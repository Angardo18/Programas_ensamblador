;*******************************************************************************
;                                                                              *
;    Filename:                                                                 *
;    Date:                                                                     *
;    File Version:                                                             *
;    Author:                                                                   *
;    Company:                                                                  *
;    Description:                                                              *
;                                                                              *
;*******************************************************************************
; TODO Step #2 - Configuration Word Setup
#include "p16f887.inc"

; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;*******************************************************************************
;
; TODO Step #3 - Variable Definitions
; TODO PLACE VARIABLE DEFINITIONS GO HERE
     CBLOCK H'20'
 CONTADOR, ;OX20 CONTADOR DEL TMR0
 SUBCONT,    ;0X21 SUBCONTADOR DEL TMR0
 CONTADORBUTTON,	;0X22 CONTADOR CON EL BOTON
 DELAYSMALL, ;0X23 
 DELAYMED;0X24 
 ANTIREB, ;0X25 ANTIREBOTE
 SELECTOR7S; 0X26 REGISTRO PARA SELECCIONAR EL DISPLAY A USAR
 VALORDISPLAY;0X27
 ALARMA;0X28
 FLAGS ;0X29 BANDERAS UTILIZADAS PARA DISTINTOS PROPOSITOS
	;BIT 0 USADO PARA NOTIFICAR QUE SE HA ENTRADO EN UNA INTERRUPCION
STATUS_RAM 
WRAM
 ENDC
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; TODO Step #4 - Interrupt Service Routines
; TODO INSERT ISR HERE
INTERRUPT CODE 0x0004
SAVE:
    MOVWF   WRAM
    SWAPF   STATUS,W
    MOVWF   STATUS_RAM ; SE GUARDAN LOS ARCHIVOS EN LA RAM
ISR:
    BCF	INTCON,2 ;SE COLOCA A 0 EL FLAG DEL TMR0
    MOVLW .158
    MOVWF   TMR0
    BSF	FLAGS,0
   ;BTFSC    INTCON,2 ;SE VERIFICA SI EL FLAG DEL TMR0 ESTA ENCENDIDA
   ;CALL CONTAR
LOAD:
    SWAPF   STATUS_RAM,W
    MOVWF   STATUS
    SWAPF   WRAM, F
    SWAPF   WRAM,W
    RETFIE

CONTAR:
     BCF	INTCON,2 ;SE COLOCA A 0 EL FLAG DEL TMR0
    MOVLW .158
    MOVWF   TMR0
    BSF	FLAGS,0
    RETURN
 
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
    BCF	STATUS,6
    BSF	STATUS,5 ;BANCO 1
    
    CLRF    TRISA ;PUERTO A   COMO SALIDA PARA EL CONTADOR DEL TMRO 
    CLRF    TRISC   ;PUERTO C PARA EL CONTADOR EN HEX DEL DISPAY
    MOVLW   B'11000000' ;RB6 Y 7 COMO ENTRADAS
    MOVWF   TRISB
    CLRF    TRISD
    
    MOVLW   B'01010111'  ;TEMPORIZADOR ADEMAS DE ASIGNARLE EL PRESCALER A TMR0
    ANDWF   OPTION_REG,F
    
    MOVLW   B'11000000'
    MOVWF   IOCB ;SE ACTIVAN LAS INTERRUMCIONES DE CAMBIO DE ESTADO EN RB6 Y RB7
    
    BSF	STATUS,6 ;BANCO 3
    
    CLRF    ANSEL; HABILITAR IO DIGITAL EN PUERTO A
    CLRF    ANSELH; HABILITAR IO DIGITAL EN PUERTO B
    
    BCF	STATUS,6
    BCF	STATUS,5  ;BANCO 0
    
    MOVLW   B'10100000'      ; SE HABILITAN LAS  INTERRUPCIONES GLOBALES Y LA INTERRUPCION DEL TMR0
    IORWF   INTCON,F; YA NO ASI COMO LAS INTERRUPCION DE CAMBIO DE ESTADO EN EL PUERTO B 

    MOVLW   .158
    MOVWF   TMR0
    
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTC
    CLRF    TRISD
    MOVLW   .40	
    MOVWF   SUBCONT
    CLRF    CONTADOR
    CLRF    CONTADORBUTTON
    CLRF    ALARMA
    MOVLW .1
    MOVWF  SELECTOR7S
