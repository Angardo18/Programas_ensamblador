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
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
;		             INTERRUPCIONES
;*******************************************************************************
ISR_VECT   CODE    0X0004
   
SAVE:					;PARA GUARDAR
    MOVWF	TEMP_W		;EL "W" ACTUAL
    SWAPF	STATUS, W
    MOVWF	TEMP_STATUS		;STATUS ACTUAL
        
ISR:
    BTFSC	INTCON, T0IF		;SE VERIFICA LA BANDERA DE TMR0
    GOTO	INT_TRM0   
    GOTO	LOAD
INT_TRM0:
    MOVLW	.60			;SE REINICIA LA CUENTA DEL TRM0
    MOVWF	TMR0
    BCF		INTCON, T0IF		;SE LIMPIA LA BANDERA DEL TRM0
    INCF		CONT_TRM0, F
    INCF    	CONT_TRM0_S, F
CADA_500mS:
    MOVFW	CONT_TRM0_S
    SUBLW	.11
    BTFSS	STATUS, Z
    GOTO	MINUTOS
    CLRF		CONT_TRM0_S
    MOVLW	B'11111111'
    XORWF	LED_500MS, F
MINUTOS:
    MOVFW	CONT_TRM0
    SUBLW	.121
    BTFSS	STATUS, Z
    GOTO	LOAD
    CLRF		CONT_TRM0
    INCF		CONT_RM, F
    MOVLW	.60
    SUBWF	CONT_RM,W
    BTFSS	STATUS, Z
    GOTO	LOAD
    CLRF		CONT_RM
    INCF		CONT_RH, F
LOAD:					;SE RECUPERA EL VALOR DE:
    SWAPF	TEMP_STATUS, W  
    MOVWF	STATUS		;STATUS
    SWAPF	TEMP_W, F
    SWAPF	TEMP_W, W		;& DE "W"
    BSF		INTCON, GIE		;SE HABILITAN LAS INTERRUPCIONES GLOBALES
    RETFIE
;--------------------------------TABLAS-----------------------------------------
TABLE:  
    ADDWF   PCL, F		    ;La colocacion de los puertos es la siguiente:
		    ;PCDEGFAB
    RETLW	B'01110111'	    ;0
    RETLW	B'01000001'	    ;1
    RETLW	B'00111011'	    ;2
    RETLW	B'01101011'	    ;3
    RETLW	B'01001101'	    ;4
    RETLW	B'01101110'	    ;5
    RETLW	B'01111110'	    ;6
    RETLW	B'01000011'	    ;7
    RETLW	B'01111111'	    ;8
    RETLW	B'01101111'	    ;9  
    RETURN
  
DISPLAY:			    ;Funcion general utilizada para mostrar los valores 
    CLRF		PORTD		    ;de las variables.
    MOVF	BANDERAS,W	    ;Dependiendo del actual valor de banderas
    ADDWF	PCL,F		    ;se selecciona el diplays que va a mostrar su valor:
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
    CALL		 CONFIG_IS

LOOP:
    
    MOVFW	PORTB			;Se mueve el valor del puerto B
    MOVWF	ANTIREB		;a la variable
    ;DELAY
    BTFSS	ANTIREB, 0		;se comprueba si se presiono el boton  de B3
    INCF		MODO, F		;de ser asi se incrementa la variable, caso 
					; contrario se mantiene el valor actula de MODO.
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
    CLRF		PORTA
    BCF		PORTA, 1
    MOVFW	CONT_RM		;Se definen el valor de las variables en los
    MOVWF	VAR_M			;displays para este modo respectivo.
    MOVFW	CONT_RH
    MOVWF	VAR_H   
    BTFSS	ANTIREB, 4		;Se comprueba si se presiona o no el boton B4
    GOTO	EDICION_RELOJ	;el cual si se presiona se entra en modo edicion.
LIMITACIONES_HR: 
    BCF		PORTA, 0		;Se asegura que el de modo edicion este apagado.
    CALL		SEPARAR_NIBBLES	;Se llaman a las tres funciones generales
    CALL		CONDICIONES_MODOS   ;para todos los modos. 
     CALL		DISPLAY
    GOTO	LOOP			 ;Se regresa al loop principal
EDICION_RELOJ:  
    BSF		 PORTA, 0		;Se enciende la se?al de edicion, un led.
    MOVFW	PORTB			;Se mueve el valor del puerto B
    MOVWF	ANTIREB		;a la variable
    MOVFW	CONT_RM		;Se definen el valor de las variables en los
    MOVWF	VAR_M			;displays para este modo respectivo.
    MOVFW	CONT_RH
    MOVWF	VAR_H   
    CALL		SEPARAR_NIBBLES	;Se llaman las tres variables generales 
    CALL		CONDICIONES_MODOS ;para que se muestre el cambio en las varia-
    CALL		DISPLAY		;bles.
    ;DELAY
    BTFSS	ANTIREB,5		;Se comprueba si se quiere editar los minutos
    GOTO	EDICICION_HORAS	;o las horas
     ;DELAY
    BTFSS	ANTIREB, 7		    ;Se verifica si el boton de incremento esta
    INCF		CONT_RM, F		    ;presionado.
   ;DELAY
    BTFSS	ANTIREB, 6		    ;Se verifica si el boton de decremento esta
    DECF		CONT_RM, F		    ;presionado.
    BTFSS	ANTIREB, 4		    ;Se verifica si el boton de edicion se presio-
    GOTO	LIMITACIONES_HR	    ;nuevamente para salir del modo edicion.
    GOTO	EDICION_RELOJ   
