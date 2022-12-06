#include <stdint.h>
#include "tm4c1294ncpdt.h"

// Ports A, Q e P para os LEDs,
// Ports L e M para o teclado,
// Port  H para o motor de passo unipolar,
// Ports M e K para o display LCD,
// Port  J para o USR_SW1
// Port  N para o LED da placa vermelha
#define GPIO_PORTA  (0x00000001)
#define GPIO_PORTH  (0x00000080)
#define GPIO_PORTJ  (0x00000100)
#define GPIO_PORTK  (0x00000200)
#define GPIO_PORTL  (0x00000400)
#define GPIO_PORTM  (0x00000800)
#define GPIO_PORTN  (0x00001000)
#define GPIO_PORTP  (0x00002000)
#define GPIO_PORTQ  (0x00004000)

void GPIO_Init(void);
void portN_Output(uint32_t entrada);
void portP_Output(uint32_t entrada);
void portA_Output(uint32_t entrada);
void portQ_Output(uint32_t entrada);
void portH_Output(uint32_t entrada);
void portM_Output(uint32_t entrada);
void portK_Output_Config(uint32_t entrada);
void portK_Output(uint32_t entrada);
uint32_t portK_Input(void);
void enable_keyboard_columns(uint32_t entrada);
void disable_keyboard_columns(void);
uint32_t read_lines(void);

void GPIO_Init(void) {
	// 1. Ativar o clock para as portas
	uint32_t ports = (GPIO_PORTA | GPIO_PORTH | GPIO_PORTJ | GPIO_PORTK | GPIO_PORTL | GPIO_PORTM | GPIO_PORTN | GPIO_PORTP | GPIO_PORTQ);
	SYSCTL_RCGCGPIO_R = ports;
	while ( (SYSCTL_PRGPIO_R & ports) != ports ) {
		
	}
	
	// 2. Limpar o AMSEL
	GPIO_PORTA_AHB_AMSEL_R = 0x00;
	GPIO_PORTH_AHB_AMSEL_R = 0x00;
	GPIO_PORTJ_AHB_AMSEL_R = 0x00;
	GPIO_PORTK_AMSEL_R = 0x00;
	GPIO_PORTL_AMSEL_R = 0x00;
	GPIO_PORTM_AMSEL_R = 0x00;
	GPIO_PORTN_AMSEL_R = 0x00;
	GPIO_PORTP_AMSEL_R = 0x00;
	GPIO_PORTQ_AMSEL_R = 0x00;
		
	// 3. Limpar PCTL
	GPIO_PORTA_AHB_PCTL_R = 0x00;
	GPIO_PORTH_AHB_PCTL_R = 0x00;
	GPIO_PORTJ_AHB_PCTL_R = 0x00;
	GPIO_PORTK_PCTL_R = 0x00;
	GPIO_PORTL_PCTL_R = 0x00;
	GPIO_PORTM_PCTL_R = 0x00;
	GPIO_PORTN_PCTL_R = 0x00;
	GPIO_PORTP_PCTL_R = 0x00;
	GPIO_PORTQ_PCTL_R = 0x00;

	// 4. DIR para 0 se for entrada, 1 se for sa�da
	GPIO_PORTA_AHB_DIR_R = 0xF0; // bits 4 a 7 para os LEDs
	GPIO_PORTH_AHB_DIR_R = 0x0F; // bits 0 a 3 para o motor
	GPIO_PORTJ_AHB_DIR_R = 0x00; // bit  0     para o USR_SW1
	GPIO_PORTK_DIR_R     = 0xFF; // bits 0 a 7 para o display
	GPIO_PORTL_DIR_R     = 0x00; // bits 0 a 3 para as linhas do teclado
	GPIO_PORTM_DIR_R     = 0x07; // bits 0 a 2 para o display, 4 a 7 para as colunas do teclado
	GPIO_PORTN_DIR_R     = 0x01; // bit  0     para o LED da placa vermelha
	GPIO_PORTP_DIR_R     = 0x20; // bit  5     para o transistor dos LEDs
	GPIO_PORTQ_DIR_R     = 0x0F; // bits 0 a 3 para os LEDs

	// 5. Limpar os bits AFSEL
	GPIO_PORTA_AHB_AFSEL_R = 0x00;
	GPIO_PORTH_AHB_AFSEL_R = 0x00;
	GPIO_PORTJ_AHB_AFSEL_R = 0x00;
	GPIO_PORTK_AFSEL_R = 0x00;
	GPIO_PORTL_AFSEL_R = 0x00;
	GPIO_PORTM_AFSEL_R = 0x00;
	GPIO_PORTN_AFSEL_R = 0x00;
	GPIO_PORTP_AFSEL_R = 0x00;
	GPIO_PORTQ_AFSEL_R = 0x00;

	// 6. Setar os bits de DEN
	GPIO_PORTA_AHB_DEN_R = 0xF0; // bits 4 a 7 para os LEDs
	GPIO_PORTH_AHB_DEN_R = 0x0F; // bits 0 a 3 para o motor
	GPIO_PORTJ_AHB_DEN_R = 0x01; // bit  0     para o USR_SW1
	GPIO_PORTK_DEN_R     = 0xFF; // bits 0 a 7 para o display
	GPIO_PORTL_DEN_R     = 0x0F; // bits 0 a 3 para as linhas do teclado
	GPIO_PORTM_DEN_R     = 0xF7; // bits 0 a 2 para o display, 4 a 7 para as colunas do teclado
	GPIO_PORTN_DEN_R     = 0x01; // bit  0     para o LED da placa vermelha
	GPIO_PORTP_DEN_R     = 0x20; // bit  5     para o transistor dos LEDs
	GPIO_PORTQ_DEN_R     = 0x0F; // bits 0 a 3 para os LEDs
	
	// 7. Habilitar resistor de pull-up interno
	GPIO_PORTJ_AHB_PUR_R = 0x01; // bit  0     para o USR_SW1
	GPIO_PORTL_PUR_R     = 0x0F; // bits 0 a 3 para as linhas do teclado

}


