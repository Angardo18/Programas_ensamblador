; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
#include "p16f887.inc"

; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

VARIABLES UDATA
    VALOR   RES 1
   W_RAM    RES 1
    STATUS_RAM RES 1
    DELAY RES 1
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program


; TODO ADD INTERRUPTS HERE IF USED
ISRS CODE 0x0004
SAVE:
    MOVWF   W_RAM
    SWAPF   STATUS,W
    MOVWF   STATUS_RAM
ISR:
    BCF	PIR1,6 ;SE LIMPIA LA INTERRUPCION DEL ADC
    MOVF   ADRESH,W ;SE MUEVE EL VALOR DEL ADC
    MOVWF   VALOR
    BSF	ADCON0,1 ;SE INICIA LA CONVERCION
    
    
LOAD:
    SWAPF   STATUS_RAM,W
    MOVWF   STATUS
    SWAPF   W_RAM,F
    SWAPF   W_RAM,W
    RETFIE

    MAIN_PROG CODE                      ; let linker place main program

START
    BSF	STATUS,6
    BSF	STATUS,5 ;BANCO 3
    
    MOVLW   .255
    MOVWF   ANSEL
    CLRF    ANSELH
    
    BCF	STATUS,6 ;BANCO 1
    
    CLRF	TRISB ;PUERTO B COMO SALIDA
    BSF	TRISA,0 ;ENTRADA EN RBA3
    
    BSF	INTCON,7 ;INTERRUPCIONES GLOBALES
    BSF	INTCON,6 ;INTERRUPCIONES PERIFERICAS ENCENDIDAS
    BSF	PIE1,6 ;INTERRUPCION DEL ADC ACTIVA	
    
    BCF	ADCON1,7 ;JUSTIFICADO A LA DERECHA
    BCF	ADCON1,5;VCC
    BCF	ADCON1,4 ;VSS
    
    BCF	TXSTA,6 ;TRANSMISION DE 8 BITS
    BSF	TXSTA,5 ;ACTIVACION DE LA TRANSMISION
    BCF	TXSTA,4 ;MODO ASINCRONO
    BSF	TXSTA,2 ;MODO HIGH SPEED BAUD RATE
    
    MOVLW   .25
    MOVWF   SPBRG   ;9615 BAUDS, 
    
    BCF	STATUS,5 ;BANCO 0
    
    MOVLW   B'10000001'
    MOVWF   ADCON0 ;CANAL AN3, FOSC/8 GO APAGADO Y ADC ENCENDIDO
    
   BSF	RCSTA,7 ;PUERTO SERIAL ACTIVADO
   
   CLRF VALOR
  
  CALL DELAY_US
  BSF	ADCON0,1; INICIA LA CONVERSION
   
LOOP:
    MOVF    VALOR,W
    MOVWF    PORTB
    
    BTFSS   PIR1,4 ;ESTA BANDERA ESTA EN 1 SI EL BUFFER ESTA VACIO Y EN 0 CUANDO ESTA OCUPADO
    GOTO LOOP
    
    MOVF    VALOR,W
    MOVWF   TXREG
    GOTO LOOP
    
    DELAY_US:
    MOVLW   .20
    MOVWF   DELAY
    DECFSZ  DELAY,F
    GOTO $-1
    RETURN

    END