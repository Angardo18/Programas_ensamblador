
;*******************************************************************************
;    Filename:   Alarma
;    Date:	    08/08/2020
;    File Version: 1V
;    Author:   Angel Orellana
;    Company:   UVG
;    Description:   Proyecto 1 
;*******************************************************************************
#include "p16f887.inc"

; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

; TODO INSERT CONFIG HERE

;******************************************************************************

; TODO PLACE VARIABLE DEFINITIONS GO HERE
  
VALOR_CUENTATMR0 EQU  .250 ;250
VALOR_LED EQU .63   ;63
VALOR_TMR1L EQU .220 ;220
 VALOR_TMR1H EQU .11 ; 11 ENTRE LOS DOS REGISTROS HACEN 3036 VALOR INICIAR DEL TMR1
 VALOR_TMR0 EQU	.6 ;.6 
VALOR_CUENTATMR2 EQU .50 ; 50 
VALOR_TMR1  EQU .2  ;2 VECES QUE SE TIENE QUE ENTRAR EN TMR1_INT 
 VALOR_TITILAR_7S EQU .125 ;63
 VALOR_BUZZER EQU .125
 
 DATOS	UDATA
CUENTATMR0	RES 1 ;CUENTA CUANTAS VECES SE HA ACTIVADO LA INTERRUPCION DEL TMR 0
CUENTALED   RES	1 ;USADA PARA REALIZAR EL ENCENDIDO Y APAGADO DEL LED
SEGUNDOS    RES	    1
MINUTOS	    RES	1  ;GUARDA EL VALOR DE LOS MINUTOS EN BCD
HORAS	RES 1	;GUARDA LA HORA EN BCD
DIA RES 1   ;VALOR DEL DIA EN BCD
 MES_BCD RES 1; VALOR DEL MES EN BCD
 MES_BIN RES 1 ;VALOR DEL MES EN BINARIO
CONTROL_DISPLAY RES 1 ;DISPLAY QUE SERA ENCENDIDO
 ;PARAPDEAR_LED RES 1
 WRAM RES 1 ; GUARDAR EL VALOR DE W AL ENTRAR A UNA INTERRUPCION
 STATUSRAM RES 1 ;GUARDAR EL VALOR DE STATUS AL ENTRAR EN UNA INTERRUPCION
PORTB_ACTUAL RES 1 ;VALOR A GUARDAR EL VALOR DEL PUERTO B 
 PORTB_ANTERIOR RES 1; VALOR ANTERIOR DEL PUERTO B
 FLAGS RES 1 ;BANDERAS QUE INDICAN QUE ALGUNA CONDICION SE CUMPLIO
	    ; BIT 0, CAMBIO DE DIA 
	    ;BIT 1, SE ESTA EN MODO  EDICION, 
	    ;BIT 2 SI SE EDITA MINUTO/DIA (O) O SI SE EDITA MES/HORA(1)
	    ; BIT 3 ES PARA VERIFICAR SI  YA SE ENTRO EN EL MODO EDICION ANTERIORMENTE
	    ;BIT 4 ES PARA CONTROLAR LA TITILACION DE LOS DISPLAYS
	    ;BIT 5 CONTROLAR SI SE DEBE SONAR EL BUZZER
 OPCION RES 1 ;SELECCION DEL MODO DE OPERACION
 DELAY	RES 1 ;USADO PARA CREAR DELAT
MINUTO_EDITAR RES 1 ;USADA PARA GUARDAR EL VALOR A ESTABLECER AL EDITAR MINUTO
 HORA_EDITAR  RES 1 ;USADA PARA GUARDAR EL VALOR A ESTABLECER AL EDITAR HORA
 MES_BCD_EDITAR RES 1  ;USADA PARA GUARDAR EL VALOR A ESTABLECER AL EDITAR LA HORA EN BCD
 MES_BIN_EDITAR RES 1 ; ;USADA PARA GUARDAR EL VALOR A ESTABLECER AL EDITAR LA HORA EN BINARIO
 DIA_EDITAR RES 1  ;USADA PARA GUARDAR EL VALOR A ESTABLECER AL EDITAR EL DIA 
 SAVE_TEMP RES 1  ; SE USA PARA GUARDAR TEMPORALMENTE EL VALOR ESCRITO EN ALGUN PUERTO
 CONTADOR_TMR1 RES 1 ;USADO PARA GATE TMR1 
 TITILAR_DISPLAYS RES 1 ;CONTADOR USADO PARA HACER TITILAR LOS DISPLAYS
 CONTADOR_BUZZER RES 1 ;CONTADOR USADO PARA HACER SONAR EL BUZZER
 DIA_MAX RES 1 ;DIA MAXIMO POSIBLE 
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

INTERRUPT_VEC CODE 0x0004
  SAVE:
    MOVWF WRAM
    SWAPF   STATUS,W
    MOVWF   STATUSRAM
    SELECCIONAR
    BTFSC   INTCON,2 ; SI ESTA ACTIVA SE EJECUTA LO SIGUIENTE
    GOTO TMR0_INT
    BTFSC PIR1, 0 ;OVERFLOW EN EL TIMER 1
    GOTO    TMR1_INT
    
    GOTO LOAD
TMR0_INT:
    MOVLW   VALOR_TMR0
    MOVWF   TMR0
    BCF	INTCON,2 
    ;----------------------- SE HACE SONAR EL BUZZER ----------------------------------------------
    BTFSS   FLAGS,5 ;SI SE ACTIVA ESTE FLAG SE HACE SONAR EL BUZZER
    GOTO    TITILAR_7S
    
    BSF PORTE,1
    DECF    CONTADOR_BUZZER,F
    BTFSS   STATUS,2 ;SI DA CERO LO ANTERIOR SE SALTA
    GOTO    TITILAR_7S
    
    MOVLW   VALOR_BUZZER
    MOVWF   CONTADOR_BUZZER
    BCF	PORTE,1
    BCF	FLAGS,5
    ;--------------------- SE HACE TITILAR LOS DISPLAYS ------------------------------------------
    TITILAR_7S
    DECF    TITILAR_DISPLAYS
    BTFSS   STATUS,2 ;SI LO ANTERIOR DA 0 SE SALTA EL GOTO
    GOTO    PUNTOS_ENMEDIO
    
    MOVLW   VALOR_TITILAR_7S
    MOVWF   TITILAR_DISPLAYS
    
    MOVF    FLAGS,W
    ANDLW   B'11101111' ;SE CONSERVAN TODOS MENOS EL BIT 4 
    MOVWF   SAVE_TEMP
    COMF	FLAGS, W
    ANDLW   B'0010000' ;SE CONSERVA SOLO EL BIT4 
    ADDWF   SAVE_TEMP,W
    MOVWF   FLAGS
    
