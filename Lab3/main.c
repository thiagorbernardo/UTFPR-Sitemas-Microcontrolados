#include <stdint.h>
#include "tm4c1294ncpdt.h"

// defines para deixar mais legível as chamadas a "ativaDesativaInterrupcaoTimer"
#define DISABLE 0
#define ACTIVE 1

#define HORARIO 0
#define ANTIHORARIO 1

#define MEIOPASSO 0
#define PASSOCOMPLETO 1

// passos para uma volta do motor utilizado
#define NUM_PASSOS 2048
#define PASSOS_POR_SEGUNDO 400

// índice das teclas especiais no teclado matricial
#define TECLA_A 3
#define TECLA_B 7
#define TECLA_C 11
#define TECLA_D 15
#define STAR_KEY 12
#define HASHTAG_KEY 14

// estados do loop principal
typedef enum execution_states {
	AWAITING_STATE,
	SPIN_STATE,
	END_STATE
} ExecutionStates;

// funções do utils.s
void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);
void SysTick_Wait1us(uint32_t delay);
//

// funções do gpio.c
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

// teclado.c
void keyboard_refresh(void);
void atualizaTecla(uint32_t keyIndex, uint32_t keyPressed);
uint32_t check_key_pressed(uint32_t keyIndex);
void clear_key_pressed(void);
void reset_keyboard(void);

// funções desse arquivo (as declaradas como static só são usadas nesse arquivo)
static void GPIO_Int_Init(void);
static void Timer_Int_Init(void);
static void ativaDesativaInterrupcaoTimer(uint32_t ativar);
static void TimerMotor_Int_Init(void);

void GPIOPortJ_Handler(void);
void Timer2A_Handler(void);
void Timer1A_Handler(void);

// display.c
void write_lcd(uint32_t byte, uint32_t dado_ou_comando);
void lcd_init(void);
void move_lcd_cursor(uint32_t linha, uint32_t coluna);
void write_lcd_string(const char *string);
void write_lcd_digit(uint32_t numero);

uint32_t dig_index(uint32_t digito);

static void awaiting_state(void);
static void spin_state(void);
static void end_state(void);

static void meioPassoMotor(void);
static void passoCompletoMotor(void);

static void led_output(uint16_t led);

const uint32_t port_passo_completo_output[4] = { 0x08, 0x04, 0x02, 0x01 };
const uint32_t meio_passo_output[8] = { 0x08, 0x0C, 0x04, 0x06, 0x02, 0x03, 0x01, 0x09 };
static uint32_t passoCompletoAtual = 0;
static uint32_t meioPassoAtual = 0;

// state do LED da placa vermelha (usada para indicar motor girando)
static volatile uint32_t ledPlaca = 0;

// começamos no state "esperando configuração"
static ExecutionStates state = AWAITING_STATE;

// state "AWAITING" e "SPIN"
static uint16_t numVoltas = 1;
static uint16_t sentidoMotor = 0; // 0 para horário e 1 para anti-horário
static uint16_t velocidadeMotor = 1; // 0 para meio passo e 1 para passo completo

// state "SPIN"
static uint32_t passosDados;
static uint32_t valorParaAcender;
static uint32_t contLed;
static uint32_t voltasFaltando;

static volatile uint32_t hora_de_dar_um_passo = 1;
static uint32_t atualizar_display = 1;

// indica para o programa principal se o botão de cancelar foi apertado
static volatile uint32_t cancelado = 0;


int main(void) {
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	
	GPIO_Int_Init();
	Timer_Int_Init();
	TimerMotor_Int_Init();
	lcd_init();
	reset_keyboard();
	led_output(0x00);
	portP_Output(0x20);

	while (1) {
		keyboard_refresh();
		switch (state) {
			case AWAITING_STATE:
				awaiting_state();
				break;
			case SPIN_STATE:
				spin_state();
				break;
			case END_STATE:
				end_state();
				break;
		}
	}
}


// Configura interrupção em borda de descida para a chave USR_SW1
static void GPIO_Int_Init(void) {
	GPIO_PORTJ_AHB_IM_R = 0x00;
	GPIO_PORTJ_AHB_IS_R = 0x00;
	GPIO_PORTJ_AHB_IBE_R = 0x00;
	GPIO_PORTJ_AHB_IEV_R = 0x00;
	GPIO_PORTJ_AHB_ICR_R = 0x01;
	GPIO_PORTJ_AHB_IM_R = 0x01;
	NVIC_EN1_R = 0x80000;
	NVIC_PRI12_R = 5u << 29;
}

// Muda a variável volátil "cancelado" que indica se a operação de giro foi cancelada
void GPIOPortJ_Handler(void) {
	cancelado = 1;
	GPIO_PORTJ_AHB_ICR_R = 0x01;
}

