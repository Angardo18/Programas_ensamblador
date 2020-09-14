    ;*******************************************************************************
;                                                                              *
;    Microchip licenses this software to you solely for use with Microchip     *
;    products. The software is owned by Microchip and/or its licensors, and is *
;    protected under applicable copyright laws.  All rights reserved.          *
;                                                                              *
;    This software and any accompanying information is for suggestion only.    *
;    It shall not be deemed to modify Microchip?s standard warranty for its    *
;    products.  It is your responsibility to ensure that this software meets   *
;    your requirements.                                                        *
;                                                                              *
;    SOFTWARE IS PROVIDED "AS IS".  MICROCHIP AND ITS LICENSORS EXPRESSLY      *
;    DISCLAIM ANY WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING  *
;    BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS    *
;    FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL          *
;    MICROCHIP OR ITS LICENSORS BE LIABLE FOR ANY INCIDENTAL, SPECIAL,         *
;    INDIRECT OR CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, HARM TO     *
;    YOUR EQUIPMENT, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR    *
;    SERVICES, ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY   *
;    DEFENSE THEREOF), ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER      *
;    SIMILAR COSTS.                                                            *
;                                                                              *
;    To the fullest extend allowed by law, Microchip and its licensors         *
;    liability shall not exceed the amount of fee, if any, that you have paid  *
;    directly to Microchip to use this software.                               *
;                                                                              *
;    MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF    *
;    THESE TERMS.                                                              *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Filename:                  Usando TMR0                                               *
;    Date:                            10/08/2020                       *
;    File Version:                           V1                         *
;    Author:           ANGEL ORELLANA                             *
;    Company:          UVG                             *
;    Description:         LABORATORIO 3 DE PROGRAMACION DE MICROS                                                 *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Notes: In the MPLAB X Help, refer to the MPASM Assembler documentation    *
;    for information on assembly instructions.                                 *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Known Issues: This template is designed for relocatable code.  As such,   *
;    build errors such as "Directive only allowed when generating an object    *
;    file" will result when the 'Build in Absolute Mode' checkbox is selected  *
;    in the project properties.  Designing code in absolute mode is            *
;    antiquated - use relocatable mode.                                        *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;                                                                              *
;*******************************************************************************



