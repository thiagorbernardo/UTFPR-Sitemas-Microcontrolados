#include <stdint.h>
#include "tm4c1294ncpdt.h"

// número de vezes que um state de tecla deve
// ser lido em sequência para ser considerado estável
#define LIMITE_DEBOUNCING 3

void keyboard_refresh(void);
void refresh_key(uint32_t keyIndex, uint32_t keyPressed);

uint32_t check_key_pressed(uint32_t keyIndex);
void clear_key_pressed(void);
void reset_keyboard(void);

uint32_t dig_index(uint32_t digito);

// funções do utils.s
void SysTick_Wait1ms(uint32_t delay);
void SysTick_Wait1us(uint32_t delay);

// funções do gpio.c
void enable_keyboard_columns(uint32_t entrada);
void disable_keyboard_columns(void);
uint32_t read_lines(void);

// estados possíveis para uma dada tecla
typedef enum estados_teclas {
	KEY_RELEASED = 0x00000000,
	KEY_PRESSED_DEBOUNCING = 0x00010000,
	KEY_PRESSED = 0x00020000,
	KEY_RELEASED_DEBOUNCING = 0x00030000,
} EstadosTeclas;

// vetores que guardam o state das teclas:
static uint32_t key_states[16];
static uint32_t key_pressed[16]; // posição do vetor é uma tecla, para marcar que a tecla foi pressionada

// Muda vetores de acordo com as novas leituras do teclado
// Passa nas linhas e colunas para de descobrir qual tecla foi pressionada
void keyboard_refresh(void) {
	uint32_t keyIndex = 0;
	uint32_t current_column = 0;
	uint32_t linhaAtual = 0;

	for (current_column = 0; current_column < 4; ++current_column, keyIndex = current_column) {
		enable_keyboard_columns(current_column);
		SysTick_Wait1us(5);
		uint32_t linhasLidas = read_lines();
		
		for (linhaAtual = 0; linhaAtual < 4; keyIndex += 4, ++linhaAtual) {
			uint32_t keyPressed = (linhasLidas & (1 << linhaAtual)) == 0;
			refresh_key(keyIndex, keyPressed);
		}
	}
	disable_keyboard_columns();
}

// Atualiza key_states[keyIndex]
void refresh_key(uint32_t keyIndex, uint32_t keyPressed) {
	switch (key_states[keyIndex] & 0xFFFF0000) {
		case KEY_RELEASED:
			if (keyPressed) {
				key_states[keyIndex] = KEY_PRESSED_DEBOUNCING;
				key_pressed[keyIndex] = 1;
			}
			break;
		case KEY_PRESSED_DEBOUNCING:
			if (keyPressed) {
				++key_states[keyIndex];
				if (key_states[keyIndex] >= KEY_PRESSED_DEBOUNCING + LIMITE_DEBOUNCING) {
					key_states[keyIndex] = KEY_PRESSED;
				}
			} else {
				key_states[keyIndex] = KEY_RELEASED_DEBOUNCING;
			}
			break;
		case KEY_PRESSED:
			if (!keyPressed) {
				key_states[keyIndex] = KEY_RELEASED_DEBOUNCING;
			}
			break;
		case KEY_RELEASED_DEBOUNCING:
			if (keyPressed) {
				key_states[keyIndex] = KEY_PRESSED_DEBOUNCING;
			} else {
				++key_states[keyIndex];
				if (key_states[keyIndex] >= KEY_RELEASED_DEBOUNCING + LIMITE_DEBOUNCING) {
					key_states[keyIndex] = KEY_RELEASED;
				}
			}
			break;
	}
}

// Checa se a tecla de índice  foi pressionada, e se foi, zera essa
uint32_t check_key_pressed(uint32_t keyIndex) {
	if (key_pressed[keyIndex] == 1) {
		key_pressed[keyIndex] = 0;
		return 1;
	} else {
		return 0;
	}
}

// Limpa todas as posições do vetor key_pressed
void clear_key_pressed(void) {
	for (uint32_t i = 0; i < 16; ++i) {
		key_pressed[i] = 0;
	}
}

// Reseta os vetores
void reset_keyboard(void) {
	for (uint32_t i = 0; i < 16; ++i) {
		key_states[i] = 0;
		key_pressed[i] = 0;
	}
}

// Entrada; 0 a 9
// Retorna o índice do digito no teclado (vetor key_pressed), linha * 4 + coluna
uint32_t dig_index(uint32_t digito) {
	if (digito == 0) return 13;
	if (digito >= 1 && digito <= 9) {
		digito -= 1;
		uint32_t linha = digito / 3;
		uint32_t coluna = digito % 3;
		uint32_t indice = linha * 4 + coluna;
		return indice;
	}
	return 0;
}