// Configura interrupção de estouro do timer 2 com 32 bits no modo periódico
static void Timer_Int_Init(void) {
	SYSCTL_RCGCTIMER_R |= 0x04;
	while ((SYSCTL_PRTIMER_R & 0x04) == 0) {
		
	}

	TIMER2_CTL_R &= ~(0x01u);
	TIMER2_CFG_R &= ~(0x07u);
	TIMER2_TAMR_R = (TIMER2_TAMR_R & ~(0x03u)) | 0x02;
	TIMER2_TAILR_R = 15999999; // 50 ms
	TIMER2_TAPR_R = 0;
	TIMER2_ICR_R |= 0x01;
	TIMER2_IMR_R |= 0x01;
	NVIC_PRI5_R = 4u << 29;
	NVIC_EN0_R = 1u << 23;
	// TIMER2_CTL_R |= 0x01;
	// somente ativa quando entrar no state girando
}


// Muda o state do LED da placa vermelha
void Timer2A_Handler(void) {
	ledPlaca ^= 0x01;
	portN_Output(ledPlaca);
	TIMER2_ICR_R |= 0x01;
}


// Configura interrupção de estouro do timer 1 com 32 bits no modo periódico
static void TimerMotor_Int_Init(void) {
	SYSCTL_RCGCTIMER_R |= 0x02;
	while ((SYSCTL_PRTIMER_R & 0x02) == 0) {
		
	}

	TIMER1_CTL_R &= ~(0x01u);
	TIMER1_CFG_R &= ~(0x07u);
	TIMER1_TAMR_R = (TIMER1_TAMR_R & ~(0x03u)) | 0x02;
	TIMER1_TAILR_R = 80000000 / PASSOS_POR_SEGUNDO;
	TIMER1_TAPR_R = 0;
	TIMER1_ICR_R |= 0x01;
	TIMER1_IMR_R |= 0x01;
	NVIC_PRI5_R = 4u << 13;
	NVIC_EN0_R = 1u << 21;
	TIMER1_CTL_R |= 0x01;
}

// Diz que é hora de dar um passo
void Timer1A_Handler(void) {
	hora_de_dar_um_passo = 1;
	TIMER1_ICR_R |= 0x01;
}

// Ativa ou desativa a interrupção do timer
// Se "ativar" é 1, ativa a interrupção, e se é 0 desativa
static void ativaDesativaInterrupcaoTimer(uint32_t ativar) {
	if (ativar == ACTIVE) {
		TIMER2_CTL_R |= 0x01;
	} else {
		TIMER2_CTL_R &= ~(0x01u);
	}
}

// Checa se botões foram apertados, e se sim muda as configurações correspondentes
static void awaiting_state(void) {
 	if (check_key_pressed(TECLA_A)) {
    sentidoMotor = !sentidoMotor;
	}
	
	if (check_key_pressed(TECLA_B)) {
		velocidadeMotor = !velocidadeMotor;
	}
	
	// Procura no vetor qual digito foi pressionado, se for 0 é 10
	if (check_key_pressed( dig_index(0) )) {
		numVoltas = 10;
	} else {
		for (uint32_t i = 1; i <= 9; ++i) {
			if (check_key_pressed( dig_index(i) )) {
				numVoltas = i;
			}
		}
	}
	
	// se a hashtag for pressionada alterna o state para spin
	// ativa interrupcao
 	if (check_key_pressed(HASHTAG_KEY)){
		state = SPIN_STATE;
		cancelado = 0;
		ativaDesativaInterrupcaoTimer(ACTIVE);
		
		passosDados = 0;
		if (sentidoMotor == HORARIO) {
			contLed = 0x01;
		} else {
			contLed = 0x80;
		}
		if (velocidadeMotor == MEIOPASSO) {
			valorParaAcender = NUM_PASSOS/4;
		} else {
			valorParaAcender = NUM_PASSOS/8;
		}
		voltasFaltando = numVoltas;

		hora_de_dar_um_passo = 1;
		atualizar_display = 1;
		cancelado = 0;
	}

	// coloca na primeira linha
	move_lcd_cursor(0, 0);
	if (numVoltas == 1) {
		write_lcd_string("     1 volta    ");
	} else {
		write_lcd_string("   ");
		write_lcd_digit(numVoltas);
		write_lcd_string(" voltas");
	}

	// coloca na segunda linha
	move_lcd_cursor(1, 0);
	if (velocidadeMotor == MEIOPASSO) {
		write_lcd_string("  Meio passo ");
	} else {
		write_lcd_string("Passo completo ");
	}

	// coloca a letra A ou H de acordo com o sentido do motor
	if (sentidoMotor == ANTIHORARIO) {
		write_lcd_string("A");
	} else {
		write_lcd_string("H");
	}
}