// Escreve no bit 0 do registrador DATA do PortN o bit 0 da vari�vel de entrada
// Par�metro de entrada: valor a serem escritos no pino 0
// Par�metro de sa�da: n�o tem
void portN_Output(uint32_t entrada) {
	// ignora os outros bits de entrada
    uint32_t valor = entrada & 0x01;
	
    // escrita amig�vel
    GPIO_PORTN_DATA_R = (GPIO_PORTN_DATA_R & ~(0x01u)) | valor; 
}


// Escreve no bit 5 do registrador DATA do PortP o bit 5 da vari�vel de entrada
// Par�metro de entrada: valor a serem escritos no pino 5
// Par�metro de sa�da: n�o tem
void portP_Output(uint32_t entrada) {
	// ignora os outros bits de entrada
    uint32_t valor = entrada & 0x20;
	
    // escrita amig�vel
    GPIO_PORTP_DATA_R = (GPIO_PORTP_DATA_R & ~(0x20u)) | valor; 
}


// Escreve nos bits 4 a 7 do registrador DATA do PortA os bits 4 a 7 da vari�vel de entrada
// Par�metro de entrada: valores a serem escritos nos pinos 4 a 7
// Par�metro de sa�da: n�o tem
void portA_Output(uint32_t entrada) {
	// ignora os outros bits de entrada
    uint32_t valor = entrada & 0xF0;
	
    // escrita amig�vel
    GPIO_PORTA_AHB_DATA_R = (GPIO_PORTA_AHB_DATA_R & ~(0xF0u)) | valor; 
}


// Escreve nos bits 0 a 3 do registrador DATA do PortQ os bits 0 a 3 da vari�vel de entrada
// Par�metro de entrada: valores a serem escritos nos pinos 0 a 3
// Par�metro de sa�da: n�o tem
void portQ_Output(uint32_t entrada) {
	// ignora os outros bits de entrada
    uint32_t valor = entrada & 0x0F;
	
    // escrita amig�vel
    GPIO_PORTQ_DATA_R = (GPIO_PORTQ_DATA_R & ~(0x0Fu)) | valor; 
}

