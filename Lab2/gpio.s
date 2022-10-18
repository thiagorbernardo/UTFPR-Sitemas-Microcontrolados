; gpio.s
; Desenvolvido para a placa EK-TM4C1294XL
; Jhonny e Thiago (baseado no projeto de exemplo do professor)
; LAB02 - Display, Teclado e Interrup��es


; -------------------------------------------------------------------------------
			THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declara��es EQU - Defines
; ========================
; ========================
FLAG_INTERRUPCAO EQU 0x20002048
GPIO_PORTJ_AHB_IS_R		EQU 	0x40060404
GPIO_PORTJ_AHB_IBE_R	EQU 	0x40060408
GPIO_PORTJ_AHB_IEV_R	EQU		0x4006040C
GPIO_PORTJ_AHB_IM_R 	EQU		0x40060410
GPIO_PORTJ_AHB_RIS_R	EQU		0x40060414
GPIO_PORTJ_AHB_ICR_R	EQU 	0x4006041C
NVIC_EN1_R				EQU 	0xE000E104
NVIC_PRI12_R			EQU 	0xE000E430
; Defini��es dos Registradores Gerais
SYSCTL_RCGCGPIO_R	 		EQU		0x400FE608
SYSCTL_PRGPIO_R		 		EQU    	0x400FEA08
; ========================
; Defini��es dos Ports
; PORT A
GPIO_PORTA_AHB_LOCK_R    	EQU    	0x40058520
GPIO_PORTA_AHB_CR_R      	EQU    	0x40058524
GPIO_PORTA_AHB_AMSEL_R   	EQU    	0x40058528
GPIO_PORTA_AHB_PCTL_R    	EQU    	0x4005852C
GPIO_PORTA_AHB_DIR_R     	EQU    	0x40058400
GPIO_PORTA_AHB_AFSEL_R   	EQU    	0x40058420
GPIO_PORTA_AHB_DEN_R     	EQU    	0x4005851C
GPIO_PORTA_AHB_PUR_R     	EQU    	0x40058510
GPIO_PORTA_AHB_DATA_R    	EQU    	0x400583FC
GPIO_PORTA               	EQU    	0x00000001

; PORT J
GPIO_PORTJ_AHB_LOCK_R    	EQU    	0x40060520
GPIO_PORTJ_AHB_CR_R      	EQU    	0x40060524
GPIO_PORTJ_AHB_AMSEL_R   	EQU    	0x40060528
GPIO_PORTJ_AHB_PCTL_R    	EQU    	0x4006052C
GPIO_PORTJ_AHB_DIR_R     	EQU    	0x40060400
GPIO_PORTJ_AHB_AFSEL_R   	EQU    	0x40060420
GPIO_PORTJ_AHB_DEN_R     	EQU    	0x4006051C
GPIO_PORTJ_AHB_PUR_R     	EQU    	0x40060510
GPIO_PORTJ_AHB_DATA_R    	EQU    	0x400603FC
GPIO_PORTJ               	EQU    	0x00000100

; PORT K
GPIO_PORTK_LOCK_R    		EQU    	0x40061520
GPIO_PORTK_CR_R      		EQU    	0x40061524
GPIO_PORTK_AMSEL_R   		EQU    	0x40061528
GPIO_PORTK_PCTL_R    		EQU    	0x4006152C
GPIO_PORTK_DIR_R     		EQU    	0x40061400
GPIO_PORTK_AFSEL_R   		EQU    	0x40061420
GPIO_PORTK_DEN_R     		EQU    	0x4006151C
GPIO_PORTK_PUR_R     		EQU    	0x40061510
GPIO_PORTK_DATA_R    		EQU    	0x400613FC
GPIO_PORTK               	EQU    	0x00000200

; PORT L
GPIO_PORTL_LOCK_R    		EQU    	0x40062520
GPIO_PORTL_CR_R      		EQU    	0x40062524
GPIO_PORTL_AMSEL_R   		EQU    	0x40062528
GPIO_PORTL_PCTL_R    		EQU    	0x4006252C
GPIO_PORTL_DIR_R     		EQU    	0x40062400
GPIO_PORTL_AFSEL_R   		EQU    	0x40062420
GPIO_PORTL_DEN_R     		EQU    	0x4006251C
GPIO_PORTL_PUR_R     		EQU    	0x40062510
GPIO_PORTL_DATA_R    		EQU    	0x400623FC
GPIO_PORTL               	EQU    	0x00000400

