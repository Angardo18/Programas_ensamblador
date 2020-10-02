;*********************************************************************************
;    Filename: Reloj -> Proyecto_Reloj						*
;    Date:  22/09/2020								*
;    File Version: v1								*
;    Author: Daniel Mundo								*
;    Company:  UVG								*
;    Description: Reloj digital con tres modos: alarma, fecha & hora			*
;	           adem?s puede configurarse los tres modos.				*
;********************************************************************************
#include "p16f887.inc"
;********************************************************************************
; CONFIG1
; __config 0x20D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;********************************************************************************
; TODO Step #3 - Variable Definitions
;********************************************************************************
;Recordar utilizar EQU para comprecion de ciertos parametros con los displays
GPR_VAR	    UDATA
;*****************************INTERRUPCIONES********************************
CONT_TRM2	RES	    1	;Variable utilizada para el Timer 2
CONT_TRM1	RES	    1	;Variable utilizada para el Timer 1
CONT_TRM0	RES	    1	 ;Variable utilizada para el Timer 0
CONT_TRM0_S	RES	    1	 ;Variable utilizada para el Timer 0
TEMP_W	RES	    1	;Variable destinada para guardar el valor actual de "W"
TEMP_STATUS	RES	    1	;Variable destinada para guardar el valor actual de "STATUS"
;********************************ESTADOS**************************************
CONT_RM	RES	    1	;Varible destinada para configuraciones del reloj (minutos)
CONT_RH	RES	    1	;Varible destinada para configuraciones del reloj (hora)
CONT_AM	RES	    1	;Varible destinada para configuraciones de la alarma (minutos)
CONT_AH	RES	    1	;Varible destinada para configuraciones de la alarma (hora)
CONT_DM	RES	    1	;Varible destinada para configuraciones de la fecha (mes)
CONT_DD	RES	    1	;Varible destinada para configuraciones de la fecha (dia)
BANDERAS	RES	    1	;Variable destinada para la selccion del display
MODO		RES	    1
;*****************************GENERALES***************************************
ANTIREB	RES	    1	 ;Variable utilizada para el antirebote en los botones
VAR_H		RES	    1	;Variable destinada para las horas & las siguientes guardan sus nibbles
NIBH_H	RES	    1	;Variable destinada para los nibbles m?s significativos
NIBH_L	RES	    1	;Variable destinada para los nibbles menos significativos
VAR_M		RES	    1	;Variable destinada para los minutos
NIBM_H	RES	    1	;Variable destinada para los nibbles m?s significativos
NIBM_L	RES	    1	;Variable destinada para los nibbles menos significativos
LED_500MS	RES	    1	;Variable utilizada para prender/apagar los leds cada 500ms
VAR_TEMP_MH	RES	    1	;
VAR_TEMP_H	RES	    1	;
VAR_TEMP_ML	RES	    1	;
VAR_TEMP_HL	RES	    1	;
CONT1		RES	    1	;Variables utilizadas para el delay
CONT2		RES	    1	;
EDICION	RES	    1
EDIT		RES	    1
FLAGS		RES	    1	;banderas
		;bit 0 si se entro al modo edicion
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
;		             INTERRUPCIONES
;*******************************************************************************
ISR_VECT   CODE    0X0004
   
SAVE:					;Sirve para guardar el valor actual de:
    MOVWF	TEMP_W		;"W"
    SWAPF	STATUS, W
    MOVWF	TEMP_STATUS		;& STATUS
        
ISR:
    BTFSC	INTCON, T0IF		;Se comprueba siempre que la bandera este
    GOTO	INT_TRM0		;encendida para realizar las operaciones de
    GOTO	LOAD			;la interrupcion.
INT_TRM0:
    MOVLW	.60			;Se carga el valor de "n" a la ecucion del TRM0
    MOVWF	TMR0			;para que este levante la bandera aproximada-
    BCF		INTCON, T0IF		;mente cada 50 ms.
    INCF		CONT_TRM0, F		;Con cada interrupcion se incrementan las va-
    INCF    	CONT_TRM0_S, F	;riables.
