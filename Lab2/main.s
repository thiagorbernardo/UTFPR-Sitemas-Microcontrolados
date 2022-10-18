; -------------------------------------------------------------------------------
			THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
			
; Declara��es EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
; Defini��es de Valores

SENHA_DIGITADA_RAM EQU 0x20002004
SENHA_FINAL_RAM EQU 0x20002026
FLAG_INTERRUPCAO EQU 0x20002048
zero_ascii				EQU		'0'

; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
			AREA	dados, DATA, READWRITE, ALIGN=2
				
digitos					SPACE	16
tabuada					SPACE   10
flag_zera_tudo			SPACE   4

; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir ser� armazenado na mem�ria de c�digo
			AREA	|.text|, CODE, READONLY, ALIGN=2
				
; vetor na mem�ria FLASH:
senha_mestra DCB   9, 9, 9, 9
; texto "Tabuada do ":
texto_tabuada			DCB   'T', 'a', 'b', 'u', 'a', 'd', 'a', ' ', 'd', 'o', ' ', 0

; texto "Aperte uma tecla":
bem_vindo_1				DCB   'A', 'p', 'e', 'r', 't', 'e', ' ', 'u', 'm', 'a', ' ', 't', 'e', 'c', 'l', 'a', 0

; texto "  para come�ar  ":
bem_vindo_2				DCB   ' ', ' ', 'p', 'a', 'r', 'a', ' ', 'c', 'o', 'm', 'e', 0x07, 'a', 'r', ' ', ' ', 0

			EXPORT Start			; Permite chamar a Funcao Start a partir de 
									; outro arquivo. No caso startup.s
			IMPORT PLL_Init
			IMPORT Int_Init
			IMPORT SysTick_Init
			IMPORT SysTick_Wait1ms
			IMPORT SysTick_Wait1us
			
			IMPORT InicializaGPIO
			IMPORT PortA_Output
			IMPORT PortQ_Output
			IMPORT PortP_Output
			IMPORT PortK_Output
			IMPORT PortM_Output_LCD_Controle
			IMPORT Ativa_Coluna
			IMPORT Desativa_Colunas
			IMPORT Port_L_Input
			IMPORT GPIOPortJ_Handler
				
; -------------------------------------------------------------------------------
; Funcao EnviaLCD
; Parametro de entrada: R8 -> valor enviado para o LCD
;                       R9 -> indica se � um dado ou comando (s� o bit 0 � usado)
; Parametro de saida: N�o tem
; Modifica: R0, R10, R11 e R12 (R10, 11 e 12 nas funcoes chamadas por EnviaLCD)
EnviaLCD
	PUSH { LR }
	; R8 j� possui o valor a ser enviado
	BL PortK_Output
	
	;ignora outros bits al�m do bit 0
	AND R9, #0x01
	
	ORR R9, #0x04
	BL PortM_Output_LCD_Controle
	MOV R0, #20
	BL SysTick_Wait1us
	; manda dados e enable por 20us
	
	BIC R9, #0x04
	BL PortM_Output_LCD_Controle
	MOV R0, #2
	BL SysTick_Wait1ms
	; zera enable e espera por 2ms
	
	POP { LR }
	BX LR
	
LCD_Init
	PUSH { LR }
	MOV R8, #0x38
	MOV R9, #0
	BL EnviaLCD
	
	MOV R8, #0x06
	MOV R9, #0
	BL EnviaLCD
	
	MOV R8, #0x0E
	MOV R9, #0
	BL EnviaLCD
	
	MOV R8, #0x01
	MOV R9, #0
	BL EnviaLCD
	
	;;;;;;;;;;;;;
	
	MOV R8, #0x78
	MOV R9, #0
	BL EnviaLCD
	
	MOV R8, #0x00
	MOV R9, #1
	BL EnviaLCD
	MOV R8, #0x00
	MOV R9, #1
	BL EnviaLCD
	MOV R8, #0x0E
	MOV R9, #1
	BL EnviaLCD
	MOV R8, #0x10
	MOV R9, #1
	BL EnviaLCD
	MOV R8, #0x11
	MOV R9, #1
	BL EnviaLCD
	MOV R8, #0x0E
	MOV R9, #1
	BL EnviaLCD
	MOV R8, #0x04
	MOV R9, #1
	BL EnviaLCD
	MOV R8, #0x0C
	MOV R9, #1
	BL EnviaLCD
	
	MOV R8, #0x80
	MOV R9, #0
	BL EnviaLCD
	
	POP { LR }
	BX LR

