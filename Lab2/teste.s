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
PASSO_CONTADOR EQU 0x20002004
ORDEM_CONTADOR EQU 0x20002005

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
leds_vector DCB		0x81, 0x42, 0x24, 0x18, 0x18, 0x24, 0x42, 0x81

		
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
		IMPORT  PortP_Output


; -------------------------------------------------------------------------------
; Fun��o main()
Start  		
	BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init
	BL GPIO_Init                 ;Chama a subrotina que inicializa os GPIO
	
	LDR R10,=PASSO_CONTADOR
	LDR R11,=ORDEM_CONTADOR
	MOV R12,#1
	STRB R12,[R11]
	MOV R12,#1
	STRB R12,[R10]
	
	MOV R10,#0 ; Dezenas
	MOV R11,#0 ; Unidade

MainLoop
	LDR R12,=digitos_vector
	LDR R9,=leds_vector
	MOV R7, #0

	B LOOP_CRESCENTE

LIGAR_LEDS
	PUSH {LR}
	LDR R9,=leds_vector
	LDRB R1,[R9, R6]
	BL liga_LED
	
	MOV R0,#0
	BL PortB_Output
	
	MOV R0,#2_00100000
	BL PortP_Output

	MOV R0, #5
	BL SysTick_Wait1ms
	
	ADD R6,#1
	CMP R6,#9
	IT EQ
		MOVEQ R6,#0
	POP {LR}
	BX LR

LOOP_CRESCENTE
	MOV R0,#0
	BL PortP_Output
	
	LDR R12,=digitos_vector
	LDRB R0,[R12, R10]
	BL Display_show
	MOV R0,#0x10
	BL PortB_Output
	MOV R0, #1
	BL SysTick_Wait1ms
	
	LDRB R0,[R12, R11]
	BL Display_show
	MOV R0,#0x20
	BL PortB_Output
	MOV R0, #1
	BL SysTick_Wait1ms
	
	ADD R7, #1
	CMP R7, #100
	BLT LOOP_CRESCENTE
	
	MOV R7, #0
	
	BL LIGAR_LEDS
	BL ALTERA_PASSO
	BL ALTERA_ORDEM
	
	LDR R0,=PASSO_CONTADOR
	LDRB R1,[R0] ; -> R1 = passo
	
	LDR R0,=ORDEM_CONTADOR
	LDRB R2,[R0] ; R2 = ordem 1 ou 0
	CMP R2,#0
	
	ITTEE EQ
		ADDEQ R11,R1
		MOVEQ R8,#10
		SUBNE R11, R1
		MOVNE R8, #-1
	
	CMP R2, #0
	BEQ crescente
	CMP R11,R8
	BGT LOOP_CRESCENTE
	B continua

crescente
	CMP R11,R8
	BLT LOOP_CRESCENTE
	B continua
	
continua
	CMP R2,#0
	ITTEE EQ
		SUBEQ R11,#10
		ADDEQ R10, #1
		ADDNE R11,#10
		SUBNE R10, #1
	
	CMP R10,R8
	BNE LOOP_CRESCENTE
	
	CMP R2,#0
	ITE EQ
		SUBEQ R10,#10
		ADDNE R10,#10
	B MainLoop

ALTERA_PASSO
	PUSH {LR}
	BL PortJ_Input
	

	LDR R1,=PASSO_CONTADOR
	LDRB R2,[R1]

	CMP R0,#2
	BLEQ incrementa_passo
	POP {LR}
	BX LR
	
incrementa_passo
	ADD R2,#1
	CMP R2, #10
	IT EQ
		MOVEQ R2, #1
	STRB R2,[R1]
	BX LR

ALTERA_ORDEM
	PUSH {LR}
	BL PortJ_Input

	LDR R1,=ORDEM_CONTADOR
	LDRB R2,[R1]

	CMP R0,#1
	BLEQ TROCA_ORDEM
	POP {LR}
	BX LR
	
TROCA_ORDEM
	CMP R2, #0
	ITE EQ
		MOVEQ R2, #1
		MOVNE R2, #0
	STRB R2,[R1]
	BX LR
; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN                        ;Garante que o fim da se��o est� alinhada 
    END                          ;Fim do arquivo