CADA_500mS:
    MOVFW	CONT_TRM0_S		;Se comprueba si la variable llego a 
    SUBLW	.5			;250 ms.
    BTFSS	STATUS, Z
    GOTO	MINUTOS		;En caso de que no, se va a Minutos. 
    CLRF		CONT_TRM0_S		;En caso de que si, se reinicia la variable 
    MOVLW	B'11111111'		;y se hace un Exclusive OR a la puerto E, que
    XORWF	PORTE, F		;se prende cuando pasen 250ms y se apague cuando pase 500ms.
MINUTOS:
    MOVFW	CONT_TRM0
    SUBLW	.120			;Se comprueba si ya se llego a un minuto
    BTFSS	STATUS, Z		
    GOTO	LOAD			;En caso de que no se va LOAD
    CLRF		CONT_TRM0		;En caso de que si se limpia el conteo del TRM0
    INCF		CONT_RM, F		; y se incrementa en 1 la variable minuto.
    MOVLW	.60			;Se comprueba si se llego a una hora.
    SUBWF	CONT_RM,W		
    BTFSS	STATUS, Z		
    GOTO	LOAD			;En caso de que no sea asi se va a LOAD.
    CLRF		CONT_RM		;En caso de que si pase se limpia la variable
    INCF		CONT_RH, F		;de minuto y se incrementa en 1 la de horas.
     MOVLW	.24			;Se comprueba si ya pasaron 24 horas.
    SUBWF	CONT_RH,W
    BTFSS	STATUS, Z
    GOTO	LOAD			;En caso de que no se va LOAD
    CLRF		CONT_RH		;En caso si haya llegado se reinician las varia-
    CLRF		CONT_RM		;de horas,  minutos y se incrementa en 1
    INCF		CONT_DM, F		;el dia.
LOAD:					;Se recupera el valor de:
    SWAPF	TEMP_STATUS, W  
    MOVWF	STATUS		;STATUS
    SWAPF	TEMP_W, F
    SWAPF	TEMP_W, W		;& de "W"
    BSF		INTCON, GIE		;se habilitan la interrupciones globales
    RETFIE
;--------------------------------TABLAS-----------------------------------------
TABLE:  
    ADDWF   PCL, F			;La colocacion de los puertos es la siguiente:
		    ;PCDEGFAB
    RETLW	B'01110111'		;0
    RETLW	B'01000001'		;1
    RETLW	B'00111011'		;2
    RETLW	B'01101011'		;3
    RETLW	B'01001101'		;4
    RETLW	B'01101110'		;5
    RETLW	B'01111110'		;6
    RETLW	B'01000011'		;7
    RETLW	B'01111111'		;8
    RETLW	B'01101111'		;9  
    RETURN 
DISPLAY:				;Funcion general utilizada para mostrar los  
    CLRF		PORTD			;valores de las variables.
    MOVF	BANDERAS,W		;Dependiendo del actual valor de banderas
    ADDWF	PCL,F			;se selecciona el diplays que va a mostrar su valor:
    GOTO	DISPLAY_0		    ;Las unidades de minuto.
    GOTO	DISPLAY_1		    ;Las decenas de minuto.
    GOTO	DISPLAY_2		    ;Las unidades de hora.
    GOTO	DISPLAY_3		    ;Las decenas de hora.
DISPLAY_0:			
    MOVF	NIBM_L, W	
    CALL		TABLE			;Este display muestra valores del 0 al 9
    MOVWF	PORTC			;para los tres modos.
    BSF		PORTD, 0
    GOTO	FIN_DISPLAY
DISPLAY_1:			
    MOVF	NIBM_H, W		;Este display muestra valores:	
    CALL		TABLE			;->del 0 al 5 (Modo 0 & 2).
    MOVWF	PORTC			;->del 0 al 3 (Modo 1).
    BSF		PORTD, 1
    GOTO	FIN_DISPLAY
DISPLAY_2:			
    MOVF	NIBH_L, W	
    CALL		TABLE			;Este display muestra valores del 0 al 9
    MOVWF	PORTC			;para los tres modos.
    BSF		PORTD, 2
    GOTO	FIN_DISPLAY
