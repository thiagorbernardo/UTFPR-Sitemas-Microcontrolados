#include <stdint.h>
#include "tm4c1294ncpdt.h"

#define ENTRADA 0
#define SAIDA 1

// fun��es do utils.s
void SysTick_Wait1ms(uint32_t delay);
void SysTick_Wait1us(uint32_t delay);

// fun��es do gpio.c
void portM_Output(uint32_t entrada);
void portK_Output_Config(uint32_t entrada);
void portK_Output(uint32_t entrada);
uint32_t portK_Input(void);

void write_lcd(uint32_t byte, uint32_t dado_ou_comando);
void lcd_init(void);
void move_lcd_cursor(uint32_t linha, uint32_t coluna);
void write_lcd_string(const char *string);
void write_lcd_digit(uint32_t numero);

// Manda o byte de entrada (que pode ser dado ou comando) para o LCD.
// Se dado_ou_comando � 1, o byte � de dado, e se 0 o byte � de comando.
void write_lcd(uint32_t byte, uint32_t dado_ou_comando) {
	// ignora outros bits
	dado_ou_comando &= 0x01;
	portK_Output_Config(SAIDA);
	SysTick_Wait1us(1);

	// escreve byte e manda enable por 20 us
	portK_Output(byte);
	portM_Output(0x04 | dado_ou_comando);
	SysTick_Wait1us(20);

	// zera enable e conta mais 20 us
	portM_Output(dado_ou_comando);
	SysTick_Wait1us(20);

	// prepara para ler busy flag
	portK_Output_Config(ENTRADA);
	SysTick_Wait1us(1);

	// manda LCD escrever no port K ao inv�s de ler
	portM_Output(0x02);

	// espera no m�ximo 80*50us = 4ms (mas deve sempre sair antes)
	uint32_t timeout = 80;
	while (timeout > 0) {
		SysTick_Wait1us(40);

		// ativa enable para poder ver o busy flag
		portM_Output(0x04 | 0x02);
		SysTick_Wait1us(10);
		if ((portK_Input() & 0x80) == 0) {
			// j� est� pronto, podemos sair
			break;
		}
		portM_Output(0x02);
		--timeout;
	}
	
	portM_Output(0x00);
	portK_Output_Config(SAIDA);
}

// Configura LCD e os caracteres extras
void lcd_init(void) {
	// comando 0x38: configura display para usar 2 linhas e caracteres de 5x8
	write_lcd(0x38, 0);
	
	// comando 0x06: autoincremento para a direita
	write_lcd(0x06, 0);
	
	// comando 0x0E: habilita o display e cursor que n�o pisca
	write_lcd(0x0E, 0);
	
	// comando 0x01: limpa o display e volta para o in�cio
	write_lcd(0x01, 0);
	
	//////////////////////////////////////////////////////////////////////////
	
	// comando 0x70: seleciona endere�o da CGRAM 2_110000
	write_lcd(0x70, 0);
	
	// as seguintes intru��es colocam entre os endere�os 2_110000 e 2_110111
	// os dados necess�rios para se desenhar uma flecha indicando sentido anti-hor�rio
	write_lcd(0x00, 1);
	write_lcd(0x0E, 1);
	write_lcd(0x11, 1);
	write_lcd(0x11, 1);
	write_lcd(0x14, 1);
	write_lcd(0x0C, 1);
	write_lcd(0x1C, 1);
	write_lcd(0x00, 1);
	
	// comando 0x78: seleciona endere�o da CGRAM 2_111000
	write_lcd(0x78, 0);
	
	// as seguintes intru��es colocam entre os endere�os 2_111000 e 2_111111
	// os dados necess�rios para se desenhar uma flecha indicando sentido hor�rio
	write_lcd(0x00, 1);
	write_lcd(0x0E, 1);
	write_lcd(0x11, 1);
	write_lcd(0x11, 1);
	write_lcd(0x05, 1);
	write_lcd(0x06, 1);
	write_lcd(0x07, 1);
	write_lcd(0x00, 1);
	
	// volta a apontar para a DDRAM, no endere�o inicial (primeira posi��o do display)
	write_lcd(0x80, 0);
}

// Move cursor para linha e coluna especificados, com linha entre 0 e 1
// e coluna entre 0 e 15
void move_lcd_cursor(uint32_t line, uint32_t column) {
	line &= 0x01;
	column &= 0x0F;

	uint32_t comando = 0x80 | (line << 6) | column;
	write_lcd(comando, 0);
}

// Escreve a string (terminada em '\0') enviada no argumento
void write_lcd_string(const char *string) {
	uint32_t i = 0;
	while (string[i] != '\0') {
		write_lcd(string[i], 1);
		++i;
	}
}

// Escreve o n�mero enviado no argumento, supondo que � de no m�ximo 2 d�gitos
// Se o n�mero for de um s� d�gito, escreve um espa�o antes
void write_lcd_digit(uint32_t number) {
	if ((number / 10) != 0) {
		write_lcd('0' + ((number / 10) % 10), 1);
	} else {
		write_lcd(' ', 1);
	}
	write_lcd('0' + number % 10, 1);
}