static void spin_state(void) {
	
	if (cancelado == 1) {
		ativaDesativaInterrupcaoTimer(DISABLE);
		ledPlaca = 0x00;
		portN_Output(ledPlaca);
		state = END_STATE;
		clear_key_pressed();
		cancelado = 0;
		return;
	}

  // só escreve quando começa ou quando dá uma volta
	if (atualizar_display == 1) {
		// coloca na primeira linha
		move_lcd_cursor(0, 0);
		if (voltasFaltando != 1) {			
			write_lcd_string("Faltam ");
			write_lcd_digit(voltasFaltando);
			write_lcd_string(" voltas");
		} else {
			write_lcd_string(" Falta 1 volta ");
		}
		
		// coloca na segunda linha
		move_lcd_cursor(1, 0);
		if (velocidadeMotor == MEIOPASSO) {
			write_lcd_string("  Meio passo ");
		} else {
			write_lcd_string("Passo completo ");
		}

		if (sentidoMotor == ANTIHORARIO) {
			write_lcd_string("A");
		} else {
			write_lcd_string("H");
		}
		
		atualizar_display = 0;
	}
	
	if (hora_de_dar_um_passo == 1) {
		if (velocidadeMotor == MEIOPASSO) {
			meioPassoMotor();
		} else {
			passoCompletoMotor();
		}
		++passosDados;
		
		if (passosDados == valorParaAcender) {
			led_output(contLed);
			
			if (sentidoMotor == HORARIO) { // shift para acender o prox led
				contLed <<= 1;
			} else {
				contLed >>= 1;
			}
			
			if (velocidadeMotor == MEIOPASSO) {
				valorParaAcender = valorParaAcender + (NUM_PASSOS/4);
			} else {
				valorParaAcender = valorParaAcender + (NUM_PASSOS/8);
			}
			
		}
		
		// checa se finalizou uma volta
		if ((passosDados == NUM_PASSOS && velocidadeMotor == PASSOCOMPLETO) || (passosDados == 2 * NUM_PASSOS && velocidadeMotor == MEIOPASSO)) {
			passosDados = 0; // reseta os passos
			
			if (sentidoMotor == HORARIO) { // reseta para o primeiro led
				contLed = 0x01;
			} else {
				contLed = 0x80;
			}
			
			if (velocidadeMotor == MEIOPASSO) {
				valorParaAcender = NUM_PASSOS/4;
			} else {
				valorParaAcender = NUM_PASSOS/8;
			}
			// diminui as voltas faltantes e seta para atualizar o display
			--voltasFaltando;
			atualizar_display = 1;
			
			// checa se acabou as voltas e seta para o end state
			if (voltasFaltando == 0) {
				ativaDesativaInterrupcaoTimer(DISABLE);
				ledPlaca = 0x00;
				portN_Output(ledPlaca);
				state = END_STATE;
				clear_key_pressed();
			}
		}
		
		hora_de_dar_um_passo = 0;
	}
	
}

static void end_state(void){
	move_lcd_cursor(0, 0);
	write_lcd_string("       FIM      ");
	move_lcd_cursor(1, 0);
	write_lcd_string("                ");
	led_output(0x00);
  if (check_key_pressed(STAR_KEY)) { // se receber asterisco comeca tudo de novo
		clear_key_pressed();
		state = AWAITING_STATE;
  }
}

static void meioPassoMotor(void) {
	portH_Output(meio_passo_output[meioPassoAtual]);
	SysTick_Wait1ms(2);
	if (sentidoMotor == MEIOPASSO) {
		++meioPassoAtual;
		if (meioPassoAtual >= 8) { // se chegou em 8 meio passos reseta
			meioPassoAtual = 0;
		}
	} else {
		if (meioPassoAtual == HORARIO) {
			meioPassoAtual = 7;
		} else {
			--meioPassoAtual;
		}
	}
}

static void passoCompletoMotor(void) {
	portH_Output(port_passo_completo_output[passoCompletoAtual]);
	SysTick_Wait1ms(2);
	if (sentidoMotor == 0) {
		++passoCompletoAtual;
		if (passoCompletoAtual >= 4) { // se chegou em 4 passos completos reseta
			passoCompletoAtual = 0;
		}
	} else {
		if (passoCompletoAtual == 0) {
			passoCompletoAtual = 3;
		} else {
			--passoCompletoAtual;
		}
	}
}

static void led_output(uint16_t led){
	portA_Output(led);
	portQ_Output(led);
}