DISPLAY_3:			
    MOVF	NIBH_H, W		;Este display muestra valores:
    CALL		TABLE			;->del 0 al 2 (Modo 0).
    MOVWF	PORTC			;->del 0 al 1 (Modo 1).
    BSF		PORTD, 3		;->del 0 al 9 (Modo 2).
    GOTO	FIN_DISPLAY
FIN_DISPLAY:
    CALL		TOGGLE_B0
    RETURN 
TABLA_MESES:
    MOVFW	CONT_DM
    ADDWF	PCL,F
    GOTO	MES_I
    GOTO	ENERO
    GOTO	FEBRERO
    GOTO	MARZO
    GOTO	ABRIL
    GOTO	MAYO
    GOTO	JUNIO
    GOTO	AGOSTO
    GOTO	SEPTIEMBRE
    GOTO	OCTUBRE
    GOTO	NOVIEMBRE
    GOTO	DICIEMBRE
    GOTO	MES_I
TOGGLE_B0:				;Se incrementa el valor de banderas cada 
    INCF		BANDERAS,F		;vez que que se llama a la funcion.
    MOVLW	.4			;Debido a que solo hay 4 displays, se resetea
    SUBWF	BANDERAS,W		;la variable cada vez que esta tiene un valor
    BTFSC	STATUS, Z		;de 4.
    CLRF		BANDERAS
    RETURN    
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      

START
    CALL		CONFIG_I
    CALL		CONFIG_IS
    
LOOP:  
    CLRF		EDICION		;Asegura que esta variable siempre este en 0 antes de cada "edicion".
    MOVFW	PORTB			;El puerto B funciona como entrada,  el antirebote
    MOVWF	ANTIREB		;es RC, la variable se usa para asegurar.    ;Se comprueba si se presiono el boton  de B0
    CALL		DELAY_2MS
    BTFSC	ANTIREB, 0
    GOTO	SELECCION_MODOS
    INCF		MODO, F		;de ser asi se modifica el valor de Modo 		
SELECCION_MODOS:
     MOVLW	.0			;-----------------Modo 0--------------------
     SUBWF	MODO, W		;El reloj es el modo estandar, por lo cual se
    BTFSC	STATUS,Z		; tiene que siempre que la variable siempre 
    GOTO	RELOJ			; este en 0.
    MOVLW	.1			;-----------------Modo 1--------------------
    SUBWF	MODO, W		;El siguiente modo es la fecha, por lo cual el
    BTFSC	STATUS,Z		;valor de la variable siempre tiene que ser
    GOTO	FECHA			;1.
    MOVLW	.2			;-----------------Modo 2--------------------
    SUBWF	MODO, W		;El ultimo modo es la alarma, por lo cual el
    BTFSC	STATUS,Z		;valor de la variable siempre tiene que ser
    GOTO	ALARMA		;2
    MOVLW	.3			;-----------------Reseteo-------------------
    SUBWF	MODO, W		
    BTFSC	STATUS,Z		;Debido a que solo existen 3 modos, se tiene
    CLRF		MODO			;que resetear la variable y ser llevada devuel-
    GOTO	SELECCION_MODOS	;al modo estandar.
 
;*******************************************************************************
;				SUBRUTINAS    
;*******************************************************************************     
;----------------------------------MODOS-----------------------------------------------    
;------------------------------------------Modo Reloj------------------------------------    
RELOJ:	
    MOVLW	B'00000010'		;Se asegura de limpiar el puerto A
    MOVWF	PORTA			;Se enciende el LED correspondiente al modo
    MOVFW	CONT_RM		;Se definen el valor de las variables en los
    MOVWF	VAR_M			;displays para este modo respectivo.
    MOVFW	CONT_RH
    MOVWF	VAR_H   
    BTFSC	EDICION, 0
    GOTO	EDICION_RELOJ  
    BTFSC	ANTIREB, 4;este  boton habilita el modo edicion.
    GOTO	LIMITACIONES_HR
    BSF		PORTA, 0
    BSF		EDICION, 0		;Se enciende el bit 0 de la variable que significa modo edicion		
    GOTO	EDICION_RELOJ	;el cual si se presiona se entra en modo edicion.