; PORT M
GPIO_PORTM_LOCK_R    		EQU    	0x40063520
GPIO_PORTM_CR_R      		EQU    	0x40063524
GPIO_PORTM_AMSEL_R   		EQU    	0x40063528
GPIO_PORTM_PCTL_R    		EQU    	0x4006352C
GPIO_PORTM_DIR_R     		EQU    	0x40063400
GPIO_PORTM_AFSEL_R   		EQU    	0x40063420
GPIO_PORTM_DEN_R     		EQU    	0x4006351C
GPIO_PORTM_PUR_R     		EQU    	0x40063510
GPIO_PORTM_DATA_R    		EQU    	0x400633FC
GPIO_PORTM               	EQU    	0x00000800

; PORT P
GPIO_PORTP_LOCK_R    		EQU    	0x40065520
GPIO_PORTP_CR_R      		EQU    	0x40065524
GPIO_PORTP_AMSEL_R   		EQU    	0x40065528
GPIO_PORTP_PCTL_R    		EQU    	0x4006552C
GPIO_PORTP_DIR_R     		EQU    	0x40065400
GPIO_PORTP_AFSEL_R   		EQU    	0x40065420
GPIO_PORTP_DEN_R     		EQU    	0x4006551C
GPIO_PORTP_PUR_R     		EQU    	0x40065510
GPIO_PORTP_DATA_R    		EQU    	0x400653FC
GPIO_PORTP               	EQU    	0x00002000

; PORT Q
GPIO_PORTQ_LOCK_R    		EQU    	0x40066520
GPIO_PORTQ_CR_R      		EQU    	0x40066524
GPIO_PORTQ_AMSEL_R   		EQU    	0x40066528
GPIO_PORTQ_PCTL_R    		EQU    	0x4006652C
GPIO_PORTQ_DIR_R     		EQU    	0x40066400
GPIO_PORTQ_AFSEL_R   		EQU    	0x40066420
GPIO_PORTQ_DEN_R     		EQU    	0x4006651C
GPIO_PORTQ_PUR_R     		EQU    	0x40066510
GPIO_PORTQ_DATA_R    		EQU    	0x400663FC
GPIO_PORTQ               	EQU    	0x00004000

; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir sera armazenado na memoria de 
;                  c�digo
			AREA    |.text|, CODE, READONLY, ALIGN=2
	
			EXPORT InicializaGPIO
			EXPORT PortA_Output
			EXPORT PortQ_Output
			EXPORT PortP_Output
			EXPORT PortK_Output
			EXPORT PortM_Output_LCD_Controle
			EXPORT Ativa_Coluna
			EXPORT Desativa_Colunas
			EXPORT Port_L_Input
			EXPORT Int_Init
			EXPORT GPIOPortJ_Handler

;--------------------------------------------------------------------------------
; Funcao InicializaGPIO
; Parametro de entrada: Nao tem
; Parametro de saida: Nao tem
InicializaGPIO
;=====================
; ****************************************
; Inicializa os bits
; ****************************************

; 1. Ativa o clock para a porta setando o bit correspondente no registrador RCGCGPIO,
; e ap�s isso verifica no PRGPIO se a porta esta pronta para uso.
	LDR   R0, =SYSCTL_RCGCGPIO_R			;Carrega o endereco do registrador RCGCGPIO
	MOV   R1, #GPIO_PORTA					;Seta o bit da porta A
	ORR   R1, #GPIO_PORTJ					;Seta o bit da porta J
	ORR   R1, #GPIO_PORTK					;Seta o bit da porta K
	ORR   R1, #GPIO_PORTL					;Seta o bit da porta L
	ORR   R1, #GPIO_PORTM					;Seta o bit da porta M
	ORR   R1, #GPIO_PORTP					;Seta o bit da porta P
	ORR   R1, #GPIO_PORTQ					;Seta o bit da porta Q
	STR   R1, [R0]							;Move para a memoria os bits das portas no endereco do RCGCGPIO

	LDR   R0, =SYSCTL_PRGPIO_R				;Carrega o endereco do PRGPIO para esperar os GPIO ficarem prontos
EsperaGPIO  LDR   R2, [R0]							;le da memoria o conte�do do endereco do registrador
	TST   R1, R2							;ANDS de R1 com R2
	BEQ   EsperaGPIO						;Se o flag Z=1, volta para o la�o. SeNao continua executando
	
; 2. Limpa o AMSEL
	MOV   R1, #0x00
	LDR   R0, =GPIO_PORTA_AHB_AMSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTK_AMSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTL_AMSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTM_AMSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTP_AMSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTQ_AMSEL_R
	STR   R1, [R0]

; 3. Limpa PCTL
	MOV   R1, #0x00
	LDR   R0, =GPIO_PORTA_AHB_PCTL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTK_PCTL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTL_PCTL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTM_PCTL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTP_PCTL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTQ_PCTL_R
	STR   R1, [R0]