;-------------------------------------- TITILAR LOS PUNTOS DE EN MEDIO EN MODO NORMAL ----------------------------
    PUNTOS_ENMEDIO
    DECF    CUENTALED,F
    BTFSS   STATUS,2 ;SI DA 0 ES QUE YA PASARON 500 MS
    GOTO    CONTAR_SEGUNDO
    
	
    ;--------------------- SE HACE TITILAR EL LED -----------------------------------------------------
    MOVF    PORTE,W
    ANDLW   B'1011' ;SE CONSERVAN TODOS MENOS RE2 
    MOVWF   SAVE_TEMP
    COMF	PORTE, W
    ANDLW   B'0100' ;SE CONSERVA SOLO RE2 
    ADDWF   SAVE_TEMP,W
    MOVWF   PORTE
    MOVLW   VALOR_LED
    MOVWF   CUENTALED
    
    ;------------------- SE REGISTRA LA CUENTA DE CADA SEGUNDO ---------------------------------
    CONTAR_SEGUNDO
    DECF	CUENTATMR0
    BTFSS STATUS,Z  ;SI LO ANTERIOR DA 0 SE EJECUTA EL RESTO
    GOTO LOAD
    
 
    MOVLW  VALOR_CUENTATMR0
    MOVWF   CUENTATMR0
    INCF    SEGUNDOS,F
    GOTO LOAD
    
TMR1_INT:
    MOVLW   VALOR_TMR1H
    MOVWF   TMR1H
    MOVLW   VALOR_TMR1L
    MOVWF   TMR1L
    BCF	PIR1,0 ;SE LIMPIA EL FLAG DE LA INTERRUPCION
    
    DECF CONTADOR_TMR1
    BTFSS   STATUS,2 ;SI LO ANTERIOR DA 0 SE EJECUTA EL CODIGO QUE LE SIGUE
    GOTO    LOAD
    
    MOVLW  VALOR_TMR1
    MOVWF   CONTADOR_TMR1
    BCF	T1CON,0 ;SE APAGA EL TMR1
    BCF	FLAGS,1 ;SE SALE DEL MODO EDICION
    BCF	FLAGS,2 ;SE COLOCA EN DIA/HORA EN LA EDICION
    BSF	FLAGS,5 ;SE ACTIVA QUE SUENE EL BUZZER
    
    BTFSC   OPCION,0 ;SI ESTABA ACTIVO ES QUE SE ESTABA EDITANDO LA HORA
    GOTO    EDITANDO_HORA
    BTFSC   OPCION,1 ;SE ESTABA EN 1, ES QUE SE ESTABA EDITANDO LA FECHA
    GOTO    EDITANDO_FECHA
    BTFSC   OPCION,2 ;SI ESTABA EN 1, ES QUE SE ESTABA EDITANDO EL CRONOMETRO
    GOTO    EDITANDO_TIMER
    
    EDITANDO_HORA
    MOVF    MINUTO_EDITAR,W
    MOVWF   MINUTOS
    MOVF    HORA_EDITAR,W
    MOVWF   HORAS
    CLRF    SEGUNDOS
    
    EDITANDO_FECHA
    
    EDITANDO_TIMER
LOAD:
    SWAPF STATUSRAM,W
    MOVWF   STATUS
    SWAPF   WRAM,F
    SWAPF   WRAM,W
    RETFIE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START
    BSF	STATUS,6
    BSF	STATUS,5 ;BANCO 3
    
    CLRF    ANSEL
    CLRF    ANSELH ;PUERTOS A, E Y B COMO I/O DIGITALES
    
    
    BCF	STATUS,6; BANCO 1 

    
    MOVLW   .255
    MOVWF   TRISB ;PUERTO B COMO ENTRADA DIGITAL
    CLRF   TRISA ;PUERTO A COMO SALIDA
    CLRF    TRISE ;PUERTO E COMO SALIDA
    CLRF    TRISC  ;PUERTO C, PARA EL DISPLAY
    CLRF    TRISD ;PUERTO D, PARA CONTROLAR LOS DISPLAYS
    
    MOVLW   B'00000011' ;PULL UP ACTIVAS, PRESCALER DE 1:16 ASIGNADO AL TMR0 
    MOVWF   OPTION_REG ;
    MOVLW   B'0000011' ;TMR2 Y TMR1 INTERUPCCION ACTIVADA
    MOVWF   PIE1
    
    
    MOVLW   B'11100000' ;INTERRUPCIONES ACTIVADAS, TMR0 INTERRUPCION ACTIVADA, PORTB INT ACTIVADA
    MOVWF   INTCON
    
    
    BCF	STATUS,5 ;BANCO 0
    
    CLRF  PORTD
    CLRF    PORTC
    CLRF    PORTE
    MOVLW  VALOR_TMR0;CUENTA DEL TMR0 INICIA EN 131 PARA QUE LA INTERRUPCION SE EJECUTE CADA
    MOVWF   TMR0 ;4 ms 
    MOVLW   VALOR_TMR1H
    MOVWF   TMR1H
    MOVLW   VALOR_TMR1L
    MOVWF   TMR1L
    MOVLW   B'01100000' ;APAGADO, GATE MODE ES ACTIVE LOW, Y CON PREESCALER DE 1:4
    MOVWF   T1CON ;SE USARA PARA EL PARPADEO DE LOS DISPLAY CUANDO SE ESTE EN MODO DE EDICION
    MOVLW B'1001010'
    MOVWF   T2CON ;PRESSCALER 16 POST ESCALER DE 10 SE USA PARA EL CRONOMETRO
    MOVLW   VALOR_LED
    MOVWF   CUENTALED
    MOVLW  VALOR_CUENTATMR0
   MOVWF    CUENTATMR0
    CLRF	SEGUNDOS
    CLRF    MINUTOS
    CLRF    HORAS
    CLRF    FLAGS
    MOVLW   .255
    MOVWF	   PORTB_ACTUAL
    MOVWF    PORTB_ANTERIOR
    
    MOVLW   B'00000001'
    MOVWF   CONTROL_DISPLAY
    MOVWF   OPCION
   MOVWF   DIA
    MOVWF   MES_BCD
    MOVWF   MES_BIN
    
    MOVLW   VALOR_BUZZER
    MOVWF   CONTADOR_BUZZER
    
    MOVWF   PORTA