LIMITACIONES_HR: 
    CALL		CONDICIONES_MODOS;Se llaman a las tres funciones generales
    CALL		SEPARAR_NIBBLES	   ;para todos los modos. 
    CALL		DISPLAY
    GOTO	LOOP			 ;Se regresa al loop principal
EDICION_RELOJ:  
    CALL		DELAY_2MS
    MOVFW		PORTB			;El puerto B funciona como entrada,  el antirebote
    MOVWF		ANTIREB		    ;Se comprueba si se presiono el boton  de B0
    BTFSC	ANTIREB, 4;este  boton habilita el modo edicion.*
    GOTO EDIT_2
    
    BCF		EDICION, 0
    BCF	PORTA,0
    EDIT_2
    
    BTFSC	EDICION, 1		;Si el bit 1 esta encendido significa que actual-
    GOTO	EDICICION_HORAS	;actualmente se estan editando las horas.
    BTFSS	ANTIREB, 5		;Se comprueba si se presiono el boton  de B5
    CALL		DELAY_2MS
    BTFSC	PORTB, 5		;con este boton se selecciona si se edita los 
    GOTO	$+3			;minutos o las horas
    BSF		EDICION, 1		;mantendra la edicion en horas hasta que se presione B5.
    GOTO	EDICICION_HORAS
    BTFSS	ANTIREB, 7		;Se comprueba si se presiono el boton  de B7
    CALL		DELAY_2MS
    BTFSC	PORTB, 7		;este  boton  incrementa la variable.
    GOTO	$+2			  
    INCF		CONT_RM, F		  
     BTFSS	ANTIREB, 6		;Se comprueba si se presiono el boton  de B6
     CALL		DELAY_2MS
    BTFSC	PORTB, 6		;este  boton  decrementa la variable.
    GOTO	$+2			  
    DECF		CONT_RM, F
     BTFSS	ANTIREB, 4		;Se comprueba si se presiono el boton  de B4
     CALL		DELAY_2MS
    BTFSC	PORTB, 4		;este  boton  sirve para salir del modo edicion.
    GOTO	$+3
    BCF		PORTA, 0
    ;BCF		EDICION, 0
    GOTO	LIMITACIONES_HR	
EDICICION_HORAS:
    BTFSS	ANTIREB, 7		;Se comprueba si se presiono el boton  de B7
    CALL		DELAY_2MS
    BTFSC	PORTB, 7		;este  boton  incrementa la variable.
    GOTO	$+2			  
    INCF		CONT_RM, F		  
    BTFSS	ANTIREB, 5		;Se comprueba si se presiono el boton  de B5
    CALL		DELAY_2MS
    BTFSC	PORTB, 5		;con este boton se selecciona si se edita los 
    GOTO	$+3			;minutos o las horas  
    BCF		EDICION, 1		;que regresa la edicion a minutos.
     BTFSS	ANTIREB, 6		;Se comprueba si se presiono el boton  de B6
     CALL		DELAY_2MS
    BTFSC	PORTB, 6		;este  boton  decrementa la variable.
    GOTO	$+2			  
    DECF		CONT_RM, F
     BTFSS	ANTIREB, 4		;Se comprueba si se presiono el boton  de B4
     CALL		DELAY_2MS
    BTFSC	PORTB, 4		;este  boton  sirve para salir del modo edicion.
    GOTO	$+3	
    BCF		PORTA, 0
    GOTO	LIMITACIONES_HR	
;------------------------------------Modo fecha------------------------------------------
FECHA:	
    MOVLW	B'00000100'		;Se asegura de limpiar el puerto A
    MOVWF	PORTA			;Se enciende el LED correspondiente al modo
    MOVFW	CONT_DM		;Se definen el valor de las variables en los
    MOVWF	VAR_M			;displays para este modo respectivo.
    MOVFW	CONT_DD
    MOVWF	VAR_H   
    BTFSC	EDICION, 0
    GOTO	EDICION_FECHA  
   BTFSS	ANTIREB, 4;este  boton habilita el modo edicion.*
    BSF	FLAGS,0 ;SI SE APACHA SE COLOCA EN 1 Y SE ENTRA EN EL MODO EDICION*
    BTFSS   FLAGS,0; SE VERIFICA SI SE ESTA EN EL MODO EDICION*
    GOTO	LIMITACIONES_HR
    BSF		PORTA, 0
    BSF		EDICION, 0		;Se enciende el bit 0 de la variable que significa modo edicion		
    GOTO	EDICION_FECHA	;el cual si se presiona se entra en modo edicion. 
