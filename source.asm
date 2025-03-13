.org    0x0000 ;INTERRUPT VECTOR ADDRESS FOR "RESET"
    ljmp INITIAL


.org    0x0023 ;INTERRUPT VECTOR ADDRESS FOR "SERIAL"
    setb 0x01
    clr ri
    reti ;BACK TO MAIN PROGRAM


.org    0x0100
INITIAL:
        ;initial delay
    mov A, #30
	acall	_DELAY  

        ;init 82C55 
		;(port A output,port B input)
    mov	A, #0x82
	mov	DPTR, #0xA003
    movx	@DPTR, A
    mov	A, #0x80
    mov DPTR, #0x9003
	movx	@DPTR, A

        ;init serial port
    mov scon, #50h ;SERIAL PORT MODE == 1, 8-bit UART,
				   ;SET RI WHEN RECEIVE STOP BIT.
    mov tmoD, #20h ;TIMER 1 MODE == 2,
				   ;C/T == 0, INTERNAL CLOCK SOURCE,
				   ;GATE == 0, SOFTWARE-CONTROLLED TIMER;
    mov th1, #250 ;BAUD RATE 9600
    setb tr1 ;TURN ON TIMER 1
    ;setb ti

;************************************************************
;************************************************************

    ;initial parameters for memorizing function
mov DPTR, #0x0000
mov A, #10000000b ;END flag
movx @DPTR, A

    ;default speed: fast
mov R3, #1 ;time of moving
mov R4, #1 ;time of stopping

clr 0x00 ;recording flag
clr 0x01 ;interrupt flag
clr ri
;clr ti


MAIN: 
    JNB RI,MAIN ;WAIT UNITL DATA IS READY."RI" INIDICATE THE DATA IS READY TO BE READ".
    clr RI ;IF NOT CLEAR, IT WILL KEEP READING THE PREVIOUS VALUE
    mov A, SBUF ;DATA FROM HC05

        ;SPEED CONTROL
    jb acc.4, SPEED     ;0001 000X

        ;ACTION MEMORIZING
    jb acc.5, PLAY_LOOP ;0010 0000
    jb acc.6, STOP      ;0100 0000  STOP must be placed before RECORD to avoid jump into RECORDING instantly
    jb acc.7, RECORD    ;1000 0000  restart RECROD during RECORDING
    jb 0x00, RECORDING  

        ;FORWARD, BACKWARD, LEFT, RIGHT
    jnb 0x00, PASS      ;0000 XXXX

SPEED: ;CHANGE SPEED BY CHANGING PERIOD OF STOP, LONGER STOP TIME => LOWER SPEED
    jnb acc.0, SLOW
    ljmp FAST 

    SLOW:
        mov R3, #1;                  ________               ________
        mov R4, #3;                 |        |             |        |
        ljmp HERE ;                 |        |             |        |
                  ;                 |        |             |        |
    FAST:         ;                 |        |             |        |          . . . . . .
        mov R3, #1;                 |        |             |        |
        mov R4, #1;          _______|        |_____________|        |__________
                  ;                  \  R3  / \     R4    /
    HERE:
        ljmp MAIN

RECORD:
    setb 0x00 ;trigger record
    mov DPTR, #0x0000
    push DPL
    push DPH
    ljmp MAIN

    RECORDING:
            ;show on leds
        mov DPTR, #0xA000
        movx @DPTR, A

        pop DPH
        pop DPL
        movx @DPTR, A
        inc DPTR
        push DPL
        push DPH

PASS: ;ALTERNATING POWER ON AND OFF
    mov DPTR, #0x9000
    movx @DPTR, A
    mov A, R3
    acall _DELAY

        ;BRAKE
    mov A, #00000000b
    movx @DPTR, A
    mov A, R4
    acall _Delay

    ljmp MAIN

STOP:
    jnb 0x00, MAIN ;check if already off

    clr 0x00
    pop DPH
    pop DPL
    mov A, #10000000b ;mark the END
    movx @DPTR, A

        ;turn off leds
    mov DPTR, #0xA000
    mov A, #00000000b
    movx @DPTR, A

    ljmp MAIN
	
;************************************************************
;************************************************************

PLAY_LOOP:
    jb 0x00, MAIN ;not allow to play in RECORDING mode

    mov DPTR, #0x0000
    push DPL
    push DPH

    clr 0x01
    mov ie, #90h ;"INTERRUPT ENABLE". turn on serial interrupt (press any button to stop)

    PLAYING:
            ;show on leds
        mov DPTR, #0xA000
        movx @DPTR, A

        pop DPH
        pop DPL
        movx A, @DPTR

        jb acc.7, EXIT ;jump out when meets the END

        inc DPTR
        push DPL
        push DPH

        mov DPTR, #0x9000
        movx @DPTR, A
        mov A, R3
        acall _DELAY
        mov A, #00000000b ;BRAKE
        movx @DPTR, A
        mov A, R4
        acall _Delay

        jb 0x01, EXIT ;jump out after interrupt

        ljmp PLAYING
    
    EXIT:
        mov ie, #00h ;turn off serial interrupt

            ;turn off leds
        mov DPTR, #0xA000
        mov A, #00000000b
        movx @DPTR, A

        ljmp MAIN
		
;************************************************************
;************************************************************

_DELAY:
	mov R0, A
_DELAY_I:
	mov R1, #100		;R1 = 100
_DELAY_J:
	mov R2, #100		;R2 = 100
_DELAY_K:
	djnz R2, _DELAY_K	;if(--R2 != 0) goto DELAY_K
	djnz R1, _DELAY_J	;if(--R1 != 0) goto DELAY_J
	djnz R0, _DELAY_I	;if(--R0 != 0) goto DELAY_I
	ret

.end
