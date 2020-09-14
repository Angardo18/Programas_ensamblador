; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

    
    ;*******************************************************************************
;
;   Filename:	    Laboratorio 5 -> Lab5.asm
;   Date:		    24/08/2020
;   File Version:	    v.1
;   Author:		    Noel Prado
;   Company:	    UVG
;   Description:	    Timer1 y TImer2
;
;*******************************************************************************  
    
    #include "p16f887.inc"

; CONFIG1
; __config 0xFFD4
    __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
; CONFIG2
; __config 0xFFFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF


GPR_VAR		UDATA
W_TEMP		RES 1
STATUS_TEMP	RES 1
CONT1		RES 1
CONT2		RES 1
NIBBLE_L		RES 1
NIBBLE_H		RES 1
BANDERAS	RES 1
VAR_DISPLAY	RES 1	
BCD		RES 1
VAR_REVTEMP	RES 1
	
;**************************************************INICIO DEL PROGRAMA**************************************************************
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START		    ; go to beginning of program

;*****************************************************INTERRUPCIONES*******************************************************************

 ISR_VECT   CODE    0X0004
   
PUSH:
    BCF	    INTCON, GIE
    MOVWF	    W_TEMP
    SWAPF	   STATUS, W
    MOVWF	   STATUS_TEMP 
        
ISR:
    BTFSC   INTCON, T0IF
    GOTO    FUE_TMR0
    BTFSC   PIR1, TMR1IF
    GOTO    FUE_TMR1
    BTFSC   PIR1, TMR2IF
    GOTO    FUE_TMR2
    
    
     FUE_TMR0:
  
    MOVLW	    .249
    MOVWF	    TMR0
    BCF	    INTCON, T0IF    
    CALL	    DISPLAY
    GOTO	    POP
    
    
    FUE_TMR1:
    
    BCF	   PIR1, TMR1IF
    INCF	   VAR_DISPLAY, F
    
    MOVLW   085H
    MOVWF   TMR1H
    MOVLW   0EEH
    MOVWF   TMR1L
    GOTO	    POP

    FUE_TMR2:
   
    CLRF    TMR2
    BCF	PIR1, TMR2IF
    MOVLW	    .255
    XORWF   CONT2,F 
   
POP:
    SWAPF	    STATUS_TEMP, W
    MOVWF	    STATUS
    SWAPF	    W_TEMP, F
    SWAPF	    W_TEMP, W
    BSF	    INTCON, GIE
  
    RETFIE
    
    
        TABLE
    ;ANDWF   B'00001111'; LIMITANDO DE 0 A F
    ADDWF   PCL, F
    ;	      PCDEGFAB
    RETLW   B'01110111'	;0
    RETLW   B'01000001'	;1
    RETLW   B'00111011'	;2
    RETLW   B'01101011'	;3
    RETLW   B'01001101'	;4
    RETLW   B'01101110'	;5
    RETLW   B'01111110'	;6
    RETLW   B'01000011'	;7
    RETLW   B'01111111'	;8
    RETLW   B'01101111'	;9
    RETLW   B'01101111'	;9
    RETLW   B'01101111'	;9
    RETLW   B'01101111'	;9
    RETLW   B'01101111'	;9
    RETLW   B'01101111'	;9
    RETLW   B'01101111'	;9
    
    RETURN
;----------------------------------------------------SUBRUTINAS DE LA INTERRUPCION--------------------------------------------


   
 


;----------------------------------------------------------PRINCIPAL-----------------------------------------------------------------------

MAIN_PROG CODE                      ; let linker place main program

START

    CALL	CONFIG_IO
    CALL	CONFIG_TMR0	; 2MS
    CALL	CONFIG_TMR1	; 1 SEGUNDO
    CALL	CONFIG_TMR2	; 500MS
    CALL	CONFIG_INTERRUPT
    CLRF    VAR_DISPLAY
    
 LOOP
 
    MOVF	    VAR_DISPLAY, W
    ANDLW	   B'00001111'
    MOVWF	    VAR_REVTEMP
    MOVLW	.10
    SUBWF	VAR_REVTEMP, W
    BTFSS	STATUS, Z
    GOTO    SIGUIENTE
    MOVLW   .6
    ADDWF   VAR_DISPLAY
 
SIGUIENTE:
    CALL	    LEDS
    CALL	    SEPARAR_NIBBLE
   
    MOVLW   .160
    SUBWF   VAR_DISPLAY, W
    BTFSC	  STATUS, Z
    CLRF	VAR_DISPLAY

   
    
   
    GOTO    LOOP
    GOTO $                          ; loop forever

    