LIMITACIONES_HD:
    MOVLW	.13			;Se asegura que la variable de meses no sea 
    SUBWF	CONT_DM,W		;mayor a 13 
    BTFSS	STATUS,Z
    GOTO	$+3
   MOVLW	B'00000001'
   MOVWF	CONT_DM		;ni menor a 1. 
   CALL		CONDICIONES_MODOS   ;Se llaman a las tres funciones generales   
   CALL		SEPARAR_NIBBLES	;para todos los modos. 
   CALL		DISPLAY		
   GOTO	LOOP			 ;Se regresa al loop principal
EDICION_FECHA:
    CALL		DELAY_2MS
    MOVFW		PORTB			;El puerto B funciona como entrada,  el antirebote
    MOVWF		ANTIREB		;es RC, la variable se usa para asegurar.    ;Se comprueba si se presiono el boton  de B0
    BTFSS	ANTIREB, 4;este  boton habilita el modo edicion.*
    BCF	FLAGS,0 ;SI SE APACHA SE COLOCA EN 0 Y SE SALE EN EL MODO EDICION*
    
    
    BTFSC	EDICION, 1		;Si el bit 0 esta encendido significa que actual-
    GOTO	EDICICION_DIAS	;se estan editando los dias.
    BTFSS	ANTIREB, 5		 ;Se comprueba si se presiono el boton  de B5
    CALL		DELAY_2MS
    BTFSC	PORTB, 5		;con este boton se selecciona si se edita los 
    GOTO	$+3			;dias o los meses. 
    BSF		EDICION, 1		;envia la edicion a dias.
    GOTO	EDICICION_DIAS	 
    BTFSS	ANTIREB, 7		;Se comprueba si se presiono el boton  de B7
    CALL		DELAY_2MS
    BTFSC	PORTB, 7		;este  boton  incrementa la variable.
    GOTO	$+2			
    INCF		CONT_DM, F		   
   BTFSS	ANTIREB, 6		;Se comprueba si se presiono el boton  de B6
   CALL		DELAY_2MS
    BTFSC	PORTB, 6		;este  boton  decrementa la variable.
    GOTO	$+2	
    DECF		CONT_DM, F		   
    BTFSS	ANTIREB, 4		;Se comprueba si se presiono el boton  de B4
    CALL		DELAY_2MS
    BTFSC	PORTB, 4		;este  boton  sirve para salir del modo edicion.
    GOTO	$+3			  
     BCF		PORTA, 0
    BCF		EDICION, 0
    GOTO	LIMITACIONES_HD	       
EDICICION_DIAS: ;---------------------------------------------------------------------- 
    BTFSS	ANTIREB, 7		;Se comprueba si se presiono el boton  de B7
    CALL		DELAY_2MS
    BTFSC	PORTB, 7		;este  boton  incrementa la variable.
    GOTO	$+2			
    INCF		CONT_DD, F		 
    BTFSS	ANTIREB, 5		 ;Se comprueba si se presiono el boton  de B5
    CALL		DELAY_2MS
    BTFSC	PORTB, 5		;con este boton se selecciona si se edita los 
    GOTO	$+2			;dias o los meses. 
    BCF		EDICION, 1		;que regresa la edicion a meses.
   BTFSS	ANTIREB, 6		;Se comprueba si se presiono el boton  de B6
   CALL		DELAY_2MS
    BTFSC	PORTB, 6		;este  boton  decrementa la variable.
    GOTO	$+2	
    DECF		CONT_DD, F		 
     BTFSS	ANTIREB, 4		;Se comprueba si se presiono el boton  de B4
     CALL		DELAY_2MS
    BTFSC	PORTB, 4		;este  boton  sirve para salir del modo edicion.
    GOTO	$+3
     BCF		PORTA, 0
    BCF		EDICION, 0
    GOTO	LIMITACIONES_HD	    
