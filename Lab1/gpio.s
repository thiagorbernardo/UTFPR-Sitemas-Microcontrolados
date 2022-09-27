; gpio.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 24/08/2020

; -------------------------------------------------------------------------------
        THUMB                        ; Instru??es do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declara??es EQU - Defines
; ========================
; Defini??es de Valores
BIT0	EQU 2_0001
BIT1	EQU 2_0010
; ========================
; Defini??es dos Registradores Gerais
SYSCTL_RCGCGPIO_R	 EQU	0x400FE608
SYSCTL_PRGPIO_R		 EQU    0x400FEA08
; ========================
; Defini??es dos Ports
; PORT J
GPIO_PORTJ_AHB_LOCK_R    	EQU    0x40060520
GPIO_PORTJ_AHB_CR_R      	EQU    0x40060524
GPIO_PORTJ_AHB_AMSEL_R   	EQU    0x40060528
GPIO_PORTJ_AHB_PCTL_R    	EQU    0x4006052C
GPIO_PORTJ_AHB_DIR_R     	EQU    0x40060400
GPIO_PORTJ_AHB_AFSEL_R   	EQU    0x40060420
GPIO_PORTJ_AHB_DEN_R     	EQU    0x4006051C
GPIO_PORTJ_AHB_PUR_R     	EQU    0x40060510	
GPIO_PORTJ_AHB_DATA_R    	EQU    0x400603FC
GPIO_PORTJ_AHB_DATA_BITS_R  EQU    0x40060000
GPIO_PORTJ               	EQU    2_000000100000000
; PORT Q
GPIO_PORTQ_LOCK_R    	EQU    0x40066520
GPIO_PORTQ_CR_R      	EQU    0x40066524
GPIO_PORTQ_AMSEL_R   	EQU    0x40066528
GPIO_PORTQ_PCTL_R    	EQU    0x4006652C
GPIO_PORTQ_DIR_R     	EQU    0x40066400
GPIO_PORTQ_AFSEL_R   	EQU    0x40066420
GPIO_PORTQ_DEN_R     	EQU    0x4006651C
GPIO_PORTQ_PUR_R     	EQU    0x40066510	
GPIO_PORTQ_DATA_R    	EQU    0x400663FC
GPIO_PORTQ_DATA_BITS_R  EQU    0x40066000
GPIO_PORTQ               	EQU    2_100000000000000
; PORT A
GPIO_PORTA_LOCK_R    	EQU    0x40058520
GPIO_PORTA_CR_R      	EQU    0x40058524
GPIO_PORTA_AMSEL_R   	EQU    0x40058528
GPIO_PORTA_PCTL_R    	EQU    0x4005852C
GPIO_PORTA_DIR_R     	EQU    0x40058400
GPIO_PORTA_AFSEL_R   	EQU    0x40058420
GPIO_PORTA_DEN_R     	EQU    0x4005851C
GPIO_PORTA_PUR_R     	EQU    0x40058510	
GPIO_PORTA_DATA_R    	EQU    0x400583FC
GPIO_PORTA_DATA_BITS_R  EQU    0x40058000
GPIO_PORTA               	EQU    2_000000000000001
; PORT B
GPIO_PORTB_LOCK_R    	EQU    0x40059520
GPIO_PORTB_CR_R      	EQU    0x40059524
GPIO_PORTB_AMSEL_R   	EQU    0x40059528
GPIO_PORTB_PCTL_R    	EQU    0x4005952C
GPIO_PORTB_DIR_R     	EQU    0x40059400
GPIO_PORTB_AFSEL_R   	EQU    0x40059420
GPIO_PORTB_DEN_R     	EQU    0x4005951C
GPIO_PORTB_PUR_R     	EQU    0x40059510	
GPIO_PORTB_DATA_R    	EQU    0x400593FC
GPIO_PORTB_DATA_BITS_R  EQU    0x40059000
GPIO_PORTB               	EQU    2_000000000000010
; PORT P
GPIO_PORTP_LOCK_R    	EQU    0x40065520
GPIO_PORTP_CR_R      	EQU    0x40065524
GPIO_PORTP_AMSEL_R   	EQU    0x40065528
GPIO_PORTP_PCTL_R    	EQU    0x4006552C
GPIO_PORTP_DIR_R     	EQU    0x40065400
GPIO_PORTP_AFSEL_R   	EQU    0x40065420
GPIO_PORTP_DEN_R     	EQU    0x4006551C
GPIO_PORTP_PUR_R     	EQU    0x40065510	
GPIO_PORTP_DATA_R    	EQU    0x400653FC
GPIO_PORTP_DATA_BITS_R  EQU    0x40065000
GPIO_PORTP               	EQU    2_010000000000000

