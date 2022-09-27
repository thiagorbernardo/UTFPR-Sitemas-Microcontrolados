; main.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 24/08/2020
; Este programa espera o usu�rio apertar a chave USR_SW1.
; Caso o usu�rio pressione a chave, o LED1 piscar� a cada 0,5 segundo.

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declara��es EQU - Defines
;<NOME>         EQU <VALOR>
; ========================

; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
		AREA  DATA, ALIGN=2
		; Se alguma vari�vel for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a vari�vel <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma vari�vel de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posi��o da RAM		

; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir ser� armazenado na mem�ria de 
;                  c�digo
        AREA    |.text|, CODE, READONLY, ALIGN=2
digitos_vector DCB   0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
		
		; Se alguma fun��o do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a fun��o Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma fun��o externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; fun��o <func>
		IMPORT  PLL_Init
		IMPORT  SysTick_Init
		IMPORT  SysTick_Wait1ms
		IMPORT  SysTick_Wait1s
		IMPORT  GPIO_Init
        IMPORT  Display_show
		IMPORT  liga_LED
		IMPORT  PortB_Output
        IMPORT  PortJ_Input	


; -------------------------------------------------------------------------------
; Fun��o main()
Start  		
	BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init
	BL GPIO_Init                 ;Chama a subrotina que inicializa os GPIO

MainLoop
	LDR R12,=digitos_vector
	MOV R10,#0
	MOV R11,#0
	B LOOP

LOOP
	LDR R12,=digitos_vector
	LDRB R0,[R12, R10]
	BL Display_show
	MOV R0,#0x10
	BL PortB_Output
	BL SysTick_Wait1ms
	
	MOV R0,#0
	BL PortB_Output
	BL SysTick_Wait1ms
	
	LDRB R0,[R12, R11]
	BL Display_show
	MOV R0,#0x20
	BL PortB_Output
	BL SysTick_Wait1ms
	
	MOV R0,#0
	BL PortB_Output
	BL SysTick_Wait1s
	
	ADD R11,#1
	CMP R11,#10
	BLT LOOP
	
	SUB R11,#10
	ADD R10,#1
	
	CMP R10,#10
	BLT LOOP
	
	SUB R10,#10
	B LOOP
	
;;LOOP_UNIT
;	LDRB R0,[R12, ]
;	BL Display_show
;	MOV R0,#2_00100000
;	BL PortB_Output
;	ADD R3,#1 ;-> passo
;	CMP R3,#9
;	PUSH {R3}
;	BL SysTick_Wait1s
;	POP {R3}
;;	BGE LOOP_UNIT
;;	B LOOP

;Verifica_Nenhuma
;	CMP	R0, #2_00000011			 ;Verifica se nenhuma chave est� pressionada
;	BNE Verifica_SW1			 ;Se o teste viu que tem pelo menos alguma chave pressionada pula
;	MOV R0, #0                   ;N�o acender nenhum LED
;	BL PortQ_Output			 	 ;Chamar a fun��o para n�o acender nenhum LED
;	B MainLoop					 ;Se o teste viu que nenhuma chave est� pressionada, volta para o la�o principal
;Verifica_SW1	
;	CMP R0, #2_00000010			 ;Verifica se somente a chave SW1 esta pressionada
;	BNE Verifica_SW2             ;Se o teste falhou, pula
;	MOV R0, #2_00010000			 ;Setar o par�metro de entrada da fun��o como o BIT4
;	BL PortQ_Output				 ;Chamar a fun��o para setar o LED3
;	B MainLoop                   ;Volta para o la�o principal
;Verifica_SW2	
;	CMP R0, #2_00000001			 ;Verifica se somente a chave SW2 esta pressionada
;	BNE Verifica_Ambas           ;Se o teste falhou, pula
;	MOV R0, #2_00000001			 ;Setar o par�metro de entrada da fun��o como o BIT0
;	BL PortQ_Output				 ;Chamar a fun��o para setar o LED4
;	B MainLoop                   ;Volta para o la�o principal	
;Verifica_Ambas
;	CMP R0, #2_00000000			 ;Verifica se ambas as chaves estao pressionadas
;	BNE MainLoop          		 ;Se o teste falhou, pula
;	MOV R0, #2_00010001			 ;Setar o par�metro de entrada da fun��o como o BIT0
Liga_Display
	

;--------------------------------------------------------------------------------
; Fun��o Pisca_LED
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
;Pisca_LED
;	MOV R0, #2_10				 ;Setar o par�metro de entrada da fun��o setando o BIT1
;	PUSH {LR}
;	BL PortN_Output				 ;Chamar a fun��o para acender o LED1
;	MOV R0, #500                ;Chamar a rotina para esperar 0,5s
;	BL SysTick_Wait1ms
;	MOV R0, #0					 ;Setar o par�metro de entrada da fun��o apagando o BIT1
;	BL PortN_Output				 ;Chamar a rotina para apagar o LED
;	MOV R0, #500                ;Chamar a rotina para esperar 0,5
;	BL SysTick_Wait1ms	
;	POP {LR}
;	BX LR						 ;return

; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN                        ;Garante que o fim da se��o est� alinhada 
    END                          ;Fim do arquivo