;*******************************************************************************
; Processor Inclusion
;
; TODO Step #1 Open the task list under Window > Tasks.  Include your
; device .inc file - e.g. #include <device_name>.inc.  Available
; include files are in C:\Program Files\Microchip\MPLABX\mpasmx
; assuming the default installation path for MPLAB X.  You may manually find
; the appropriate include file for your device here and include it, or
; simply copy the include generated by the configuration bits
; generator (see Step #2).
;
;*******************************************************************************

; TODO INSERT INCLUDE CODE HERE
    #include "p16f887.inc"
    ; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF


;*******************************************************************************
;
; TODO Step #2 - Configuration Word Setup
;
; The 'CONFIG' directive is used to embed the configuration word within the
; .asm file. MPLAB X requires users to embed their configuration words
; into source code.  See the device datasheet for additional information
; on configuration word settings.  Device configuration bits descriptions
; are in C:\Program Files\Microchip\MPLABX\mpasmx\P<device_name>.inc
; (may change depending on your MPLAB X installation directory).
;
; MPLAB X has a feature which generates configuration bits source code.  Go to
; Window > PIC Memory Views > Configuration Bits.  Configure each field as
; needed and select 'Generate Source Code to Output'.  The resulting code which
; appears in the 'Output Window' > 'Config Bits Source' tab may be copied
; below.
;
;*******************************************************************************

; TODO INSERT CONFIG HERE

;*******************************************************************************
;
; TODO Step #3 - Variable Definitions
;
; Refer to datasheet for available data memory (RAM) organization assuming
; relocatible code organization (which is an option in project
; properties > mpasm (Global Options)).  Absolute mode generally should
; be used sparingly.
;
; Example of using GPR Uninitialized Data
;
;   GPR_VAR        UDATA
;   MYVAR1         RES        1      ; User variable linker places
;   MYVAR2         RES        1      ; User variable linker places
;   MYVAR3         RES        1      ; User variable linker places
;
;   ; Example of using Access Uninitialized Data Section (when available)
;   ; The variables for the context saving in the device datasheet may need
;   ; memory reserved here.
;   INT_VAR        UDATA_ACS
;   W_TEMP         RES        1      ; w register for context saving (ACCESS)
;   STATUS_TEMP    RES        1      ; status used for context saving
;   BSR_TEMP       RES        1      ; bank select used for ISR context saving
;
;*******************************************************************************

; TODO PLACE VARIABLE DEFINITIONS GO HERE
 PUNTERO_7S EQU H'20' ;CONSTANTE USADA PARA EL DIRECCIONAMIENTO INDIRECTO
 ;PARA ACCEDER A LAS POSICIONES 0X20 A 0X2F EN DONDE SE ENCONTRARAN GUARDADOS
 ;LAS CONFIGURACIONES DE BITS PARA MOSTRAR LOS VALORES EN UN 7 SEGMENTOS DE CATODO COMUN
 ;NO USAR POSICIONES DESDE OX20 HASTA OX2F, AFECTARA LO MOSTRADO EN EL DISPLAY
 CONTADOR EQU H'30'
 SUBCONT EQU  H'31'
 DELAYMED EQU H'32'
 DELAYSMALL EQU H'33'
 CONTADORBUTTON EQU H'34'
 ANTIREB    EQU	H'35'
 ALARMA	    EQU	H'36'
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; TODO Step #4 - Interrupt Service Routines
;
; There are a few different ways to structure interrupt routines in the 8
; bit device families.  On PIC18's the high priority and low priority
; interrupts are located at 0x0008 and 0x0018, respectively.  On PIC16's and
; lower the interrupt is at 0x0004.  Between device families there is subtle
; variation in the both the hardware supporting the ISR (for restoring
; interrupt context) as well as the software used to restore the context
; (without corrupting the STATUS bits).
;
; General formats are shown below in relocatible format.
;
;------------------------------PIC16's and below--------------------------------
;
; ISR       CODE    0x0004           ; interrupt vector location
;
;     <Search the device datasheet for 'context' and copy interrupt
;     context saving code here.  Older devices need context saving code,
;     but newer devices like the 16F#### don't need context saving code.>
;
;     RETFIE
;
;----------------------------------PIC18's--------------------------------------
;
; ISRHV     CODE    0x0008
;     GOTO    HIGH_ISR
; ISRLV     CODE    0x0018
;     GOTO    LOW_ISR
;
; ISRH      CODE                     ; let linker place high ISR routine
; HIGH_ISR
;     <Insert High Priority ISR Here - no SW context saving>
;     RETFIE  FAST
;
; ISRL      CODE                     ; let linker place low ISR routine
; LOW_ISR
;       <Search the device datasheet for 'context' and copy interrupt
;       context saving code here>
;     RETFIE
;
;*******************************************************************************

; TODO INSERT ISR HERE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program
START
    
    BSF	STATUS,5
    BCF	STATUS,6 ;IR A BANCO 1
    
    CLRF    TRISC ;PUERTO C COMO SALIDA PARA EL DISPLAY
    MOVLW   B'11100000' ;RB7-RB5 COMO ENTRADA, RB0-RB4 COMO SALIDA, LOS PRIMEROS 4 BITS PARA LOS 
    ;LED DEL CONTADOR DEL TMR0 Y EL 5 COMO EL LED QUE SE ENCIENDE AL LLEGAR AL LIMITE ESTABLECIDO
    MOVWF   TRISB
    
    BSF	STATUS,6 ;IR AL BANCO 3
    CLRF    ANSELH	;PUERTO B EN MODO DIGITAL
    MOVLW   B'01010000' ;
    ANDWF   OPTION_REG,W ; EN W QUEDA EL DATO : 0X0X0000
    IORLW   B'00000111'	;SE ACTIVAN LAS RESISTENCIAS DE PULLUP PREESCALER EN TMRO 
    MOVWF   OPTION_REG	;CON VALOR 1:256 Y USA LA FUENTE DE OSCILADOR INTERNA
    
    
    
    BCF	STATUS,5
    BCF	STATUS,6 ; BANCO CERO
    
    
    BCF	STATUS,7 ;BANCOS 0 Y 1 PARA EL DIRECCIONAMIENTO INDIRECTO
    MOVLW   PUNTERO_7S ;COLOCA EL VALOR DE LA MEMORIA PARA EL DIRECCIONAMIENTO INDIRECTO
    MOVWF   FSR
    ; SE COLOCAN LOS VALORES PARA EL 7 SEGMENTOS ORDEN DEL PUERTO HACIA EL DISPLAY:
	;  PCDEGFAB
    MOVLW B'01110111'  ; 0  EN EL DISPLAY
    MOVWF   INDF
    INCF    FSR,F  ;0X21
    MOVLW B'01000001' ;1
    MOVWF   INDF
    INCF    FSR,F ;0X22
    MOVLW B'00111011' ;2
    MOVWF   INDF
    INCF    FSR,F ;0X23
    MOVLW B'01101011';3
    MOVWF   INDF
    INCF FSR,F ;OX24
    MOVLW B'01001101';4
    MOVWF   INDF ;OX25
    INCF FSR,F
    MOVLW   B'01101110' ;5
    MOVWF   INDF
    INCF    FSR,F ;OX26
    MOVLW B'01111110'
    MOVWF   INDF
    INCF    FSR,F ;0X27
    MOVLW   B'01000011' ;7
    MOVWF   INDF
    INCF    FSR,F;OX28
    MOVLW   B'01111111'
    MOVWF   INDF
    INCF    FSR,F;OX29
    MOVLW   B'01101111'
    MOVWF   INDF
    INCF    FSR,F;OX2A
    MOVLW   B'01011111'
    MOVWF   INDF
    INCF    FSR,F;OX2B
    MOVLW   B'01111100'
    MOVWF   INDF
    INCF    FSR,F;OX2C
    MOVLW   B'00110110'
    MOVWF   INDF
    INCF    FSR,F;OX2D
    MOVLW   B'01111001'
    MOVWF   INDF
    INCF    FSR,F;OX2E
    MOVLW   B'00111110'
    MOVWF   INDF
    INCF    FSR,F;OX2F
    MOVLW   B'00011110'
    MOVWF   INDF
   
    MOVLW .60
    MOVWF  TMR0 ; SE COLOCA EN 60 EL VALOR DEL TIMER 0
    
    MOVLW .10
    MOVWF  SUBCONT
    
    MOVFW   PUNTERO_7S
    MOVWF   PORTC ;INICIAR CON VALOR 0 EN DISPLAY
    CLRF   CONTADORBUTTON ;INICIAR CON 0 EN ESTE REGISTRO
    CLRF  CONTADOR  ;INICIAR EN 0 EL CONTADOR PARA EL TMR
    CLRF  PORTB ;SE LIMPA LA SALIDA DEL PUERTO B
    CLRF  ALARMA ;LA ALARMA SE COLOCA EN 0
LOOP:
    MOVFW   PORTB
    MOVWF   ANTIREB
    CALL DELAY_MED   ;ANTIRREBOTE
    BTFSS   ANTIREB,5 ;INCREMENTA SI SE PRESIONA EL BOTON
    CALL INCREMENTO
    BTFSS   ANTIREB,6 ;DECREMENTA 
    CALL DECREMENTO
    BTFSC INTCON,2
    CALL CONTAR_TMR
   
    
    ;SE COMPARA SI EL CONTADOR ES IGUAL QUE EL CONTADOR CON BOTON
    MOVFW   CONTADOR
    SUBWF   CONTADORBUTTON,W
    BTFSC   STATUS,2 ; BIT C DE ESTATUS SE COLOCA EN 1 SI LA OPERACION CREA UN ACCARREO EN EL BIT MAS
    CALL SONAR_ALARMA; SIGNIFICATIVO AL RESTAR, SIGNIFICA QUE SI HUBO ACARREO, LA RESTA DIO UN VALOR
    ;MAYOR QUE 0 Y SI NO HUBO ACARREO ES QUE LA RESTA DIO UN NUMERO MENOR QUE CERO
    BTFSS STATUS,0 ; SI LA OPERACION ANTERIOR NO DA CERO SE COMPRUEBA SI CONTADOR > CONTADOR BUTTON
    CALL SONAR_ALARMA_SI0 ;EN DICHO CASO TAMBIEN EL LED CAMBIA DE ESTADO
    
    
    
    GOTO LOOP
SONAR_ALARMA_SI0:
     MOVLW   B'11110000' ; AL HACER AND ENTRE EL PUERTO B Y EL VALOR 11110000 SE CONSERVAN LOS DATOS 
    ANDWF   PORTB,F;QUE SE ENCUENTREN EN LOS ULTIMOS 4 BITS Y SE COLOCAN A 0 LOS PRIMEROS 4 BIS
SONAR_ALARMA:
    BTFSC  ALARMA,0
    BSF	PORTB,4
    BTFSS	ALARMA, 0
    BCF	PORTB,4
    
    CLRF CONTADOR ; SE REINICIA EL CONTADOR
    MOVLW   .10
    MOVWF   SUBCONT ;Y EL SUBCONTADOR TAMBIEN 
    MOVLW .60
 ;   MOVWF   TMR0 ; SE REINICIA EL TIMMER
 ;    BCF	INTCON,2 ;SE COLOCA EN 0 EL FLAG DE OVERFLOW EN EL TMR0
    MOVLW   .255 ; SE COLOCAN TODOS LOS BIS PARA LUEGO HACER UN XOR CON EL VALOR EN ALARMA
    XORWF   ALARMA,F ; SI EL PRIMER BIT DE ALARMA ES 1 AL HACER XOR CON 1 SE VULEVE 0 SI ES 0 AL HACER XOR CON 1 SE VUELVE 1
    RETURN
    
CONTAR_TMR:
    DECF    SUBCONT,F
    BTFSC   STATUS,2
    CALL INC_CONTADOR
    MOVLW   .60
    MOVWF TMR0
    BCF INTCON, 2
    RETURN
    
INC_CONTADOR:
    MOVLW .10
    MOVWF   SUBCONT ;SE COLOCA EN 10 EL SUBCONTADOR
    INCF    CONTADOR,F
    BTFSC   CONTADOR,4
    CLRF CONTADOR
PRINT_B:
    MOVLW   B'11110000' ; AL HACER AND ENTRE EL PUERTO B Y EL VALOR 11110000 SE CONSERVAN LOS DATOS 
    ANDWF   PORTB,W	;QUE SE ENCUENTREN EN LOS ULTIMOS 4 BITS Y SE COLOCAN A 0 LOS PRIMEROS 4 BIS
    ADDWF   CONTADOR,W; YA QUE CONTADOR COMO MUCHO VALE 15, ENTONCES NO AFECTA AL SUMARSE
    MOVWF   PORTB   ; CON W HACIENDO QUE EN EL PUERTO B QUEDE LA INFORMACION DEL NIBBLE MAS ALTO
    RETURN  ;INTACTA Y EL VALOR DE CONTADOR QUEDA EN EL NIBBLE MAS BAJO
    
INCREMENTO:
    BTFSC PORTB,5	; SE INCREMENTA EL VALOR DE LA VARIABLE SI ESTA EXCEDE DE 15 SE REINICIA A 0
    INCF    CONTADORBUTTON,F
    BTFSC   CONTADORBUTTON,4
    CLRF    CONTADORBUTTON
    CALL MOSTRAR7S
    RETURN
    
MOSTRAR7S:
    MOVLW   PUNTERO_7S	    ; SE MUVE EL VALOR 0X20 AL REGISTRO W, EL CUAL ES EL VALOR DE DIRECCION
    ADDWF   CONTADORBUTTON,W ; DE MEMORIA PARA MOSTRAR UN CERO EN EL 7 SEGMENTOS
    MOVWF   FSR	; LUEGO SE SUMA CON VARIABLE CONTADOR BUTTON, Y SE MUEVE A FSR PARA EL 
    MOVFW   INDF    ;DIRECCIONAMIENTO INDIRECTO, SE OBTIENE EL VALOR DEL REGISTRO CON DIRECCION
    MOVWF   PORTC   ; IGUAL A ESA SUMA Y LUEGO SE ENVIA AL PUERTO C
    RETURN
    
DECREMENTO:
    MOVLW   .15
    BTFSC   PORTB,6
    DECF    CONTADORBUTTON,F	    ; SE INCREMENTA EL VALOR DE LA VARIABLE QUE CONTROLA EL 
    BTFSC   CONTADORBUTTON,7	; 7 SEGMENTOS SI EL CONTADOR LLEGA A -1 ESTE SE REINICIA Y SE 
    MOVWF   CONTADORBUTTON  ; COLOCA UN VALOR DE 0 
    CALL MOSTRAR7S
    RETURN
    
DELAY_MED: ;RETARDO DE APROXIMADAMENTE 19.328 mS 
    MOVLW .2	
    MOVWF   DELAYMED
LOOP_DELAY  
    CALL DELAY_SMALL
    DECFSZ DELAYMED,F
    GOTO LOOP_DELAY
RETURN
DELAY_SMALL: ;768 uS
    MOVLW   .255
    MOVWF   DELAYSMALL
    DECFSZ	  DELAYSMALL,F
    GOTO    $-1
RETURN

    END