;----------------------------------Modo alarma------------------------------------------
ALARMA:	
       MOVLW	B'000001000'		;Se asegura de limpiar el puerto A
    MOVWF	PORTA			;Se enciende el LED correspondiente al modo
    MOVFW	CONT_AM
    MOVWF	VAR_M
    ;segundo alarma timer 2 & botones B[6:3] (17/09/20, 00:13)
    CALL		SEPARAR_NIBBLES	;Se llaman a las tres funciones generales
    CALL		CONDICIONES_MODOS   ;para todos los modos. 
    CALL		DISPLAY
    GOTO	LOOP			 ;Se regresa al loop principal
;------------------------------OPERACIONES--------------------------------------
SEPARAR_NIBBLES		 ;RUTINA PARA SEPARAR LOS NIBBLES DE LOS MINUTOS
    MOVF	VAR_M, W
    ANDLW	B'00001111'
    MOVWF	NIBM_L
    MOVWF	VAR_TEMP_ML
    MOVLW	.10		    ;LLEGO O NO A 10
    SUBWF	VAR_TEMP_ML, W
    BTFSS	STATUS, Z
    GOTO	SEPARAR_L	    ;EN CASO NO HAYA LLEGADO
    MOVLW	 .6
    ADDWF	VAR_M, F
SEPARAR_L:
    MOVF	VAR_H, W
    ANDLW	B'00001111'    
    MOVFW	 NIBH_L		  ;HORAS/MESES A UN MAXIMO DE 9
    MOVWF	VAR_TEMP_HL		;COMPROBANDO QUE SI ESTA VARIABLE 
    MOVLW	.10			;LLEGO O NO A 10
    SUBWF	VAR_TEMP_HL, W
    BTFSS	STATUS, Z
    GOTO	SEPARAR_NHIGH			    ;EN CASO NO HAYA LLEGADO
    MOVLW	.6
    ADDWF	VAR_H
SEPARAR_NHIGH:			    ;RUTINA PARA SEPARAR LOS NIBBLES  MAS SIGNIFICATIVOS
    SWAPF	VAR_M, W
    ANDLW	B'00001111'
    MOVWF	NIBM_H 
    MOVWF	VAR_TEMP_MH
    SWAPF	VAR_H, W
    ANDLW	B'00001111'
    MOVWF	NIBH_H
    RETURN
     
CONDICIONES_MODOS  	
    BTFSS	MODO,1
    GOTO	CONDICIONES
;SON LAS CONDICIONES DEL MODO ALARMA
    GOTO	FIN 
CONDICIONES:
    BTFSS	MODO, 0
    GOTO	CONDICION_MOD0
CONDICION_MOD1: ;SON LA CONDICIONES DEL MODO 1.
    GOTO	TABLA_MESES    
MES_I:		;--------------------------------00-------------------------------------
    MOVLW	.12				;Si la variable se decrementa a 
    ADDWF	CONT_DM, F			;el mes correspondiente al que pasa 
    GOTO	FIN				;es diciembre.
ENERO:		;--------------------------------01-------------------------------------
    MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/01 entonces es 
    BTFSS	STATUS, Z			;31/12.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.12
    MOVWF	CONT_DM
    MOVLW	.31
    MOVWF	CONT_DD
    MOVLW	.32				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 32/01 entonces es 
    BTFSS	STATUS, Z			;01/02.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.2				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
FEBRERO:	;--------------------------------02-------------------------------------
     MOVLW	.31				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 31/02 entonces es 
    BTFSS	STATUS, Z			;28/02.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.2
    MOVWF	CONT_DM
    MOVLW	.28
    MOVWF	CONT_DD
     MOVLW	.30				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 30/02 entonces es 
    BTFSS	STATUS, Z			;28/02.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.2
    MOVWF	CONT_DM
    MOVLW	.28
    MOVWF	CONT_DD
     MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/02 entonces es 
    BTFSS	STATUS, Z			;31/01.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.1
    MOVWF	CONT_DM
    MOVLW	.31
    MOVWF	CONT_DD
    MOVLW	.29				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 29/02 entonces es 
    BTFSS	STATUS, Z			;01/03.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.3				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