;
; Funcao main()
Start
	BL PLL_Init							; Altera o clock para 80MHz
	BL SysTick_Init						; Inicializa o SysTick
	BL InicializaGPIO					; Inicializa os GPIO
	BL LCD_Init
	BL Int_Init
main_loop
	; o c�digo vai aqui
	LDR R10,=FLAG_INTERRUPCAO
	MOV R11, #0
	STRB R11,[R10]
	BL setar_senha
	BL decifrar_senha

	B main_loop

; loop para setar a senha digitada
setar_senha
	PUSH { LR }
	MOV R1, #0
loop_setar_senha	
	BL ler_teclado
	CMP R6, #1
	BLEQ salvar_senha_digitada
	CMP R6, #0
	BEQ loop_setar_senha
;			BL LCD
	MOV R4, #2
	BL SysTick_Wait1us ;TODO arrumar o BOUNCE 
	ADD R1, #1
	CMP R1, #4
	BLT loop_setar_senha
	MOV R1, #0
; loop para ignorar todos os digitos que nao seja a # para salvar a senha
loop_espera_hashtag
	BL ler_teclado
	CMP R5,#0x0c ; caso seja #
	BNE loop_espera_hashtag
	BL salvar_senha_final
	POP { LR }
	BX LR

; entrada:
; R1 -> posicao no loop
; R5 -> numero digitado
; salva na memoria (0x20002004) os numeros que o usuario digitou
; pula caso tenha digitado * ou #
salvar_senha_digitada
    CMP R5,#0x0c ; caso seja #
    BEQ nao_digitou_numero
    CMP R5,#0x0a ; caso seja *
    BEQ nao_digitou_numero

	LDR R10,=SENHA_DIGITADA_RAM
    STRB R5,[R10, R1]
    BX LR

nao_digitou_numero
    MOVEQ R6,#0
    BX LR ; volta para o loop_setar_senha

; entrada:
;   R1 -> posicao no loop
; pega todos os digitos do endereco da senha digitada e passa para o endereco da senha final
salvar_senha_final
    LDR R10,=SENHA_DIGITADA_RAM
    LDRB R5,[R10, R1]
    MOV R7,#0xFF
    STRB R7,[R10, R1]
    LDR R10,=SENHA_FINAL_RAM
    STRB R5,[R10, R1]

    ADD R1,#1
    CMP R1,#4
    BLT salvar_senha_final
    MOV R1,#0
    BX LR

; fica guardando a senha digitada e depois compara com a senha mestra, tendo apenas 3 tentativas ate travar
decifrar_senha
	PUSH { LR }
	MOV R1, #0 ;i do loop
	MOV R2, #0 ;numero de tentativas
	MOV R12, #0
loop_decifrar_senha
	BL ler_teclado
	CMP R6, #1
	BLEQ salvar_senha_digitada
	CMP R6, #0
	BEQ loop_decifrar_senha
;			BL LCD
	MOV R4, #2
	BL SysTick_Wait1us ;TODO arrumar o BOUNCE 
	ADD R1, #1
	CMP R1, #4
	BLT loop_decifrar_senha
	MOV R1, #0
	BL verificar_senha
	CMP R12, #1
	BEQ senha_certa
	ADD R2, #1
	CMP R2, #4
	BLT loop_decifrar_senha
	B travar ; trava caso passe o limite