// Escreve nos bits 0 a 3 do registrador DATA do PortH os bits 0 a 3 da vari�vel de entrada
// Par�metro de entrada: valores a serem escritos nos pinos 0 a 3
// Par�metro de sa�da: n�o tem
void portH_Output(uint32_t entrada) {
	// ignora os outros bits de entrada
    uint32_t valor = (~entrada) & 0x0F;
	
    // escrita amig�vel
    GPIO_PORTH_AHB_DATA_R = (GPIO_PORTH_AHB_DATA_R & ~(0x0Fu)) | valor; 
}

// Escreve nos bits 0 a 2 do registrador DATA do PortM os bits 0 a 2 da vari�vel de entrada
// Par�metro de entrada: valores a serem escritos nos pinos 0 a 2
// Par�metro de sa�da: n�o tem
void portM_Output(uint32_t entrada) {
	// ignora os outros bits de entrada
    uint32_t valor = entrada & 0x07;
	
    // escrita amig�vel
    GPIO_PORTM_DATA_R = (GPIO_PORTM_DATA_R & ~(0x07u)) | valor; 
}


// Se a entrada � 0, o port K � configurado como entrada, e se for 1 � como sa�da
void portK_Output_Config(uint32_t entrada) {
	entrada &= 0x01;
	if (entrada == 0) {
		GPIO_PORTK_DIR_R &= ~(0xFFu);
	} else {
		GPIO_PORTK_DIR_R |=   0xFF;
	}
}

// Escreve no registrador DATA do PortK os bits da vari�vel de entrada correspondentes aos
// bits configurados como sa�da (o PortK tamb�m pode estar lendo a sa�da do LCD)
void portK_Output(uint32_t entrada) {
	// ignora os outros bits de entrada
	// utiliza como m�scara os bits configurados como sa�da
	uint32_t mascara = GPIO_PORTK_DIR_R & 0xFF;
    uint32_t valor = entrada & mascara;
	
    // escrita amig�vel
    GPIO_PORTK_DATA_R = (GPIO_PORTK_DATA_R & ~(mascara)) | valor; 
}

// L� e retorna o registrador DATA do PortK com os bits correspondentes aos
// bits configurados como entrada
uint32_t portK_Input(void) {
	// utiliza como m�scara os bits configurados como entrada
	uint32_t mascara = (~GPIO_PORTK_DIR_R) & 0xFF;
    return GPIO_PORTK_DATA_R & mascara;
}

// Configura como sa�da e escreve 0 na coluna selecionada pela vari�vel de entrada
// Par�metro de entrada: coluna selecionada (�ndice de 0 a 3)
// Par�metro de sa�da: n�o tem
void enable_keyboard_columns(uint32_t entrada) {
	// faz a entrada ser de 0 a 3 e soma 4 (pois os bits s�o de 4 a 7)
    uint32_t bit_selecionado = (entrada & 0x03) + 4;
	uint32_t coluna = 1 << bit_selecionado;

	// faz a coluna selecionada ser sa�da, enquanto as outras colunas voltam a ser alta imped�ncia
	// sem bagun�ar os bits relativos ao controle do LCD
	uint32_t valor_dir = GPIO_PORTM_DIR_R & ~(0xF0u);
	valor_dir |= coluna;
	GPIO_PORTM_DIR_R = valor_dir;
	
    // com escrita amig�vel faz a coluna igual a 0
    GPIO_PORTM_DATA_R = GPIO_PORTM_DATA_R & ~(coluna); 
}

// Configura como entrada todas as colunas do teclado
// Par�metro de entrada: n�o tem
// Par�metro de sa�da: n�o tem
void disable_keyboard_columns(void) {
	GPIO_PORTM_DIR_R = GPIO_PORTM_DIR_R & ~(0xF0u);
}

// L� o valor nas linhas do teclado
// Par�metro de entrada: n�o tem
// Par�metro de sa�da: valor lido do port L, bits 0 a 3
uint32_t read_lines(void) {
	return GPIO_PORTL_DATA_R & 0x0F;
}