; -------------------------------------------------------------------------------
; ?rea de C?digo - Tudo abaixo da diretiva a seguir ser? armazenado na mem?ria de 
;                  c?digo
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma Fun��o do arquivo for chamada em outro arquivo	
        EXPORT GPIO_Init            ; Permite chamar GPIO_Init de outro arquivo
        EXPORT Display_show			; Permite chamar Display_show de outro arquivo
        EXPORT liga_LED
        EXPORT PortB_Output
		EXPORT PortJ_Input          ; Permite chamar PortJ_Input de outro arquivo
		EXPORT PortP_Output
									

;--------------------------------------------------------------------------------
; Fun��o GPIO_Init
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: N�o tem
GPIO_Init
;=====================
; 1. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO,
; ap?s isso verificar no PRGPIO se a porta est� pronta para uso.
; enable clock to GPIOF at clock gating register
            LDR     R0, =SYSCTL_RCGCGPIO_R  		;Carrega o endere?o do registrador RCGCGPIO
			MOV		R1, #GPIO_PORTQ                 ;Seta o bit da porta Q
			ORR     R1, #GPIO_PORTJ					;Seta o bit da porta J, fazendo com OR
			ORR     R1, #GPIO_PORTB					;Seta o bit da porta B, fazendo com OR
			ORR     R1, #GPIO_PORTA					;Seta o bit da porta A, fazendo com OR
            ORR     R1, #GPIO_PORTP					;Seta o bit da porta P, fazendo com OR
            STR     R1, [R0]						;Move para a mem?ria os bits das portas no endere?o do RCGCGPIO
 
            LDR     R0, =SYSCTL_PRGPIO_R			;Carrega o endere?o do PRGPIO para esperar os GPIO ficarem prontos
EsperaGPIO  LDR     R1, [R0]						;L? da mem?ria o conte?do do endere?o do registrador
			MOV     R2, #GPIO_PORTQ                 ;Seta os bits correspondentes ?s portas para fazer a compara??o
			ORR     R2, #GPIO_PORTJ                 ;Seta o bit da porta J, fazendo com OR
			ORR     R2, #GPIO_PORTA                 ;Seta o bit da porta A, fazendo com OR
			ORR     R2, #GPIO_PORTB                 ;Seta o bit da porta A, fazendo com OR
            ORR     R1, #GPIO_PORTP					;Seta o bit da porta P, fazendo com OR
            TST     R1, R2							;Testa o R1 com R2 fazendo R1 & R2
            BEQ     EsperaGPIO					    ;Se o flag Z=1, volta para o la�o. Sen�o continua executando
 
; 2. Limpar o AMSEL para desabilitar a anal?gica
            MOV     R1, #0x00						;Colocar 0 no registrador para desabilitar a Fun��o anal?gica
            LDR     R0, =GPIO_PORTJ_AHB_AMSEL_R     ;Carrega o R0 com o endere?o do AMSEL para a porta J
            STR     R1, [R0]						;Guarda no registrador AMSEL da porta J da mem?ria
            LDR     R0, =GPIO_PORTQ_AMSEL_R			;Carrega o R0 com o endere?o do AMSEL para a porta N
            STR     R1, [R0]					    ;Guarda no registrador AMSEL da porta N da mem?ria
			LDR     R0, =GPIO_PORTA_AMSEL_R			;Carrega o R0 com o endere?o do AMSEL para a porta A
            STR     R1, [R0]					    ;Guarda no registrador AMSEL da porta A da mem?ria
            LDR     R0, =GPIO_PORTB_AMSEL_R			;Carrega o R0 com o endere?o do AMSEL para a porta A
            STR     R1, [R0]					    ;Guarda no registrador AMSEL da porta A da mem?ria
            LDR     R0, =GPIO_PORTP_AMSEL_R			;Carrega o R0 com o endere?o do AMSEL para a porta A
            STR     R1, [R0]					    ;Guarda no registrador AMSEL da porta A da mem?ria
 