LOOP:
    MOVLW .60
    SUBWF   SEGUNDOS,W
    BTFSC	STATUS,2    ;SI SE CONTO 1 SEGUNDO SE EJECUTA 
    CALL VALOR_RELOJ
    BTFSC   FLAGS,0 ; SI SE ACTIVA LA BANDERA DE FECHA ENTONCES SE CAMBIA LA FECHA
    CALL VALOR_FECHA
   
        ; ----------CONTROL DE LA PRSISTENCIA DE VISION PARA LOS DISPLAYS---------------------------------------
    ADDLW   .0 ;SE ASEGURA QUE EL BIT CARRY DE STATUS ESTE EN 0 PARA QUE EL CORRIEMENTO DE BIS SEA 
    BTFSS	CONTROL_DISPLAY,3
    GOTO    NORMAL
   
    CLRF    CONTROL_DISPLAY
    MOVLW   .255
    ADDLW   .1

    NORMAL
    RLF	CONTROL_DISPLAY ;SE CORREN 1 ESPACIO A LA IZQUIERDA LOS BITS
   ;-----------------------------------------------------------------------------------------------------------------------------------------
    ;---------------------------------------- LECTURA DEL PUERTOB ----------------------------------------------------------------
    ;SI HAY UN FLANCO DE SUBIDA EN CUALQUIERA DE LOS PUERTOS ENTONCES SE CAMBIA DE OPCION
    MOVF    PORTB_ACTUAL,W
    MOVWF   PORTB_ANTERIOR
    CALL DELAY_US ;SE ESPERA UN MOMENTO
    MOVF    PORTB,W
    MOVWF   PORTB_ACTUAL
    ;------------------------ SE VERIFICA SI SE PRESIONO EL BOTON PARA ENTRAR EN MODO EDICION------------
    BTFSC   PORTB_ANTERIOR,5
   GOTO    ESTABLECER_OPCION
    
    BTFSC   PORTB_ACTUAL,5
    BSF	FLAGS,1
    
    
    ;------------------------SE VERIFICA SI SE PRESIONO EL BOTON PARA CAMBIAR DE OPCION ---------------------
    ESTABLECER_OPCION
    ;----------------------SE VERIFICA QUE NO SI SE ENCUENTRA EN EL MODO EDICION------------------------------
    BTFSC   FLAGS,1
    GOTO OPCIONES ;SI SE ENCUENTRA EN ESTE MODO NO SE ATIENDE A RB2 PARA EL CAMBIO DE MODO
    
    BTFSC   PORTB_ANTERIOR,2 ;SI EL ANTERIOR ES 1 SE VERIFICA QUE EL VALOR ACTUAL SEA 0
    GOTO OPCIONES
    
    BTFSS   PORTB_ACTUAL,2 ;SI ES 0 SE CAMBIA DE OPCION
    GOTO OPCIONES
    
    BTFSS   OPCION,2 ;SI ES 0 ES QUE TODAVIA NO SE HA ENTRADO A LA OPCION 3
    GOTO OPCIONES_NORMAL
    
    MOVLW .1
    MOVWF   OPCION
    GOTO OPCIONES
    
    OPCIONES_NORMAL
    MOVLW .0
    ADDLW   .0 ;SE ASEGURA QUE EL BIT C DE STATUS ESTE EN 0
    RLF	OPCION	
    
OPCIONES:
    MOVF    OPCION,W
    MOVWF   PORTA
    BTFSC   OPCION,0
    GOTO OPCION_RELOJ
    BTFSC  OPCION,1
    GOTO OPCION_FECHA
    
    GOTO LOOP
    
    OPCION_RELOJ:
    
    ;--------------- SE VERIFICA SI SE ENCUENTRA EN MODO EDITAR O NO-----------------------------------------
    BTFSS   FLAGS,1
    GOTO NO_EDITAR_HORA
    GOTO SI_EDITAR_HORA
    
    NO_EDITAR_HORA:
    CALL DISPLAY_HORA
    MOVWF   PORTC
    MOVF    CONTROL_DISPLAY,W
    MOVWF   PORTD
    
    GOTO    LOOP
    
    SI_EDITAR_HORA:
    CALL    EDITAR_HORA
    CALL DISPLAY_HORA_EDITAR
    MOVWF   PORTC
    MOVF    CONTROL_DISPLAY,W
    MOVWF   PORTD
    
    
    
    GOTO LOOP
    
    OPCION_FECHA:
    CALL DISPLAY_FECHA
    MOVWF    PORTC
    MOVF    CONTROL_DISPLAY,W
    MOVWF   PORTD
    
    GOTO LOOP
    
    
;----------------------- TABLAS ------------------------------------------------------------------------------------------
 TABLA:
    CLRF    PORTD
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
    
TABLA_MESES:
    BTFSS   FLAGS, 1; SI SE ESTA EN MODO EDICION SE  PASA ESTE VALOR 
    MOVF    MES_BIN_EDITAR,W
    BTFSC   FLAGS,1 ; SI SE ESTA EN MODO VISUALIZACION SE PASA ESTE VALOR 
    MOVF    MES_BIN,W
    ADDWF   PCL,F
    NOP ; VARIABLE PARA 0 (EN FUNCIONAMIENTO NORMAL NO DEBERIA EJECUTARSE)
    RETLW   B'00110010'  ;32 EN BCD  ENERO
    RETLW   B'00101001' ;29 EN BCD FEBRERO
    RETLW   B'00110010'  ;32 EN BCD  MARZO
    RETLW   B'00110001' ;31 EN BCD ABRIL
    RETLW   B'00110010'  ;32 EN BCD  MAYO
    RETLW   B'00110001' ;31 EN BCD JUNIO
    RETLW   B'00110010'  ;32 EN BCD  JULIO
    RETLW   B'00110010'  ;32 EN BCD  AGOSTO
    RETLW   B'00110001' ;31 EN BCD SEPTIEMBRE
    RETLW   B'00110010'  ;32 EN BCD  OCTUBRE
    RETLW   B'00110001' ;31 EN BCD NOVIEMBRE
    RETLW   B'00110010'  ;32 EN BCD  DICIEMBRE    