; se a senha certa for digitada volta para main pois o cofre esta aberto 
senha_certa
	;BL LCD 
	POP { LR }
	BX LR

; loop para nao deixar o usuario sair enquanto nao digitar a senha mestra
; fica guardando a senha digitada e depois compara com a senha mestra		
travar
	BL pisca_LED
	LDR R10,=FLAG_INTERRUPCAO
	LDRB R11,[R10]
	CMP R11, #1
	BNE travar
	MOV R12, #0
	BL ler_teclado
	CMP R6, #1
	BLEQ salvar_senha_digitada
	CMP R6, #0
	BEQ travar
;			BL LCD
	MOV R4, #2
	BL SysTick_Wait1us ;TODO arrumar o BOUNCE 
	ADD R1, #1
	CMP R1, #4
	BLT travar
	MOV R1, #0
	BL verificar_senha_mestra
	CMP R12, #0
	BEQ travar
	POP { LR }
	BX LR


; entrada:
; R1 -> posicao no loop
; le a senha digitada e compara com a senha previamente cadastrada no endereco (0x20002026)
verificar_senha
    LDR R10,=SENHA_DIGITADA_RAM
    LDRB R5,[R10, R1]
    LDR R10,=SENHA_FINAL_RAM
    LDRB R6,[R10, R1]
    CMP R5,R6
    MOV R12,#0 ; flag que indica se a senha esta certa ou errada
    BXNE LR
    ADD R1,#1
    CMP R1,#4
    BLT verificar_senha
    MOV R1,#0
    MOV R12,#1
    BX LR

; entrada:
; R1 -> posicao no loop
; le a senha digitada e compara com o vetor de senha mestra registrado
verificar_senha_mestra
    LDR R10,=SENHA_DIGITADA_RAM
    LDRB R5,[R10, R1]
    LDR R10,=senha_mestra
    LDRB R6,[R10, R1]
    CMP R5,R6
    MOV R12,#0 ; flag que indica se a senha esta certa ou errada
    BXNE LR
    ADD R1,#1
    CMP R1,#4
    BLT verificar_senha_mestra ; loop para comparar todos os digitos
    MOV R1,#0
    MOV R12,#1
    BX LR

; Parte de leitura do teclado matricial
ler_teclado
	PUSH { LR }
	MOV R6, #0
	MOV R8, #0
proxima_coluna
	MOV R7, #0x01
	BL Ativa_Coluna
	MOV R0, #1
	BL SysTick_Wait1ms
	BL Port_L_Input
proxima_linha
	TST R9, R7 ; ANDS
	BEQ encontrou
	LSL R7, #1
	CMP R7, #0x10
	BNE proxima_linha
	ADD R8, #1
	CMP R8, #3
	BNE proxima_coluna
	B nao_encontrou
encontrou
	ADD R5, R8, #1
continua
	LSRS R7, #1
	BCS numero_final
	ADD R5, #3
	B continua
numero_final
	; seta R6 pois lemos uma tecla
	MOV R6, #1
nao_encontrou
	BL Desativa_Colunas
	POP { LR }
	BX LR

pisca_LED
	PUSH { LR, R8, R0, R1 }

	MOV R1, #0
	MOV R8, #0xFF
	BL PortA_Output
	BL PortQ_Output
loop_pisca_LED
	MOV R9, #0x20
	BL PortP_Output

	MOV R0,#500
	BL SysTick_Wait1ms
	MOV R9, #0x00
	BL PortP_Output

	MOV R0,#500
	BL SysTick_Wait1ms
	ADD R1, #1
	CMP R1, #5
	BNE loop_pisca_LED

	POP { LR, R8, R0, R1 }
	MOV R3, #0
	MOV R6, #0
	BX LR

	ALIGN                        ; Garante que o fim da se��o est� alinhada 
	END                          ; Fim do arquivo