; 4. DIR para 0 se for entrada, 1 se for saida
	LDR   R0, =GPIO_PORTA_AHB_DIR_R
	MOV   R1, #0xF0						; pinos 4 a 7 do port A serao saidas
	STR   R1, [R0]

	LDR   R0, =GPIO_PORTK_DIR_R
	MOV   R1, #0xFF						; 8 pinos do port K serao saida
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTL_DIR_R
	MOV   R1, #0x00						; pinos 3 a 0 do port L serao entradas
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTM_DIR_R
	MOV   R1, #0x07						; pinos 0 a 2 do port M serao saidas
										; pinos 7 a 4 comecam em alto
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTP_DIR_R
	MOV   R1, #0x20						; pino 5 do port P sera saida
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTQ_DIR_R
	MOV   R1, #0x0F						; pinos 0 a 3 do port Q serao saidas
	STR   R1, [R0]

; 5. Limpa os bits AFSEL
	MOV   R1, #0x00
	LDR   R0, =GPIO_PORTA_AHB_AFSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTK_AFSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTL_AFSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTM_AFSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTP_AFSEL_R
	STR   R1, [R0]
	LDR   R0, =GPIO_PORTQ_AFSEL_R
	STR   R1, [R0]
	
; 6. Seta os bits de DEN para habilitar I/O digital
	LDR   R0, =GPIO_PORTA_AHB_DEN_R
	MOV   R1, #0xF0						; ativa pinos 4 a 7 do port A
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTJ_AHB_DEN_R
	MOV   R1, #0x01						; ativa pino 0 do port J
	STR   R1, [R0]

	LDR   R0, =GPIO_PORTK_DEN_R
	MOV   R1, #0xFF						; ativa 8 pinos do port K
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTL_DEN_R
	MOV   R1, #0x0F						; ativa pinos 0 a 3 do port L
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTM_DEN_R
	MOV   R1, #0xF7						; ativa pinos 0 a 2 e 4 a 7 do port M
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTP_DEN_R
	MOV   R1, #0x20						; ativa pino 5 do port P
	STR   R1, [R0]
	
	LDR   R0, =GPIO_PORTQ_DEN_R
	MOV   R1, #0x0F						; ativa pinos 0 a 3 do port Q
	STR   R1, [R0]

; 7. Habilitar resistor de pull-up interno
	LDR   R0, =GPIO_PORTJ_AHB_PUR_R
	MOV   R1, #0x01						; pino 0 do port J tem o USR_SW1
	STR   R1, [R0]

	LDR   R0, =GPIO_PORTL_PUR_R
	MOV   R1, #0x0F						; pinos 0 a 3 do port L tem pull-up ativado
	STR   R1, [R0]
	
;retorno
	BX    LR


; -------------------------------------------------------------------------------
; Funcao PortA_Output
; Parametro de entrada: R8 -> valores a serem escritos nos pinos 7 a 4
; Parametro de saida: Nao tem
; Modifica: R10, R11 e R12
; Escreve nos bits 7 a 4 do registrador DATA do PortA os bits 7 a 4 do R8
PortA_Output
	LDR   R10, =GPIO_PORTA_AHB_DATA_R
	; ignora outros bits de R8
	AND   R11, R8, #0xF0
	
	; le, zera os bits determinados, faz o OR com R11, e escreve de volta
	LDR   R12, [R10]
	BIC   R12, #0xF0
	ORR   R12, R11
	STR   R12, [R10]
	BX    LR
	
; -------------------------------------------------------------------------------
; Funcao PortQ_Output
; Parametro de entrada: R8 -> valores a serem escritos nos pinos 3 a 0
; Parametro de saida: Nao tem
; Modifica: R10, R11 e R12
; Escreve nos bits 3 a 0 do registrador DATA do PortQ os bits 3 a 0 do R8
PortQ_Output
	LDR   R10, =GPIO_PORTQ_DATA_R
	; ignora outros bits de R8
	AND   R11, R8, #0x0F
	
	; le, zera os bits determinados, faz o OR com R11, e escreve de volta
	LDR   R12, [R10]
	BIC   R12, #0x0F
	ORR   R12, R11
	STR   R12, [R10]
	BX    LR

; -------------------------------------------------------------------------------
; Funcao PortP_Output
; Parametro de entrada: R9 -> valor a ser escrito no pino 5
; Parametro de saida: Nao tem
; Modifica: R10, R11 e R12
; Escreve no bit 5 do registrador DATA do PortP o bit 5 do R9
PortP_Output
	LDR   R10, =GPIO_PORTP_DATA_R
	; ignora outros bits de R9
	AND   R11, R9, #0x20
	
	; le, zera os bits determinados, faz o OR com R11, e escreve de volta
	LDR   R12, [R10]
	BIC   R12, #0x20
	ORR   R12, R11
	STR   R12, [R10]
	BX    LR