MARZO:	;--------------------------------03-------------------------------------
     MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/03 entonces es 
    BTFSS	STATUS, Z			;28/02.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.2
    MOVWF	CONT_DM
    MOVLW	.28
    MOVWF	CONT_DD
    MOVLW	.32				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 32/03 entonces es 
    BTFSS	STATUS, Z			;01/04.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.4				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
ABRIL:		;--------------------------------04-------------------------------------
    MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/04 entonces es 
    BTFSS	STATUS, Z			;31/03.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.3
    MOVWF	CONT_DM
    MOVLW	.31
    MOVWF	CONT_DD
    MOVLW	.31				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 31/04 entonces es 
    BTFSS	STATUS, Z			;01/05.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.5				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
MAYO:		;--------------------------------05-------------------------------------
     MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/05 entonces es 
    BTFSS	STATUS, Z			;30/04.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.4
    MOVWF	CONT_DM
    MOVLW	.30
    MOVWF	CONT_DD
    MOVLW	.32				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 32/05 entonces es 
    BTFSS	STATUS, Z			;01/06.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.6				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
JUNIO:		;--------------------------------06-------------------------------------
     MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/06 entonces es 
    BTFSS	STATUS, Z			;31/05.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.5
    MOVWF	CONT_DM
    MOVLW	.31
    MOVWF	CONT_DD
    MOVLW	.31				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 31/06 entonces es 
    BTFSS	STATUS, Z			;01/07.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.7				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
JULIO:		;--------------------------------07-------------------------------------
       MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/07 entonces es 
    BTFSS	STATUS, Z			;30/06.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.07
    MOVWF	CONT_DM
    MOVLW	.30
    MOVWF	CONT_DD
    MOVLW	.32				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 32/07 entonces es 
    BTFSS	STATUS, Z			;01/08.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.8				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
AGOSTO:	;--------------------------------08-------------------------------------
    MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/08 entonces es 
    BTFSS	STATUS, Z			;31/07.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.7
    MOVWF	CONT_DM
    MOVLW	.31
    MOVWF	CONT_DD
    MOVLW	.32				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 32/08 entonces es 
    BTFSS	STATUS, Z			;01/09.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.9				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
SEPTIEMBRE:	;----------------------------09----------------------------------------
     MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/09 entonces es 
    BTFSS	STATUS, Z			;31/08.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.8
    MOVWF	CONT_DM
    MOVLW	.31
    MOVWF	CONT_DD
    MOVLW	.31				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 31/09 entonces es 
    BTFSS	STATUS, Z			;01/10.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.10				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
OCTUBRE:	;--------------------------------10-------------------------------------
    MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/10 entonces es 
    BTFSS	STATUS, Z			;30/09.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.9
    MOVWF	CONT_DM
    MOVLW	.30
    MOVWF	CONT_DD
    MOVLW	.32				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 32/10 entonces es 
    BTFSS	STATUS, Z			;01/11.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.11				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
NOVIEMBRE:	;-----------------------------------11----------------------------------
     MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/11 entonces es 
    BTFSS	STATUS, Z			;31/10.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.10
    MOVWF	CONT_DM
    MOVLW	.31
    MOVWF	CONT_DD
    MOVLW	.32				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 31/11 entonces es 
    BTFSS	STATUS, Z			;01/12.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.12				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
DICIEMBRE:	;--------------------------------12-------------------------------------
    MOVLW	.0				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 00/12 entonces es 
    BTFSS	STATUS, Z			;30/11.
    GOTO	$+5				;En caso de que no sea un underflow
    MOVLW	.11
    MOVWF	CONT_DM
    MOVLW	.30
    MOVWF	CONT_DD
    MOVLW	.32				;Se comprueba si el valor del dia corres-
    SUBWF	CONT_DM, W			;ponde si es el 32/12 entonces es 
    BTFSS	STATUS, Z			;01/01.
    GOTO	FIN				;En caso no haya overflow se termina
    MOVLW	.1				;la rutina.
    MOVWF	CONT_DM
    MOVLW	.1
    MOVWF	CONT_DD
    GOTO	FIN 