;-----------------------------------------------------------SUBRUTINAS-------------------------------------------------------------------

LEDS
    BTFSS	   CONT2, 0
    CALL	   APAGAR_LEDS
    BTFSC	   CONT2, 0
    CALL	   PRENDER_LEDS
    RETURN

PRENDER_LEDS
    MOVLW   B'00000011'
    MOVWF   PORTB
    RETURN

    APAGAR_LEDS
    MOVLW   B'00000000'
    MOVWF   PORTB
    RETURN
    
SEPARAR_NIBBLE
    MOVF    VAR_DISPLAY, W
    ANDLW   B'00001111'
    MOVWF   NIBBLE_L
    
    SWAPF   VAR_DISPLAY, W
    ANDLW   B'00001111'
    MOVWF   NIBBLE_H
    RETURN
     
TOGGLE_B0
    BTFSS   BANDERAS, 0
    GOTO    TOG_0
TOG_1:
    BCF	BANDERAS, 0
    RETURN
TOG_0:
    BSF	BANDERAS, 0
    RETURN   
    

        DISPLAY
    CLRF    PORTD
    BTFSC   BANDERAS, 0
    GOTO    DISPLAY_1
DISPLAY_0:
    MOVFW   NIBBLE_L
    CALL	  TABLE
    MOVWF   PORTC
    BSF	    PORTD, RD0
    GOTO    FIN_DISPLAY
DISPLAY_1:
    MOVFW    NIBBLE_H	
    CALL    TABLE
    MOVWF   PORTC
    BSF	    PORTD, RD1
    GOTO    FIN_DISPLAY
FIN_DISPLAY:
    CALL    TOGGLE_B0
    RETURN
    
    
   
    
    

;-----------------------------------------------------------CONFIGURACION-------------------------------------------------------------
    
CONFIG_IO
    BANKSEL	TRISA	;LOS PUERTOS COMO SALIDAS
    CLRF		TRISA
    CLRF		TRISB
    CLRF		TRISC
    CLRF		TRISD

    BANKSEL	ANSEL	;DIGITAL
    CLRF		ANSEL
    CLRF		ANSELH
    BANKSEL	PORTA	
    CLRF		PORTA
    CLRF		PORTB
    CLRF		PORTC
    CLRF		PORTD

    CLRF		VAR_DISPLAY
    RETURN
 
 CONFIG_TMR0
    BANKSEL TRISA
    BCF	    OPTION_REG, T0CS;	RELOJ INTERNO
    BCF	    OPTION_REG, PSA;	PRESCALER A TMR0
    BSF	    OPTION_REG, PS2;	SE PONE 111 PARA PRESCALER DE 256
    BSF	    OPTION_REG, PS1
    BSF	    OPTION_REG, PS0
    BANKSEL PORTA
    MOVLW   .249
    MOVWF   TMR0
    BCF	    INTCON, T0IF
    RETURN
 
 CONFIG_TMR1
 
    BANKSEL	PORTA
    BCF		T1CON, TMR1GE 	
    BSF		T1CON, T1CKPS1	;PRESCALER 1:2
    BCF		T1CON, T1CKPS0
    BCF		T1CON, T1OSCEN	; NO SE USA EL LP
    BCF		T1CON, TMR1CS	; RELOJ INTERNO
    BSF		T1CON, TMR1ON	; SE PRENDE TMR1
    MOVLW		0X85
    MOVWF		TMR1H
    MOVLW		0XEE
    MOVWF		TMR1L
    BCF		PIR1, TMR1IF
    
 
    RETURN
 
 CONFIG_TMR2
    BANKSEL	    PORTA
    MOVLW	    B'11111111'
    MOVWF	    T2CON
    BANKSEL	    TRISA
    MOVLW	    .244
    MOVWF	    PR2
    BANKSEL	    PORTA
    CLRF	    TMR2
    BCF	    PIR1, TMR2IF
    RETURN
 
 CONFIG_INTERRUPT
    
    BANKSEL	TRISA
    BSF		PIE1, TMR1IE
    BSF		PIE1, TMR2IE
    BANKSEL	PORTA
    BSF		INTCON, GIE
    BSF		INTCON, PEIE
    BCF		PIR1, TMR1IF
    BCF		PIR1, TMR2IF
    BSF		INTCON, T0IE
    BCF		INTCON, T0IF
    
    RETURN
    
    END