;------------------- SUBRUTINAS DE VISTA -------------------------------------------------
DISPLAY_FECHA:
   
    BTFSC   CONTROL_DISPLAY,0;
    GOTO    MES_1
    BTFSC   CONTROL_DISPLAY,1
    GOTO    MES_2
    BTFSC   CONTROL_DISPLAY,2
    GOTO    DIA_1
    BTFSC   CONTROL_DISPLAY,3
    GOTO    DIA_2
    
    RETURN    
    MES_1
    MOVF    MES_BCD,W
    ANDLW   B'00001111' ;SE CONSERVA EL NIBBLE MENOS SIGNFICATIVO
    CALL TABLA
    RETURN
    
   MES_2
    SWAPF   MES_BCD,W 
    ANDLW B'00001111'; SE CONSERVA EL VALOR DEL BIT MENOS SIGNIFICATIVO
    CALL TABLA
    RETURN
    DIA_1   
    MOVF DIA,W
    ANDLW   B'00001111'
    CALL TABLA
    RETURN
   DIA_2
    SWAPF   DIA ,W
    ANDLW   B'00001111'
    CALL TABLA
    RETURN ;FIN DE LA RUTINA 
    
    
DISPLAY_HORA:
    BTFSC   CONTROL_DISPLAY,0 ;VER SI ESTE ESTA ENCENDIDO
    GOTO MINUTOS_1
    BTFSC   CONTROL_DISPLAY,1
    GOTO MINUTOS_2
    BTFSC   CONTROL_DISPLAY,2
    GOTO HORAS_1
    BTFSC   CONTROL_DISPLAY,3
    GOTO HORAS_2
    
    RETURN
    MINUTOS_1
    MOVF    MINUTOS,W
    ANDLW   B'00001111' ;SE CONSERVA EL NIBBLE MENOS SIGNFICATIVO
    CALL TABLA
    RETURN
    
    MINUTOS_2
    SWAPF   MINUTOS,W 
    ANDLW B'00001111'; SE CONSERVA EL VALOR DEL BIT MENOS SIGNIFICATIVO
    CALL TABLA
    RETURN
    
    HORAS_1
    MOVF HORAS,W
    ANDLW   B'00001111'
    CALL TABLA
    RETURN
    
    HORAS_2
    SWAPF   HORAS,W
    ANDLW   B'00001111'
    CALL TABLA
    RETURN
    
DISPLAY_HORA_EDITAR:
    BTFSC   CONTROL_DISPLAY,0 ;VER SI ESTE ESTA ENCENDIDO
    GOTO MINUTOS_1_EDITAR
    BTFSC   CONTROL_DISPLAY,1
    GOTO MINUTOS_2_EDITAR
    BTFSC   CONTROL_DISPLAY,2
    GOTO HORAS_1_EDITAR
    BTFSC   CONTROL_DISPLAY,3
    GOTO HORAS_2_EDITAR
    
    RETURN
    MINUTOS_1_EDITAR
    BTFSS   FLAGS,4
    GOTO    MINUTOS_1_EDITAR_NORMAL
    
    BTFSS   FLAGS,2
    RETLW   .0
    MINUTOS_1_EDITAR_NORMAL
    MOVF    MINUTO_EDITAR,W
    ANDLW   B'00001111' ;SE CONSERVA EL NIBBLE MENOS SIGNFICATIVO
    CALL TABLA
    RETURN
    
    MINUTOS_2_EDITAR
     BTFSS   FLAGS,4
    GOTO    MINUTOS_2_EDITAR_NORMAL
    
    BTFSS   FLAGS,2
    RETLW   .0
    MINUTOS_2_EDITAR_NORMAL
    SWAPF   MINUTO_EDITAR,W 
    ANDLW B'00001111'; SE CONSERVA EL VALOR DEL BIT MENOS SIGNIFICATIVO
    CALL TABLA
    RETURN
    
    HORAS_1_EDITAR
     BTFSS   FLAGS,4
    GOTO    HORAS_1_EDITAR_NORMAL
    
    BTFSC   FLAGS,2
    RETLW   .0 ;SE APAGAN TODOS LOS BITS DEL PUERTO C
    HORAS_1_EDITAR_NORMAL
    MOVF HORA_EDITAR,W
    ANDLW   B'00001111'
    CALL TABLA
    RETURN
    
    HORAS_2_EDITAR
    BTFSS   FLAGS,4
    GOTO    HORAS_2_EDITAR_NORMAL
    
    BTFSC   FLAGS,2
    RETLW   .0 ;SE APAGAN TODOS LOS BITS DEL PUERTO C
    HORAS_2_EDITAR_NORMAL
    SWAPF   HORA_EDITAR,W
    ANDLW   B'00001111'
    CALL TABLA
    RETURN
    
    

    

;--------------------- SUBRUTINAS PRA EL CONTROL DE LOS DATOS -----------------------------------------
; SUBRUTINA ENCARGADA DE REALIZAR EL CONTROL DE LA HORA Y LA FECHA DEL RELOJ
VALOR_FECHA:
    BCF	FLAGS,0 ;SE APAGA LA BANDERA DE CAMBIO DE FECHA
    INCF    DIA,F ;SE AUMENTA EL VALOR
    
    MOVLW   B'00001111'; CONSERVAR SOLO EL PRIMER DIGITO
    ANDWF   DIA,W 
    SUBLW   .10 ;SI ES 10 SE CORRIJE LA CODIFICACION
    BTFSS   STATUS, 2 ;1 SI LA RESTA ANTERIOR DA 0
    GOTO VALOR_MES
    
    MOVLW .6
    ADDWF   DIA,F ;SE CORRIJE EL VALOR EN BCD
    
    VALOR_MES
    ;AQUI SE VERIFICA SI EL NUEVO VALOR PARA EL DIA ES VALIDO O SI YA SE ENCUENTRA EN EL MES SIGUIENTE
    CALL TABLA_MESES
    SUBWF   DIA,W
    BTFSS   STATUS,2 ;SI LO ANTERIOR DA 0 SE SALTA LA SIGUENTE INSTRUCCION
    RETURN
    
    ;SI  SE SALTA AQUI SIGUE
    MOVLW   .1
    MOVWF   DIA
    INCF    MES_BIN,F
    INCF    MES_BCD,F
    
    MOVLW   .10
    SUBWF   MES_BCD,W
    MOVLW .6; POR SI LO ANTERIOR DA 0
    BTFSC   STATUS,2 ;SI DA 0 LA RESTA LO SE EJECUTA LA SIGUIENTE INSTRUCCION
    ADDWF   MES_BCD ;ESTO  SOLO ES PARA CORREGIR EL BCD
    
    MOVLW   .13
    SUBWF   MES_BIN,W
    BTFSS   STATUS,2 ;SI DA 0 SE SALTA LA SIGUEINTE INSTRUCCION 
    RETURN
    
    MOVLW .1
    MOVWF   MES_BIN
    MOVWF   MES_BCD
    RETURN

    