LOOP:
    BTFSC   FLAGS,0
    CALL CONTAR_1S
  
   ;--------------------REVISAR LAS ENTRADAS-----------------------------------------
    MOVFW   PORTB
    MOVWF   ANTIREB
    CALL DELAY_SMALL
    ;CALL DELAY_MED
    BTFSS   ANTIREB,6
    CALL INCREMENTO
    BTFSS ANTIREB,7
    CALL DECREMENTO
    ;--------------MOSTRAR EN DISPLAY-------------------------
    CLRF    PORTD
    MOVLW   B'11111111' ; AL HACER XOR CON UN 1 ES COMO UN NOT
    XORWF   SELECTOR7S,F;SE REALIZA EL XOR
    CALL TABLA
    ;MOVWF   VALORDISPLAY ;SE GUARDA EL VALOR RETORNADO POR TABLA
   ; MOVLW   B'10000000'	;SE CONSERVA EL ULTIMO BIT DE SELECTOR DISPLAY PARA SABER CUAL DE
    ;ANDWF   SELECTOR7S,W    ;LOS DOS SE UTILIZARA
    ;ADDWF   VALORDISPLAY,W; SE SUMA, DESDE LA PROGRAMACION SE SABE QUE EL ULTIMO BIT SIEMPRE ES CERO
    MOVWF   PORTC  ;SE VISUALIZA EN EL 
    MOVFW   SELECTOR7S
    MOVWF   PORTD
    ;-------------SE REALIZA EL CONTROL DE LA ALARMA------------------
    MOVFW   CONTADOR
    SUBWF   CONTADORBUTTON,W
    BTFSC   STATUS,Z
    CALL ALARMA_RUTINA
     BTFSS STATUS,0 ; SI LA OPERACION ANTERIOR NO DA CERO SE COMPRUEBA SI CONTADOR > CONTADOR BUTTON
    CALL SONAR_ALARMA_SI0 ;EN DICHO CASO TAMBIEN EL LED CAMBIA DE ESTADO
    
    GOTO LOOP
CONTAR_1S:
    BCF	FLAGS,0
    DECF    SUBCONT,F
    BTFSC   STATUS,2 ; SE VERIFICA SI EL DECREMENTO ANTERIOR DIO 0
    CALL    INCREMENTAR_TMR0
    RETURN  
   
INCREMENTAR_TMR0:
    MOVLW .40
    MOVWF   SUBCONT
    INCF    CONTADOR,F
      ;--------------SE VISUALIZA EL VALOR DEL CONTADOR DEL TMR0-----------------
    MOVFW   CONTADOR
    MOVWF   PORTA
    RETURN
SONAR_ALARMA_SI0:
    MOVLW .0
    MOVWF   PORTA
ALARMA_RUTINA:
    MOVLW .255
    XORWF ALARMA,F
    MOVLW  .1
    ANDWF   ALARMA,W
    MOVWF   PORTB
    CLRF CONTADOR
    MOVLW .40
    MOVWF   SUBCONT
 
    RETURN
    
INCREMENTO:
    BTFSC PORTB,6
    INCF CONTADORBUTTON,F
    RETURN

DECREMENTO:
    BTFSC PORTB,7
    DECF CONTADORBUTTON,F
    RETURN
    
    TABLA:
    MOVFW   CONTADORBUTTON
    BTFSC SELECTOR7S,7 ; SI ESTA EN CERO SE USAN LOS BITS MENOS SIGNIFICATIVOS SI ESTA EN 1 LO CONTRARIO
    SWAPF CONTADORBUTTON,W
    ANDLW B'00001111' ;CONSERVAMOS SOLO EL NIBBLE INFERIOR DEL DATO GUARDADO EN W
    ADDWF   PCL,F
    RETLW B'01110111'  ; 0  EN EL DISPLAY
    RETLW B'01000001' ;1
    RETLW B'00111011' ;2
    RETLW B'01101011';3
    RETLW B'01001101';4
    RETLW   B'01101110' ;5
    RETLW B'01111110' ;6
    RETLW   B'01000011' ;7
    RETLW   B'01111111';8
    RETLW   B'01101111';9
    RETLW   B'01011111';A
    RETLW   B'01111100';B
    RETLW   B'00110110';C
    RETLW   B'01111001';D
    RETLW   B'00111110';E
    RETLW   B'00011110';F
    
 DELAY_MED:
    MOVLW .1
    MOVWF	DELAYMED
CONF1:
    CALL DELAY_SMALL
    DECFSZ  DELAYMED,F
    GOTO CONF1
    RETURN
    
DELAY_SMALL: ;603 uS
    MOVLW    .255
    MOVWF   DELAYSMALL
    DECFSZ  DELAYSMALL,F
    GOTO $-1
    RETURN
    
    END