; 3. Limpar PCTL para selecionar o GPIO
            MOV     R1, #0x00					    ;Colocar 0 no registrador para selecionar o modo GPIO
            LDR     R0, =GPIO_PORTJ_AHB_PCTL_R		;Carrega o R0 com o endere?o do PCTL para a porta J
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta J da mem?ria
            LDR     R0, =GPIO_PORTQ_PCTL_R      	;Carrega o R0 com o endere?o do PCTL para a porta N
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta N da mem?ria
			LDR     R0, =GPIO_PORTA_PCTL_R      	;Carrega o R0 com o endere?o do PCTL para a porta A
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta A da mem?ria
            LDR     R0, =GPIO_PORTB_PCTL_R      	;Carrega o R0 com o endere?o do PCTL para a porta A
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta A da mem?ria
            LDR     R0, =GPIO_PORTP_PCTL_R      	;Carrega o R0 com o endere?o do PCTL para a porta A
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta A da mem?ria
; 4. DIR para 0 se for entrada, 1 se for sa�da
            LDR     R0, =GPIO_PORTQ_DIR_R			;Carrega o R0 com o endere?o do DIR para a porta N
			MOV     R1, #2_00001111					;PN1
            STR     R1, [R0]						;Guarda no registrador
			LDR     R0, =GPIO_PORTA_DIR_R			;Carrega o R0 com o endere?o do DIR para a porta A
			MOV     R1, #2_11110000					;PN1
            STR     R1, [R0]						;Guarda no registrador
            LDR     R0, =GPIO_PORTB_DIR_R			;Carrega o R0 com o endere?o do DIR para a porta A
			MOV     R1, #2_00110000					;PN1
            STR     R1, [R0]						;Guarda no registrador
            LDR     R0, =GPIO_PORTP_DIR_R			;Carrega o R0 com o endere?o do DIR para a porta A
			MOV     R1, #2_00100000					;PN1
            STR     R1, [R0]						;Guarda no registrador
			; O certo era verificar os outros bits da PJ para N�o transformar entradas em sa�das desnecess?rias
            LDR     R0, =GPIO_PORTJ_AHB_DIR_R		;Carrega o R0 com o endere?o do DIR para a porta J
            MOV     R1, #0x00               		;Colocar 0 no registrador DIR para funcionar com sa�da
            STR     R1, [R0]						;Guarda no registrador PCTL da porta J da mem?ria
; 5. Limpar os bits AFSEL para 0 para selecionar GPIO 
;    Sem Fun��o alternativa
            MOV     R1, #0x00						;Colocar o valor 0 para N�o setar Fun��o alternativa
            LDR     R0, =GPIO_PORTQ_AFSEL_R			;Carrega o endere?o do AFSEL da porta N
            STR     R1, [R0]						;Escreve na porta
			LDR     R0, =GPIO_PORTA_AFSEL_R			;Carrega o endere?o do AFSEL da porta A
            STR     R1, [R0]						;Escreve na porta
            LDR     R0, =GPIO_PORTB_AFSEL_R			;Carrega o endere?o do AFSEL da porta A
            STR     R1, [R0]						;Escreve na porta
            LDR     R0, =GPIO_PORTP_AFSEL_R			;Carrega o endere?o do AFSEL da porta A
            STR     R1, [R0]						;Escreve na porta
            LDR     R0, =GPIO_PORTJ_AHB_AFSEL_R     ;Carrega o endere?o do AFSEL da porta J
            STR     R1, [R0]                        ;Escreve na porta