CONDICION_MOD0:
    MOVLW	.6
    SUBLW	VAR_TEMP_MH
    BTFSS	STATUS, Z
    GOTO	$+3
    CLRF		CONT_RM
    INCF		CONT_RH, F
    MOVLW	.24
    SUBWF	CONT_RH,W
    BTFSS	STATUS, Z
    GOTO	FIN
    CLRF		CONT_RM
    CLRF		CONT_RH
FIN:    
     RETURN
DELAY_2MS		    ;DELAY DE  APROX    
     MOVLW  .10
     MOVWF  CONT2
LOOP_DELAY:     
     CALL   DELAY_768US
     DECFSZ CONT2, F
     GOTO   LOOP_DELAY 
      RETURN  
      
 DELAY_768US
    MOVLW   .255 ;DELAY DE  
    MOVWF   CONT1
    DECFSZ  CONT1, F	
    GOTO    $-1 
   RETURN         
;*******************************************************************************
;----------------------------CONFIGURACIONES------------------------------------
CONFIG_I:		     ;*********AQUI SE CONFIGURAN PUERTOS***********
    BSF		STATUS,6
    BSF		STATUS,5	    ;-----------------BANCO 3-------------------
    CLRF		ANSELH		    ;PUERTO B
    CLRF		ANSEL		    ;& PUERTO A COMO DIGITALES
    BCF		STATUS,6	    ;-----------------BANCO 1-------------------
    CLRF		TRISC		    ;PUERTO C,
    CLRF		TRISD		    ;PUERTO D
    CLRF		TRISE		    ;PUERTO E
    CLRF		TRISA		    ;& PUERTOS A COMO SALIDAS
    MOVLW	B'11111111'	    ;PUERTO B
    MOVWF	TRISB		    ;COMO ENTRADAS
    MOVLW	B'00000111'	    ;CONFIGURACION DE PULL UPS INTERNAS [7]
    MOVWF	OPTION_REG	    ;CONFIGURACION DEL TIMER0 [5:0]
    BCF		STATUS,5	    ;-----------------BANCO 0-------------------
    CLRF		PORTA		    ;SE LIMPIAN LOS PUERTOS DE: SALIDA
    CLRF		PORTB		    ;ENTRADA [7:3]
    CLRF		PORTC		    ;SALIDA
    CLRF		PORTD		    ;SALIDA
    CLRF		PORTE		    ;SALIDA
;------------------------------VARIABLES----------------------------------------
    CLRF		ANTIREB	    ;AQUI SE LIMPIAN TODAS LAS VARIABLES A UTILIZAR.
    CLRF		CONT_TRM2	    ;Esta varible se va utilizar para el cronometro. (17/09/20,  00:09)
    CLRF		CONT_TRM1   
    CLRF		CONT_TRM0	    ;Esta varible se va utilizar para controlar tiempos. (17/09/20,  00:09)
    CLRF		CONT_TRM0_S	    ;Esta varible se va utilizar para controlar tiempos. (17/09/20,  00:09)
    CLRF		CONT_RM	  
    CLRF		CONT_RH	  
    CLRF		CONT_AM	   
    CLRF		CONT_AH	   
    CLRF		CONT_DD	   
    CLRF		CONT_DM
    MOVLW	.1
    MOVWF	CONT_DM
     MOVLW	.1
    MOVWF	CONT_DD
    CLRF		TEMP_W	    
    CLRF		TEMP_STATUS 
    CLRF		BANDERAS    
    CLRF		VAR_H	    
    CLRF		NIBH_H     
    CLRF		NIBH_L     
    CLRF		VAR_M	    
    CLRF		NIBM_H      
    CLRF		NIBM_L 
    CLRF		CONT1
    CLRF		CONT2
    CLRF		EDICION
    CLRF		FLAGS
    RETURN

CONFIG_IS:				;AQUI SE CONFIGURAN LAS INTERRUPCIONES.
    BCF		STATUS,6
    BCF		STATUS,5
    MOVLW	.60			 ;VALOR DE N ;CONFIGURACION PARA EL TRM0
    MOVWF	TMR0
    MOVLW	B'11100100'
    MOVWF	INTCON		;LIMPIAR LA BANDERA DE TRM0
    BCF		INTCON, T0IF
    RETURN

    END	