VALOR_RELOJ:
    INCF    MINUTOS,F
    CLRF    SEGUNDOS
    MOVF   MINUTOS,W
    ANDLW   B'00001111' ;NOS QUEDAMOS CON  EL PRIMER DIGITO
    SUBLW   .10	;SI LLEGA A 10 SE LE SUMAN 6 PARA CORREGIR EL BCD
    BTFSS	 STATUS,2
    RETURN
    
    MOVLW   .6
    ADDWF   MINUTOS,F
    
    ;SE VERIFICA QUE LLEGUE A 60 
    MOVLW B'01100000' ;60 EN BCD
    SUBWF  MINUTOS,W
    BTFSS   STATUS,2 
    RETURN
    
    ; SI SI LLEGO A 60 SE INCREMENTAN LAS HORAS 
    CLRF    MINUTOS
    INCF    HORAS, F
    
    MOVLW B'00100100' ;24 EN BCD
    SUBWF   HORAS,W
    BTFSS  STATUS, 2 ;SI LLEGA A ESTO SE LIMPIA EL VALOR DE HORAS Y TERMINA LA RUTINA
    GOTO CORRECCION_HORA
    
    CLRF    HORAS
    BSF	FLAGS,0 ;ESTE BIT INDICA QUE HAY QUE INCREMENTAR LA FECHA
    
    CORRECCION_HORA
    MOVF   HORAS,W
    ANDLW   B'00001111' ;SE CONSERVA EL PRIMER DIGITO
    SUBLW   .10
    BTFSS   STATUS,2 ;SI DA 0 SE EJECUTA LO SIGUENTE
    RETURN
    
    MOVLW .6
    ADDWF   HORAS,F
    RETURN

