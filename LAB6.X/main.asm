; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

#include "p16f887.inc"

; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF


 
 GPR UDATA
    VALORADC RES 1
    DISPLAY RES  1
    SAVE_PORTD RES 1
    FLAGS   RES 1
    STATUS_RAM RES 1
    W_RAM RES 1
 
 RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
ISRs CODE 0x004 
SAVE
    MOVWF   W_RAM
    SWAPF   STATUS,W
    MOVWF   STATUS_RAM
ISR_ADC:
    BCF	PIR1,6 ;SE LIMPIA LA INTERRUPCION DEL ADC
    MOVF   ADRESH,W ;SE MUEVE EL VALOR DEL ADC
    MOVWF   VALORADC
    BSF	ADCON0,1 ;SE INICIA LA CONVERCION
    
LOAD
    SWAPF   STATUS_RAM,W
    MOVWF   STATUS
    SWAPF   W_RAM,F
    SWAPF   W_RAM,W 
    RETFIE
    
; TODO ADD INTERRUPTS HERE IF USED

MAIN_PROG CODE                      ; let linker place main program

START
    BSF	STATUS, 5
    BSF	STATUS, 6 ;BANCO 3

    CLRF    ANSELH ;PUERTO B DE I/O DIGITAL 
    MOVLW   .255
    MOVWF   ANSEL ;PUERTO A COMO IENTRADA DIGITAL
    
    BCF	STATUS,6; BANCO 1
    CLRF	TRISB ;PUERTO B COMO SALIDA
    CLRF	TRISC ; PUERTO C COMO SALIDA
    CLRF	TRISD ; PUERTO D COMO SALIDA
    MOVLW   .255
    MOVWF   TRISA ;PUERTO A COMO ENTRADA (ANALOGICA)
    BCF	ADCON1,7 ;JUSTIFICADO A LA DERECHA
    BCF	ADCON1,5 ;VSS COMO VREF-
    BCF	ADCON1,4;VDD COMO VREF+
   
    ;-------- CONFIGURACION DE INTERRUPCIONES ----------------
    MOVLW   B'11000000'
    MOVWF   INTCON ;INTERRUPCIONES GLOBALES Y PERIFERICAS ACTIVADAS, TMO Y OTRAS DESACTIVADAS
      BSF	PIE1,6 ;SE ACTIVA LA INTERRUPCION DEL ADC
    BCF	STATUS,5 ;BANCO 0
    
   MOVLW    B'0000000' ;PRESCALER y POSTESCALER EN 0, APAGADO
    MOVLW   B'01000001' ;CONFIGURADO EN  FOSC/8 AN0, GO APAGADO Y ADC ENCENDIDO
    MOVWF   ADCON0
    
    ;VALORES INICIALES
    CLRF    PORTC
    MOVLW   .1
    MOVWF     PORTD
    MOVWF   FLAGS
    CLRF    PORTB
    CLRF    VALORADC
    CLRF    DISPLAY
    
    CALL DELAY 
    BSF	ADCON0,1 ; INICIA LA CONVERSION
LOOP:
    MOVF	VALORADC,W
    MOVWF	PORTB ;SE MUEVE EL VALOR REGISTRADO EN VALOR ACD AL PUERTO B
    CLRF    PORTD
    CALL TABLA
    MOVWF   PORTC
    COMF    FLAGS,F
    MOVF    FLAGS,W
    MOVWF   PORTD
    
    GOTO LOOP
    


    
 TABLA:
    MOVFW   VALORADC
    BTFSC FLAGS,0 ; SI ESTA EN CERO SE USAN LOS BITS MENOS SIGNIFICATIVOS SI ESTA EN 1 LO CONTRARIO
    SWAPF VALORADC,W
    ANDLW B'00001111' ;CONSERVAMOS SOLO EL NIBBLE INFERIOR DEL DATO GUARDADO EN W
    ADDWF   PCL,F
    ;	
    RETLW B'01110111'  ; 0  EN EL DISPLAY
    RETLW B'00010100' ;1
    RETLW B'10110011' ;2
    RETLW B'10110110';3
    RETLW B'11010100';4
    RETLW   B'11100110' ;5
    RETLW B'11100111' ;6
    RETLW   B'00110100' ;7
    RETLW   B'11110111';8
    RETLW   B'11110110';9
    RETLW   B'11110101';A
    RETLW   B'11000111';B
    RETLW   B'01100011';C
    RETLW   B'10010111';D
    RETLW   B'11100011';E
    RETLW   B'11100001';F

DELAY: ;DELAY 5 uS
    NOP
    RETURN
    END