; -------------------------------------------------------------------------------
; Funcao PortK_Output
; Parametro de entrada: R8 -> valores a serem escritos nos pinos 0 a 7
; Parametro de saida: Nao tem
; Modifica: R10, R11 e R12
; Escreve nos bits 0 a 7 do registrador DATA do PortK os bits 0 a 7 do R8
PortK_Output
	LDR   R10, =GPIO_PORTK_DATA_R
	; ignora outros bits de R8
	AND   R11, R8, #0xFF
	
	; le, zera os bits determinados, faz o OR com R11, e escreve de volta
	LDR   R12, [R10]
	BIC   R12, #0xFF
	ORR   R12, R11
	STR   R12, [R10]
	BX    LR
	
; -------------------------------------------------------------------------------
; Funcao PortM_Output_LCD_Controle
; Parametro de entrada: R9 -> valores a serem escritos nos pinos 2 a 0
; Parametro de saida: Nao tem
; Modifica: R10, R11 e R12
; Escreve nos bits 2 a 0 do registrador DATA do PortM os bits 2 a 0 do R9
PortM_Output_LCD_Controle
	LDR   R10, =GPIO_PORTM_DATA_R
	; ignora outros bits de R9
	AND   R11, R9, #0x07
	
	; le, zera os bits determinados, faz o OR com R11, e escreve de volta
	LDR   R12, [R10]
	BIC   R12, #0x07
	ORR   R12, R11
	STR   R12, [R10]
	BX    LR

; -------------------------------------------------------------------------------
; Funcao Ativa_Coluna
; Parametro de entrada: R8 -> coluna a ser ativada no teclado (0 a 3)
; Parametro de saida: Nao tem
; Modifica: R10, R11 e R12
; Configura como saida e escreve 0 na coluna selecionada por R8
Ativa_Coluna
	LDR   R10, =GPIO_PORTM_DIR_R

	; faz R11 de 0 a 3, soma 4 para ficar entre 4 e 7
	AND   R11, R8, #0x03
	ADD   R11, #4
	
	; faz R12 ter como unico bit em 1 o bit de numero R11
	MOV   R12, #1
	LSL   R12, R11
	
	; ativa essa coluna enquanto desativa outras que podem estar ativas
	LDR   R11, [R10]
	BIC   R11, #0xF0
	ORR   R11, R12
	STR   R11, [R10]
	
	; escreve 0 nessa coluna
	LDR   R10, =GPIO_PORTM_DATA_R
	LDR   R11, [R10]
	BIC   R11, R12
	STR   R11, [R10]

	BX    LR

; -------------------------------------------------------------------------------
; Funcao Desativa_Colunas
; Parametro de entrada: Nao tem
; Parametro de saida: Nao tem
; Modifica: R10, R11
; Configura como entrada todas as colunas do teclado
Desativa_Colunas
	LDR   R10, =GPIO_PORTM_DIR_R
	LDR   R11, [R10]
	BIC   R11, #0xF0
	STR   R11, [R10]

	BX    LR
	
; -------------------------------------------------------------------------------
; Funcao Port_L_Input
; Parametro de entrada: Nao tem
; Parametro de saida: R9
; Modifica: R10
Port_L_Input
; *******************************************************************************
; le o conte�do dos bits de 3 a 0 do PortL em R9
; *******************************************************************************
	LDR   R10, =GPIO_PORTL_DATA_R
	LDR   R9, [R10]
	AND   R9, #0x0F
	BX    LR
; Inicializacao da interrupcao
Int_Init
	LDR R0, =GPIO_PORTJ_AHB_IM_R
	MOV R1, #0x00
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTJ_AHB_IS_R
	MOV R1, #0x00
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTJ_AHB_IBE_R
	MOV R1, #0x00
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTJ_AHB_IEV_R
	MOV R1, #0x00
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTJ_AHB_ICR_R
	MOV R1, #0x01
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTJ_AHB_IM_R
	MOV R1, #0x01
	STR R1, [R0]
	
	LDR R0, =NVIC_EN1_R
	MOV R1, #0x80000
	STR R1, [R0]
	
	LDR R0, =NVIC_PRI12_R
	MOV R1, #5
	LSL R1, #29
	STR R1, [R0]

	BX LR

GPIOPortJ_Handler
	LDR R0, =FLAG_INTERRUPCAO
	MOV R1, #1
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTJ_AHB_ICR_R
	MOV R1, #0x01
	STR R1, [R0]
	BX LR

	ALIGN                           ; garante que o fim da secao esta alinhada 
	END                             ; fim do arquivo