EDITAR_HORA:
    ;CUANDO SE ENTRA EN ESTE MODO RB2 REALIZA LA FUNCION DE SELECTOR DE EDICION DE HORA O MINUTO
    ;RB5 DETERMINA CUANDO SE SALE DE ESTE MODO, 
    BTFSC   FLAGS,3
    GOTO SI_YA_SE_ENTRO_ANTES
    ;-----------------SE ENTRA A ESTA PARTE SOLO CUANDO ES LA PRIMERA VEZ --------------------------------------------
    BSF	FLAGS,3 ;PARA QUE NO SE VUELVA A ENTRAR AQUI HASTA QUE SE SALGA DEL MODO EDICION
    MOVF    HORAS,W
    MOVWF   HORA_EDITAR
    
    BSF	T1CON,0 ;SE ACTIVA EL TIMER 1
    
    MOVF    MINUTOS,W
    MOVWF   MINUTO_EDITAR ;SE GUARDAN LOS VALORES EN EL INSTANTE QUE SE ENTRA AL MODO DE EDICION
   
    MOVF    PORTB_ACTUAL,W ; SE ACTUALIZAN ESTOS REGISTROS YA QUE SI NO SE HACE, AL SER LA CONDICION
    MOVWF   PORTB_ANTERIOR ;DE ENTRADA IGUAL QUE LA DE SALIDA, SOLO SE VA A EJECUTAR 1 VEZ
    CALL DELAY_US ;SE ESPERA UN MOMENTO
    ;CALL DELAY_US ;SE ESPERA UN MOMENTO
    MOVF    PORTB,W
    MOVWF   PORTB_ACTUAL
    ;-----------------------------------------------------------------------------------------------------------------------------------
    SI_YA_SE_ENTRO_ANTES
    ;-------------------- SE EVITA EL PARPADEO DE LOS LEDS DEL CENTRO ----------------------------------------
    BSF	PORTE,2
    ;-------------------------------------------------------------------------------------------------------------------------------
    ;SE HACE EL CAMBIO ENTRE 0 O 1 PARA EL VALOR A EDITAR (SE VERIFICA QUE HAYA OCURRIDO FLANCO DE SUBIDA)
    BTFSC PORTB_ANTERIOR,2 ;RB2 
    GOTO    CAMBIAR
    
    BTFSS   PORTB_ACTUAL,2 
    GOTO CAMBIAR
    ;---------SE HACE EL CAMBIO DEL VALOR A EDITAR -----------------
    BTFSS   FLAGS,2 ;SE VE SI ESTA EN 1
    GOTO CAMBIAR_0
    
    BCF	FLAGS,2 ;SE  LIMPIA SI ESTA EN 1
    GOTO    CAMBIAR
    CAMBIAR_0  ;SI NO ESTA EN 1 ESTA EN CERO ENTONCES 
    BSF	FLAGS,2 
    ;-------------------------------------------------------------------------------------------
    CAMBIAR
    BTFSC   FLAGS,2 ; SE VE SI LA EDICION ESTA EN HORAS(1) O MINUTOS(0)
    GOTO EDIT_HOUR
    
    
    EDIT_MINUTE
    ;---------SE VERIFICA SI SE DEBE DECREMENTAR--------------------------------------
    DECREMENTAR_MINUTE
    BTFSC   PORTB_ANTERIOR,0
    GOTO    INCREMENTAR_MINUTE
    
    BTFSS   PORTB_ACTUAL,0
    GOTO INCREMENTAR_MINUTE
    ;--------SI HUBO UN FLANCO DE SUBIDA SE EN RB0 SE EJECUTA ESTO  DECREMENTAR ---------------
    DECF    MINUTO_EDITAR,F
    ;--- CORRECCION DEL BCD ----------
    ;PRIMERO SE VERIFICA SI SE PASO DE 00 A 59
    MOVLW .255 ;ESTE VALOR HABRIA SI SE LE RESTA 1 A 0X00H 
    SUBWF   MINUTO_EDITAR,W
    BTFSS   STATUS,2 ;SI ES 1 SE SALTA EL GOTO
    GOTO    CORREGIR_BCD_MINUTO_EDITAR
    
    MOVLW   B'01011001' ;59 EN BCD
    MOVWF   MINUTO_EDITAR
    
    CORREGIR_BCD_MINUTO_EDITAR
    MOVLW   B'00001111' 
    ANDWF   MINUTO_EDITAR,W;SE CONSERVA EL PRIMER DIGITO
    SUBLW   .15 ;ESTE VALOR DARIA SI PASA DE 0 A 9 
    BTFSS   STATUS,2 ;SI DA 1 SE SALTA LA INSTRUCCION (SE CORRIGE EL BCD)
    GOTO INCREMENTAR_MINUTE
    
    MOVLW   .6 
    SUBWF   MINUTO_EDITAR,F ;SE COLOCA  EN 9 COMO DEBERIA DE SER
    
    INCREMENTAR_MINUTE
    ;---------------------- SE VERIFICA SI SE DEBE INCREMENTAR -------------------------
    BTFSC   PORTB_ANTERIOR,1  ;SI EL ANTERIOR ERA 0 SE VERIFICA QUE EL SIGUIENTE SEA 1
    GOTO    SALIR
    
    BTFSS   PORTB_ACTUAL,1
    GOTO    SALIR
    
    ;----------- SI SE LLEGA HASTA AQUI ES QUE SE DEBIA INCREMENTAR ----------------------
    INCF    MINUTO_EDITAR,F
    
    ;----------------CORRECION DE BCD CUANDO SE PASA DE X9 A (X+1)0
    MOVLW   B'00001111' ;SE CONSERVA EL PRIMER DIGITO
    ANDWF   MINUTO_EDITAR,W
    SUBLW .10 ;SI DA 0 SE DEBE SUMAR LAS DECENAS
    BTFSS   STATUS,2 ;SI DA 0 SE SALTA ESTA INSTRUCCION
    GOTO VERIFICAR_OVERFLOW_MINUTO_EDITAR
    
    MOVLW   .6
    ADDWF   MINUTO_EDITAR,F ;SE ARREGLA EL BCD
    ;-----------------VERIFICAR SI SE PASA DE 59 A 00
    VERIFICAR_OVERFLOW_MINUTO_EDITAR
    MOVLW B'01011001' ;60 EN BCD
    SUBWF   MINUTO_EDITAR,W
    BTFSC   STATUS,2 ;SI DA 0 SE REINICIA
    CLRF    MINUTO_EDITAR
    
    GOTO SALIR 
    
    EDIT_HOUR
    ;SI HUBO UN FLANCO DE SUBIDA EN RB0 SE DECREMENTA EN 1 LAS HORAS
    ;------SE VERIFICA SI SE DEBE DECREMENTAR------------------
    BTFSC   PORTB_ANTERIOR,0 ;SE MIRA SI HUBO UN CAMBIO DE 0 A 1 (FLANCO DE SUBIDA
    GOTO    INCREMENTAR_HOUR
    
    BTFSS   PORTB_ACTUAL,0
    GOTO INCREMENTAR_HOUR
    ;--------SI HUBO UN FLANCO DE SUBIDA SE EN RB0 SE EJECUTA ESTO ---------------
    DECF    HORA_EDITAR,F
    ;--- CORRECCION DEL BCD ----------
    ;PRIMERO SE VERIFICA SI SE PASO DE 00 A 24
    MOVLW .255 ;ESTE VALOR HABRIA SI SE LE RESTA 1 A 0X00H 
    SUBWF   HORA_EDITAR,W
    BTFSS   STATUS,2 ;SI ES 1 SE SALTA EL GOTO
    GOTO    CORREGIR_BCD_HORA_EDITAR
    
    MOVLW   B'00100011' ;23 EN BCD
    MOVWF   HORA_EDITAR
    
    CORREGIR_BCD_HORA_EDITAR
    MOVLW   B'00001111' 
    ANDWF   HORA_EDITAR,W;SE CONSERVA EL PRIMER DIGITO
    SUBLW   .15 ;ESTE VALOR DARIA SI PASA DE 0 A 9 
    BTFSS   STATUS,2 ;SI DA 1 SE SALTA LA INSTRUCCION
    GOTO INCREMENTAR_HOUR
    
    MOVLW   .6 
    SUBWF   HORA_EDITAR,F ;SE COLOCA  EN 9 COMO DEBERIA DE SER
    
    INCREMENTAR_HOUR
    ;---------------SE VERIFICA SI SE DEBE INCREMENTAR-----------------------------------------------
    BTFSC   PORTB_ANTERIOR,1
    GOTO    SALIR
    
    BTFSS   PORTB_ACTUAL,1
    GOTO    SALIR
    
    ;----------- SI SE LLEGA HASTA AQUI ES QUE SE DEBIA INCREMENTAR ----------------------
    INCF    HORA_EDITAR,F
    
    ;----------------CORRECION DE BCD CUANDO SE PASA DE X9 A (X+1)0
    MOVLW   B'00001111' ;SE CONSERVA EL PRIMER DIGITO
    ANDWF   HORA_EDITAR,W
    SUBLW .10 ;SI DA 0 SE DEBE SUMAR LAS DECENAS
    BTFSS   STATUS,2 ;SI DA 0 SE SALTA ESTA INSTRUCCION
    GOTO VERIFICAR_OVERFLOW_HORA_EDITAR
    
    MOVLW   .6
    ADDWF  HORA_EDITAR,F ;SE ARREGLA EL BCD
    ;-----------------VERIFICAR SI SE PASA DE 23 A 00
    VERIFICAR_OVERFLOW_HORA_EDITAR
    MOVLW B'00100100' ;24 EN BCD
    SUBWF   HORA_EDITAR,W
    BTFSC   STATUS,2 ;SI DA 0 SE REINICIA
    CLRF    HORA_EDITAR
    ;------- LUEGO DE TODO SE LLEGA A ESTE PUNTO --------------------------------------------------
    SALIR 
    ;------- SE VERIFICA QUE SI SE HA SALIDO SOLO PULSANDO EL BOTON (SALIDA SIN GUARDAR DATOS)--------
    BTFSC   PORTB_ANTERIOR,5
    RETURN
    
    BTFSS   PORTB_ACTUAL,5
    RETURN
    
  
    ;-------------- SI HUBO FLANCO DE SUBIDA SE LLEGA A ESTE PUNTO -----------------------------------
    BCF FLAGS,3 ;SE DESHABILITA EL BIT DE VERIFICACION DE PRIMERA VEZ ENTRANDO A EDITAR HORA
    BCF FLAGS,2 ;SE COLOCA EN EDITAR MINUTO/DIA 
    BCF FLAGS,1 ;SE DESHABILITA EL MODO DE EDICION
    
   MOVLW   VALOR_TMR1H
   MOVWF   TMR1H
   MOVLW   VALOR_TMR1L
    MOVWF   TMR1L
    
    MOVLW   VALOR_TMR1
    MOVWF   CONTADOR_TMR1
    BCF	T1CON,0 ;SE APAGA EL TMR1
    
    RETURN ; PARA MI YO DE MA�ANA, ESTO NO ESTA TERMINADO, POR SI SE TE OLVIDA TIENES QEU USAR
    ;EL TMR1 COMO CONTADOR DE TIEMPO EN 0 PARA RB5 Y SI SE PRESIONA POR 1.5 SALIR CON LOS DATOS GUARDADOS
    ; Y SI NO SALIR SIN GUARDAR NADA
    
EDITAR_FECHA:
        ;CUANDO SE ENTRA EN ESTE MODO RB2 REALIZA LA FUNCION DE SELECTOR DE EDICION DE HORA O MINUTO
    ;RB5 DETERMINA CUANDO SE SALE DE ESTE MODO, 
    BTFSC   FLAGS,3
    GOTO SI_YA_SE_ENTRO_ANTES_FECHA
    ;-----------------SE ENTRA A ESTA PARTE SOLO CUANDO ES LA PRIMERA VEZ --------------------------------------------
    BSF	FLAGS,3 ;PARA QUE NO SE VUELVA A ENTRAR AQUI HASTA QUE SE SALGA DEL MODO EDICION
    MOVF    DIA,W
    MOVWF   DIA_EDITAR
    
    BSF	T1CON,0 ;SE ACTIVA EL TIMER 1
    
    MOVF    MES_BCD,W
    MOVWF   MES_BCD_EDITAR ;SE GUARDAN LOS VALORES EN EL INSTANTE QUE SE ENTRA AL MODO DE EDICION
   
    MOVF    MES_BIN,W
    MOVWF   MES_BIN_EDITAR
    MOVF    PORTB_ACTUAL,W ; SE ACTUALIZAN ESTOS REGISTROS YA QUE SI NO SE HACE, AL SER LA CONDICION
    MOVWF   PORTB_ANTERIOR ;DE ENTRADA IGUAL QUE LA DE SALIDA, SOLO SE VA A EJECUTAR 1 VEZ
    CALL DELAY_US ;SE ESPERA UN MOMENTO
    ;CALL DELAY_US ;SE ESPERA UN MOMENTO
    MOVF    PORTB,W
    MOVWF   PORTB_ACTUAL
    ;
    
    ;SE VERIFICA SI ES EL MINUTO O LA HORA QUE SE VA A EDITAR
    ;-----------------------------------------------------------------------------------------------------------------------------------
    SI_YA_SE_ENTRO_ANTES_FECHA
    ;-------------------- SE EVITA EL PARPADEO DE LOS LEDS DEL CENTRO ----------------------------------------
    BSF	PORTE,2
    ;-------------------------------------------------------------------------------------------------------------------------------
    ;SE HACE EL CAMBIO ENTRE 0 O 1 PARA EL VALOR A EDITAR (SE VERIFICA QUE HAYA OCURRIDO FLANCO DE SUBIDA)
    BTFSC PORTB_ANTERIOR,2 ;RB2 
    GOTO    CAMBIAR_FECHA
    
    BTFSS   PORTB_ACTUAL,2 
    GOTO CAMBIAR_FECHA
    ;---------SE HACE EL CAMBIO DEL VALOR A EDITAR -----------------
    BTFSS   FLAGS,2 ;SE VE SI ESTA EN 1
    GOTO CAMBIAR_1
    
    BCF	FLAGS,2 ;SE  LIMPIA SI ESTA EN 1
    GOTO    CAMBIAR_FECHA
    CAMBIAR_1  ;SI NO ESTA EN 1 ESTA EN CERO ENTONCES 
    BSF	FLAGS,2 
    ;-------------------------------------------------------------------------------------------
    CAMBIAR_FECHA
    CALL TABLA_MESES ;SE GUARDA PARA SABER EL NUMERO MAXIMO DE DIAS EN EL MES SELECCIONADO
    MOVWF DIA_MAX ;SE GUARDA EN DIA MAX
    BTFSS   FLAGS,2 ;SE MIRA SI LO QUE SE DESEA EDITAR ES EL DIA O EL MES
    GOTO EDIT_DAY
    GOTO EDIT_MONTH
    
    EDIT_DAY
    ;----------------------------------- DISMINUIR --------------------------------------------------------------
    DECREMENTAR_DAY
   ; --------------------------------SE COMPRUEBA QUE HAYA UN FLANCO DE SUBIDA EN RB0 ----------------------
    BTFSC   PORTB_ANTERIOR,0
    GOTO    INCREMENTAR_DAY
    
    BTFSS   PORTB_ACTUAL,0
    GOTO INCREMENTAR_DAY
    ;--------SI HUBO UN FLANCO DE SUBIDA SE EN RB0 SE EJECUTA ESTO  DECREMENTAR ---------------
    DECF    MINUTO_EDITAR,F
    ;--- CORRECCION DEL BCD -----------------
    ;PRIMERO SE VERIFICA SI SE PASO DE 00 A 59
    MOVLW .255 ;ESTE VALOR HABRIA SI SE LE RESTA 1 A 0X00H 
    SUBWF   DIA_EDITAR,W
    BTFSS   STATUS,2 ;SI ES 1 SE SALTA EL GOTO
    GOTO    CORREGIR_BCD_DIA_EDITAR
    
    MOVF   DIA_MAX,W ;EL DIA MAXIMO
    SUBLW   .1 ;SE LE RESTA 1  Y LA CORRECCION SE ENCARGA DE LRESTO
    MOVWF   DIA_EDITAR
    ;--------------------------------------------------
    
    CORREGIR_BCD_DIA_EDITAR
    MOVLW   B'00001111' 
    ANDWF   MINUTO_EDITAR,W;SE CONSERVA EL PRIMER DIGITO
    SUBLW   .15 ;ESTE VALOR DARIA SI PASA DE 0 A 9 
    BTFSS   STATUS,2 ;SI DA 1 SE SALTA LA INSTRUCCION (SE CORRIGE EL BCD)
    GOTO INCREMENTAR_DAY
    
    MOVLW   .6 
    SUBWF   DIA_EDITAR,F ;SE COLOCA  EN 9 COMO DEBERIA DE SER
    ;------------------------------------------------------------------------------------------------------------------------------
    INCREMENTAR_DAY
    ;---------------------- SE VERIFICA SI SE DEBE INCREMENTAR(FLANCO DE SUBIDA EN RB1) -------------------------
    BTFSC   PORTB_ANTERIOR,1  ;SI EL ANTERIOR ERA 0 SE VERIFICA QUE EL SIGUIENTE SEA 1
    GOTO    SALIR_FECHA
    ;SI LA CONDICION 0 ANTES Y 1 DESPUES NO SE DA ENTONCES NO SE EJECUTA LA SECCION QUE LE SIGUE    
    BTFSS   PORTB_ACTUAL,1
    GOTO    SALIR_FECHA
    ;------------------------------ SI SE VERIFICA QUE SE DEBE INCREMENTAR SE EJECUTA ESTO------------------
    INCF    DIA_EDITAR,F 
    
   ;SE CORRIGE EL BCD
    MOVF    DIA_EDITAR,W
    ANDLW   B'00001111' ;CONSERVAR EL PRIMER DIGITO
    SUBLW   .10 
    BTFSS   STATUS,2 ; SE SE LLEGA  A 10 SE CORRIGE
    GOTO    OVERFLOW_DIA
    
    MOVLW   .6
    ADDWF   DIA_EDITAR,F 
    
    OVERFLOW_DIA
    ;SE VERIFICA QUE NO SE HAYA PASADO DEL DIA MAXIMO PERMITIDO
    MOVF    DIA_MAX,W
    SUBWF   DIA_EDITAR,W
    BTFSC STATUS,2 ; Z=1 SI DIA_MAX = DIA_EDITAR    SE LIMPIAN LOS DIAS
    CLRF    DIA_EDITAR
    
    GOTO SALIR_FECHA ;SE SALE DE LA RUTINA
    
    EDIT_MONTH
   ; --------------------------------SE COMPRUEBA QUE HAYA UN FLANCO DE SUBIDA EN RB0 ----------------------
    BTFSC   PORTB_ANTERIOR,0
    GOTO    INCREMENTAR_MONTH
    
    BTFSS   PORTB_ACTUAL,0
    GOTO INCREMENTAR_MONTH
    ;------------------------------------------------------------------------------------------------------------------------------------
    ;--------------------------------- SE DECREMENTA SI SE DETECTA UN FLANCO DE SUBIDA------------------------
    DECF    MES_BCD_EDITAR,F
    DECF    MES_BIN_EDITAR,F
    
    
    ;PRIMERO SE VERIFICA SI SE PASO DE 00 A 12
    MOVLW .255 ;ESTE VALOR HABRIA SI SE LE RESTA 1 A 0X00H 
    SUBWF   MES_BCD_EDITAR,W
    BTFSS   STATUS,2 ;SI ES 1 SE SALTA EL GOTO
    GOTO    CORREGIR_BCD_MES_EDITAR
    
    MOVLW   .12
    MOVWF   MES_BIN_EDITAR
    MOVLW   B'00010010' ; 12 EN BCD
    MOVWF   MES_BCD_EDITAR
    
    CORREGIR_BCD_MES_EDITAR
    ;--------- SE CORRIGE EL BCD -------------------------------------------------------------
    MOVLW .B'00001111'
    ANDWF  MES_BCD_EDITAR,W
    SUBLW   .15
    BTFSS   STATUS,2
    GOTO    INCREMENTAR_MES_EDITAR
    
    MOVLW   .6
    SUBWF   MES_BCD_EDITAR
    ;-------------------------------------------------------------------------------------------------
    INCREMENTAR_MES_EDITAR
      ;---------------------- SE VERIFICA SI SE DEBE INCREMENTAR(FLANCO DE SUBIDA EN RB1) -------------------------
    BTFSC   PORTB_ANTERIOR,1  ;SI EL ANTERIOR ERA 0 SE VERIFICA QUE EL SIGUIENTE SEA 1
    GOTO    SALIR_FECHA
    ;SI LA CONDICION 0 ANTES Y 1 DESPUES NO SE DA ENTONCES NO SE EJECUTA LA SECCION QUE LE SIGUE    
    BTFSS   PORTB_ACTUAL,1
    GOTO    SALIR_FECHA
    ;------------------------------ SI SE VERIFICA QUE SE DEBE INCREMENTAR SE EJECUTA ESTO------------------
    INCF    MES_BCD_EDITAR
    INCF    MES_BIN_EDITAR
    
    ;-------- SE VERIFICA EL PASO DE 12 A 00 ---------------------------
    MOVLW   .13
    SUBWF   MES_BIN_EDITAR
    BTFSS   STATUS,2
    GOTO    CORREGIR_BCD_MES_INCREMENTAR
    
    CLRF MES_BIN_EDITAR
    CLRF MES_BCD_EDITAR
    
    ;------- LUEGO DE TODO SE LLEGA A ESTE PUNTO --------------------------------------------------
    SALIR_FECHA 
    ;------- SE VERIFICA QUE SI SE HA SALIDO SOLO PULSANDO EL BOTON (SALIDA SIN GUARDAR DATOS)--------
    BTFSC   PORTB_ANTERIOR,5
    RETURN
   ; SI NO HAY FLANCO DE SUBIDA SOLO SE SALE DE LA RUTINA PERO LA CONDICION DE EDICION SIEMPRE
   ;ESTA ACTIVA
    BTFSS   PORTB_ACTUAL,5
    RETURN
   
    ;-------------- SI HUBO FLANCO DE SUBIDA SE LLEGA A ESTE PUNTO -----------------------------------
    BCF FLAGS,3 ;SE DESHABILITA EL BIT DE VERIFICACION DE PRIMERA VEZ ENTRANDO A EDITAR HORA
    BCF FLAGS,2 ;SE COLOCA EN EDITAR MINUTO/DIA 
    BCF FLAGS,1 ;SE DESHABILITA EL MODO DE EDICION
    
   MOVLW   VALOR_TMR1H
   MOVWF   TMR1H
   MOVLW   VALOR_TMR1L
    MOVWF   TMR1L
    
    MOVLW   VALOR_TMR1
    MOVWF   CONTADOR_TMR1
    BCF	T1CON,0 ;SE APAGA EL TMR1
    
    RETURN ; PARA MI YO DE MA�ANA, ESTO NO ESTA TERMINADO, POR SI SE TE OLVIDA TIENES QEU USAR
    ;EL TMR1 COMO CONTADOR DE TIEMPO EN 0 PARA RB5 Y SI SE PRESIONA POR 1.5 SALIR CON LOS DATOS GUARDADOS
    ; Y SI NO SALIR SIN GUARDAR NADA
    
    
DELAY_US: ;RETARDO DE 228uS
    MOVLW   .75
    MOVWF   DELAY
    DECFSZ  DELAY, F
    GOTO $-1
    RETURN
    

    END