; 6. Setar os bits de DEN para habilitar I/O digital
            LDR     R0, =GPIO_PORTQ_DEN_R			    ;Carrega o endere?o do DEN
            MOV     R1, #2_00001111                     ;N1
            STR     R1, [R0]							;Escreve no registrador da mem?ria funcionalidade digital
			
			LDR     R0, =GPIO_PORTA_DEN_R			    ;Carrega o endere?o do DEN
            MOV     R1, #2_11110000                     ;N1
            STR     R1, [R0]							;Escreve no registrador da mem?ria funcionalidade digital 

            LDR     R0, =GPIO_PORTB_DEN_R			    ;Carrega o endere?o do DEN
            MOV     R1, #2_00110000                     ;N1
            STR     R1, [R0]							;Escreve no registrador da mem?ria funcionalidade digital

            LDR     R0, =GPIO_PORTP_DEN_R			    ;Carrega o endere?o do DEN
            MOV     R1, #2_00100000                     ;N1
            STR     R1, [R0]							;Escreve no registrador da mem?ria funcionalidade digital
 
            LDR     R0, =GPIO_PORTJ_AHB_DEN_R			;Carrega o endere?o do DEN
			MOV     R1, #2_00000011                     ;J0     
            STR     R1, [R0]                            ;Escreve no registrador da mem?ria funcionalidade digital
			
; 7. Para habilitar resistor de pull-up interno, setar PUR para 1
			LDR     R0, =GPIO_PORTJ_AHB_PUR_R			;Carrega o endere?o do PUR para a porta J
			MOV     R1, #2_00000011							;Habilitar funcionalidade digital de resistor de pull-up 
            STR     R1, [R0]							;Escreve no registrador da mem?ria do resistor de pull-up
			BX      LR

; -------------------------------------------------------------------------------
; Fun��o Display_show
; Par�metro de entrada: R0 -> AQ
; Par�metro de sa�da: N�o tem
Display_show
    LDR	R2, =GPIO_PORTA_DATA_R
	
	AND R4, R0, #0xF0
	
	LDR R3, [R2]
	BIC R3, #0xF0
	ORR R3, R4
	STR R3, [R2]

    LDR	R2, =GPIO_PORTQ_DATA_R

	AND R4, R0, #0x0F
	
	LDR R3, [R2]
	BIC R3, #0x0F
	ORR R3, R4
	STR R3, [R2]

	BX LR
; -------------------------------------------------------------------------------
; Fun��o PortB_Output
; Par�metro de entrada: R0
; Par�metro de sa�da: N�o tem
PortB_Output
	LDR	R2, =GPIO_PORTB_DATA_R

	AND R4, R0, #0x30
	
	LDR R3, [R2]
	BIC R3, #0x30
	ORR R3, R4
	STR R3, [R2]

	BX LR
; -------------------------------------------------------------------------------
; Fun��o liga_LED
; Par�metro de entrada: R1 -> AQ
; Par�metro de sa�da: N�o tem
liga_LED
	LDR	R2, =GPIO_PORTA_DATA_R
	
	AND R4, R1, #0xF0
	
	LDR R3, [R2]
	BIC R3, #0xF0
	ORR R3, R4
	STR R3, [R2]

    LDR	R2, =GPIO_PORTQ_DATA_R

	AND R4, R1, #0x0F
	
	LDR R3, [R2]
	BIC R3, #0x0F
	ORR R3, R4
	STR R3, [R2]

	BX LR
; -------------------------------------------------------------------------------
; Fun��o PortP_Output
; Par�metro de entrada: R0
; Par�metro de sa�da: N�o tem
PortP_Output
	LDR	R2, =GPIO_PORTP_DATA_R

	AND R4, R0, #0x20
	
	LDR R3, [R2]
	BIC R3, #0x20
	ORR R3, R4
	STR R3, [R2]

	BX LR
; -------------------------------------------------------------------------------
; Fun��o PortJ_Input
; Par�metro de entrada: N�o tem
; Par�metro de sa�da: R0 --> o valor da leitura
PortJ_Input
	LDR	R1, =GPIO_PORTJ_AHB_DATA_R		    ;Carrega o valor do offset do data register
	LDR R0, [R1]                            ;L? no barramento de dados dos pinos [J0]
	AND R0, #0x03
	BX LR									;Retorno


    ALIGN                           ; garante que o fim da se??o est� alinhada 
    END                             ; fim do arquivo