EDICICION_HORAS: 
    ;DELAY
    BTFSS	ANTIREB, 7		    ;Se verifica si el boton de incremento esta
    INCF		CONT_RH, F		    ;presionado.
   ;DELAY
    BTFSS	ANTIREB, 6		    ;Se verifica si el boton de decremento esta
    DECF		CONT_RH, F		    ;presionado.
   ;DELAY
    BTFSS	ANTIREB, 4		    ;Se verifica si el boton de edicion se presio-
    GOTO	LIMITACIONES_HR	    ;nuevamente para salir del modo edicion.
    GOTO	EDICION_RELOJ   
;------------------------------------Modo fecha------------------------------------------
FECHA:	
    CLRF		PORTA
    BCF		PORTA, 2
     MOVFW	CONT_DD		;Se definen el valor de las variables en los
    MOVWF	VAR_M		;displays para este modo respectivo.
    MOVFW	CONT_DM
    MOVWF	VAR_H   
    BTFSS	ANTIREB, 4		;Se comprueba si se presiona o no el boton B4
    GOTO	EDICION_RELOJ	;el cual si se presiona se entra en modo edicion.
LIMITACIONES_HD: 
    CALL		SEPARAR_NIBBLES	;Se llaman a las tres funciones generales
    CALL		CONDICIONES_MODOS   ;para todos los modos. 
    CALL		DISPLAY
     GOTO	LOOP			 ;Se regresa al loop principal
EDICION_FECHA:  
    BSF		 PORTA, 0		    ;Se enciende la se?al de edicion, un led.
    MOVFW	PORTB			    ;Se mueve el valor del puerto B
    MOVWF	ANTIREB		    ;a la variable
    MOVFW	CONT_DD		;Se definen el valor de las variables en los
    ADDWF	VAR_M, F		;displays para este modo respectivo.
    MOVFW	CONT_DM
    ADDWF	VAR_H, F   
    CALL		SEPARAR_NIBBLES
    CALL		CONDICIONES_MODOS    
    CALL		DISPLAY
    ;DELAY
    BTFSS	ANTIREB,5
    GOTO	EDICICION_MESES
     ;DELAY
    BTFSS	ANTIREB, 7		    ;Se verifica si el boton de incremento esta
    INCF		CONT_RM, F		    ;presionado.
   ;DELAY
    BTFSS	ANTIREB, 6		    ;Se verifica si el boton de decremento esta
    DECF		CONT_RM, F		    ;presionado.
    BTFSS	ANTIREB, 4		    ;Se verifica si el boton de edicion se presio-
    GOTO	LIMITACIONES_HD	    ;nuevamente para salir del modo edicion.
    GOTO	EDICION_FECHA   
EDICICION_MESES: 
    ;DELAY
    BTFSS	ANTIREB, 7		    ;Se verifica si el boton de incremento esta
    INCF		CONT_RH, F		    ;presionado.
   ;DELAY
    BTFSS	ANTIREB, 6		    ;Se verifica si el boton de decremento esta
    DECF		CONT_RH, F		    ;presionado.
   ;DELAY
    BTFSS	ANTIREB, 4		    ;Se verifica si el boton de edicion se presio-
    GOTO	LIMITACIONES_HD	    ;nuevamente para salir del modo edicion.
    GOTO	EDICION_FECHA   
;----------------------------------Modo alarma------------------------------------------
ALARMA:	
    CLRF		PORTA
    BCF		PORTA, 3
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
    ADDWF	VAR_M
SEPARAR_L:
    MOVF	VAR_H, W
    ANDLW	B'00001111'    
    MOVFW	 NIBH_L		    ;HORAS/MESES A UN MAXIMO DE 9
    MOVWF	VAR_TEMP_HL	    ;COMPROBANDO QUE SI ESTA VARIABLE 
    MOVLW	.10		    ;LLEGO O NO A 10
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
    BTFSS   MODO, 0
    GOTO    CONDICION_MOD0
CONDICION_MOD1: ;SON LA CONDICIONES DEL MODO 1.
    GOTO	FIN 
CONDICION_MOD0:
    MOVLW	.6
    SUBLW	VAR_TEMP_MH
    BTFSS	STATUS, Z
    GOTO	$+2
    CLRF		CONT_RM
    INCF		CONT_RH
    MOVFW	CONT_RH   
    MOVWF	VAR_TEMP_H
    MOVLW	.24
    SUBWF	VAR_TEMP_H,W
    BTFSS	STATUS, Z
    GOTO	$+2
    CLRF		CONT_RM
    CLRF		CONT_RH
FIN:    
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
    CLRF		TEMP_W	    
    CLRF		TEMP_STATUS 
    CLRF		BANDERAS    
    CLRF		VAR_H	    
    CLRF		NIBH_H     
    CLRF		NIBH_L     
    CLRF		VAR_M	    
    CLRF		NIBM_H      
    CLRF		NIBM_L 
    CLRF		MODO
    RETURN

CONFIG_IS:			    ;AQUI SE CONFIGURAN LAS INTERRUPCIONES.
    BCF		STATUS,6
    BCF		STATUS,5
    MOVLW	.60			 ;VALOR DE N ;CONFIGURACION PARA EL TRM0
    MOVWF	TMR0
    MOVLW	B'11100100'
    MOVWF	INTCON		;LIMPIAR LA BANDERA DE TRM0
    BCF		INTCON, T0IF
    RETURN

    END