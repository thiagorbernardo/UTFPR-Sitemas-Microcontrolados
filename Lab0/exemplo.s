; Exemplo.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 12/03/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
RAM_POS_LIST EQU 0x20000200
RAM_POS_SORT EQU 0x20000300

ARRAY_SIZE EQU 20

; -------------------------------------------------------------------------------
; Área de Dados - Declarações de variáveis
		AREA  DATA, ALIGN=2
; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de código
        AREA    |.text|, CODE, READONLY, ALIGN=2
input_vector DCB 50, 65, 229, 201, 101, 43, 27, 2, 5, 210, 101, 239, 73, 29, 207, 135, 33, 227, 13, 9, 6
; 229 101 43 2 5 101 239 73 29 227 13
        EXPORT Start

; -------------------------------------------------------------------------------
; Função main()
Start  
; Comece o código aqui <======================================================
	LDR R0,=input_vector ; Array de numeros
	LDR R1,=RAM_POS_LIST ; Posicao atual da ram
	MOV R2,#0 ; i
	
LOOP
	CMP R2,#ARRAY_SIZE
	BLNE LOAD_ARRAY_INPUT
	BLEQ PRIMES
	B LOOP
	
LOAD_ARRAY_INPUT
	LDRB R3,[R0],#1 ; Salva em R3 o que tem no endereco de R0, depois R0 = R0 + 4
	STRB R3,[R1],#1 ; Salva no endereco de R1 o que tem em R3
	ADD R2,#1
	BX LR
	
PRIMES
	LDR R1,=RAM_POS_LIST ; Posicao atual da ram
	LDR R2,=RAM_POS_SORT ; Posicao atual da ram pros primos
	MOV R3,#0 ; i
	MOV R10,#0 ; contador primo
	
	BL LOOP_PRIMES
	BL LOOP_I_BUBBLE_SORT
	B FIM
	
LOOP_PRIMES
    LDRB R0,[R1],#1 ; Pega os numeros do vetor salvos na ram
	MOV R9,#2
    UDIV R7,R0,R9 ; R7=R0/2
    MOV R4,#1 ; R4 comeca em 1 -> j
    CMP R3,#ARRAY_SIZE
    PUSH {LR}
    BLNE FIND_PRIMES
    POP {LR}
    ADD R3,#1
    CMP R3,#ARRAY_SIZE
    BNE LOOP_PRIMES
    BXEQ LR

FIND_PRIMES
    ADD R4, #1 ; R4 vai pra 2
    CMP R4, R7 ; compara R4 com a metade de R0
    BHI SALVAR
    UDIV R5, R0, R4 ; R5 = R0/R4
    MLS R6, R4, R5, R0 ; R6 = R4 -  R0 * R5
    CMP R6, #0 ; R6 deu 0?
    BXEQ LR ; nao eh primo
    B FIND_PRIMES
SALVAR
    STRB R0,[R2],#1 ; Salva no endereco de R2 o que tem em R0
	ADD R8,#1 ; Qtd de primos -> i
    BX LR

LOOP_I_BUBBLE_SORT
	LDR R1,=RAM_POS_SORT ; Posicao atual da ram pros primos
	MOV R2,#1 ; j
	PUSH {LR}
	BL LOOP_J_BUBBLE_SORT
	POP {LR}
	SUB R8,#1
	CMP R8,#1
	BXEQ LR
	B LOOP_I_BUBBLE_SORT
	
LOOP_J_BUBBLE_SORT
	LDRB R10,[R1] ; R10 = vetor[j]
	LDRB R11,[R1, #1] ; R11 = vetor[j + 1]
	CMP R10,R11
	ITT GT
		STRBGT R11,[R1]
		STRBGT R10,[R1, #1]
	ADD R1,#1
	ADD R2,#1
	
	CMP R2,R8
	BXEQ LR
	B LOOP_J_BUBBLE_SORT

FIM
	NOP
    ALIGN
    END