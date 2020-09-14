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
;    Filename:     Main                                                            *
;    Date:      28/7/020                                                        *
;    File Version:      V1                                                       *
;    Author:        Angel Orellna                                                     *
;    Company:          UVG                                              *
;    Description:  hacer un sumador de 4 bits, *
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
    ; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

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

 VARIABLES  UDATA
  SUMANDO1  RES	1 ;VARIABLE PARA EL PRIMER SUMANDO
  SUMANDO2  RES 1 ;VARIABLE PARA EL SEGUNDO SUMANDO
  RESULTADO RES	1   ;RESULTADO DE LA SUMA
  CONTADOR1 RES	1   ;CONTADOR PARA DELAY PEQUENIO
  CONTADOR2 RES 1   ;CONTADOR PARA DELAY MEDIO
  FLAGS	    RES 1   ;	
 
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
;----------------------------------PIC18's--------------------------------------    ;v
; ISRHV     CODE    0x0008
;     GOTO    HIGH_ISR
; ISRLV     CODE    0x0018
; GOTO    LOW_ISR

    
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
CONF
    ;SE USARA EL PUERTO A PARA MOSRAR LOS SUMANDOS EL PUERTO B PARA LAS ENTRADAS 
    ; Y EL PUERTO C PARA LAS SALIDAS
    BSF STATUS,5
    BSF STATUS,6 ;IR AL BANCO 3 STATUS 
    
    CLRF ANSEL
    CLRF ANSELH ;CAMBIAR A USO DIGITAL DE PUERTO A Y B
    
    BCF	OPTION_REG,7 ;HABILITAR RESISTENCIAS DE PULL UP
    
    BCF STATUS,6 ;IR A BANCO 1
    CLRF TRISA ;PUERTO A COMO SALIDA
    CLRF TRISC	
    MOVLW .255  ;00011111
    MOVWF TRISB ;ENTRADA EL PUERTO B
   
    
    BCF STATUS,5;BANCO 0
    CLRF PORTC	;SALIDA EL PUERTO C
    CLRF PORTA ;SE LIMPIA EL PUERTOA
    
    CLRF   SUMANDO1
    CLRF   SUMANDO2

LOOP:
    ;RBO SERA PARA INCREMENTAR SUMANDO1, RB1 PARA DECREMENTARLO
    ;RB2 SERA PARA INCREMENTAR SUMANDO2, RB3 PARA DECREMENTARLO
    ;RB4 SERA PARA REALIZAR LA SUMA
    MOVFW   PORTB ;00011111
    MOVWF   FLAGS  ;SE GUARDAN LOS VALORES DEL PUERTO PARA SU COM
    CALL DELAY_MED
    BTFSS FLAGS,0  ;incremento del sumando 1
    CALL INC_SUM1
    BTFSS FLAGS,1   ;DECREMENTO DEL SUMANDO 1
    CALL DEC_SUM1
    BTFSS FLAGS,2   ;incremento del sumando 2
    CALL INC_SUM2  
    BTFSS FLAGS,3 ; DECREMENTO DEL SUMANDO 2
    CALL DEC_SUM2
    ;ESTO ES PARA VISUALIZAR EL ESTADO DE CADA VARIABLE EN EL PUERTO A LOS PRIMEROS 4 BITS
    ;SERAN PARA SUMANDO1, Y LOS ULTIMOS 4 BITS PARA SUMANDO B
    SWAPF SUMANDO2,W ;SE INTERCAMBIAN LOS NIBBLES DE ESTA VARIABLE Y SE GUARDA EN W
    ADDWF   SUMANDO1,W  
    MOVWF   PORTA ; 
   
    BTFSS FLAGS,4
    CALL SUM_VARS
    GOTO LOOP
    

SUM_VARS:
    MOVLW   .0
    ADDWF   SUMANDO1,W
    ADDWF   SUMANDO2,W
    MOVWF   PORTC
RETURN
INC_SUM1:
 ;   CALL DELAY_MED
    BTFSC  PORTB,0   ; LUEGO DE UN RETARDO SE COMPRUEBA DE NUEVO SI SIGUE PRESIONADO EL BOTON
    INCF SUMANDO1,F
    BTFSC   SUMANDO1,4	;COMPROBAMOS QUE EL NUMERO NO EXCEDE 4 BITS, SI LO HACE SE ESTABLECE EN CERO
    CLRF    SUMANDO1;00000000
    
RETURN

INC_SUM2:
    ;CALL DELAY_MED
    BTFSC  PORTB,2   ; LUEGO DE UN RETARDO SE COMPRUEBA DE NUEVO SI SIGUE PRESIONADO EL BOTON
    INCF SUMANDO2,F
    BTFSC   SUMANDO2,4	;COMPROBAMOS QUE EL NUMERO NO EXCEDE 4 BITS, SI LO HACE SE ESTABLECE EN CERO
    CLRF    SUMANDO2
RETURN

DEC_SUM1:
    ;CALL DELAY_MED
    MOVLW   .15;     0   -1  00001111 
    BTFSC  PORTB,1   ; LUEGO DE UN RETARDO SE COMPRUEBA DE NUEVO SI SIGUE PRESIONADO EL BOTON
    DECF SUMANDO1,F
    BTFSC   SUMANDO1,7	;COMPROBAMOS QUE EL NUMERO NO EXCEDE 4 BITS, SI LO HACE SE ESTABLECE EN CERO
    MOVWF   SUMANDO1
RETURN

DEC_SUM2:
   ; CALL DELAY_MED
    MOVLW   .15
    BTFSC  PORTB,3   ; LUEGO DE UN RETARDO SE COMPRUEBA DE NUEVO SI SIGUE PRESIONADO EL BOTON
    DECF SUMANDO2,F
    BTFSC SUMANDO2,7
    MOVWF SUMANDO2
RETURN

    
DELAY_MED: ;RETARDO DE APROXIMADAMENTE 77.7 mS 
    MOVLW .100
    MOVWF   CONTADOR2
LOOP_DELAY
    CALL DELAY_SMALL
    DECFSZ CONTADOR2,F
    GOTO LOOP_DELAY
RETURN

DELAY_SMALL:	;DURA 768 uS
    MOVLW   .255
    MOVWF   CONTADOR1
    DECFSZ  CONTADOR1,F
    GOTO    $-1
RETURN
    END