#include <stdint.h>
#include <stdlib.h>
#include "tm4c1294ncpdt.h"

#define CLOCKS_PER_PERIOD 80000
#define CLOCKS_PER_PERIOD_PERCENTAGE (CLOCKS_PER_PERIOD/100)

// utils.s
void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);
void SysTick_Wait1us(uint32_t delay);

void GPIO_Init(void);
void portE_Output(uint32_t entrada);
void portF_Output(uint32_t entrada);
void Timer_Init(void);
void Timer1A_Handler(void);

// uart.c
void UART_Init(void);
void clear_UART(void);
void read_char_UART(void);
void write_char_UART(uint32_t data);
void write_string_UART(const char *palavra);
void write_number_UART(uint32_t numero);

void ADC_Init(void);
void read_value_pot(void);

void awaiting_rotation(void);
void awaiting_control(void);
void velocity_options_terminal(void);
void velocity_options_pot(void);

void verify_rotation(void);
void verify_control(void);
void verify_velocity_terminal(void);
void update_velocity_pot(void);
void enableMotor(void);
void unableMotor(void);

typedef enum states{
	AWAITING_ROTATION_STATE,
	AWAITING_CONTROL_STATE,
	VELOCITY_TERMINAL_STATE,
	VELOCITY_POTENCIOMETER_STATE,
} States;

typedef enum rotation{
	CLOCKWISE, 
	COUNTER_CLOCKWISE,
	AWAITING_ROTATION,
} Rotation;

typedef enum control{
	TERMINAL, 
	POTENCIOMETER,
	AWAITING_CONTROL,
} Control;

typedef enum pwm_state{
	SEMICICLO_POSITIVO = 1, 
	SEMICICLO_NEGATIVO = 0,
} PWM_STATE;


States current_state = AWAITING_ROTATION_STATE;
Rotation motor_rotation = AWAITING_ROTATION;
Control control_type = AWAITING_CONTROL;
PWM_STATE pwm_state = SEMICICLO_NEGATIVO;

uint16_t value_pot = 0; // Valor entre 0 e 4095
char readed_char_UART = '\0';
uint32_t velocity_percentage = 0; // Velocidade de 0 a 100%

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	UART_Init();
	ADC_Init();
	Timer_Init();
	
	while (1) {
		// limpa o terminal
		clear_UART();
		// le o caractere do terminal
		read_char_UART();
		// le o valor do pot
		read_value_pot();
		// verifica qual a rotacao desejada, horario anti horario
		verify_rotation();
		switch(current_state) {
			// motor parado e aguardando que o usuario digite se vai ser horario ou antihorario
			case AWAITING_ROTATION_STATE:
				awaiting_rotation();
				break;
			// motor ainda parado e aguardando que o usuario digite se vai controlar a velociade pelo terminal ou pelo potenciometro
			case AWAITING_CONTROL_STATE:
				awaiting_control();
				break;
			// mostra todas as opcoes pro usuario no terminal e espera ele digitar um numero entre 0 e 6 para controlar a velocidade
			case VELOCITY_TERMINAL_STATE:
				velocity_options_terminal();
				break;
			// mostra todas as opcoes pro usuario no terminal e espera ele girar o potenciometro para controlar a velocidade
			case VELOCITY_POTENCIOMETER_STATE:
				velocity_options_pot();
				break;
			default:
				write_string_UART("Estado invalido\n");
				awaiting_rotation();
				break;
		}
		SysTick_Wait1ms(250);
	}
}

// Mostra as opções para o usuário escolher o sentido de rotação
void awaiting_rotation(void) {
	write_string_UART("Motor parado\n");
	write_string_UART("Indique o sentido da rotacao: horario (h) ou anti-horario (a)\n");
	if(motor_rotation != AWAITING_ROTATION)
		current_state = AWAITING_CONTROL_STATE;
}

// Mostra o sentido de rotação e mostra as opções para o usuário escolher
// controlar a velocidade pelo terminal ou pelo potenciômetro
void awaiting_control(void) {
	write_string_UART("Motor parado\n");
	if(motor_rotation == CLOCKWISE)
		write_string_UART("Sentido horario (h)\n");
	else
		write_string_UART("Sentido anti-horario (a)\n");
	write_string_UART("Deseja controlar a velocidade pelo terminal (t) ou potenciometro (p)?\n");
	verify_control();
	if(control_type == TERMINAL) {
		current_state = VELOCITY_TERMINAL_STATE;
		enableMotor();
	}
	else if(control_type == POTENCIOMETER) {
		current_state = VELOCITY_POTENCIOMETER_STATE;
		enableMotor();
	}
}

// Mostra o sentido de rotação e a velocidade e mostra as opções de 
// configuração de velocidade do motor
void velocity_options_terminal(void) {
	verify_velocity_terminal();
	if(motor_rotation == CLOCKWISE)
		write_string_UART("Sentido horario (h)\n");
	else
		write_string_UART("Sentido anti-horario (a)\n");
	write_string_UART("Controle pelo terminal. Motor girando a ");
	write_number_UART(velocity_percentage);
	write_string_UART("% da velocidade maxima.\n");
	write_string_UART("Escolha a velocidade da rotacao do motor: \n");
	write_string_UART("0 - Parar motor (0%)\n");
	write_string_UART("1 - 50% da velocidade\n");
	write_string_UART("2 - 60% da velocidade\n");
	write_string_UART("3 - 70% da velocidade\n");
	write_string_UART("4 - 80% da velocidade\n");
	write_string_UART("5 - 90% da velocidade\n");
	write_string_UART("6 - 100% da velocidade\n");
}

// Mostra o sentido de rotação, calcula a velocidade de acordo com a leitura 
// do potenciômetro e mostra a velocidade
void velocity_options_pot(void) {
	if(motor_rotation == CLOCKWISE)
		write_string_UART("Sentido horario (h)\n");
	else
		write_string_UART("Sentido anti-horario (a)\n");
	update_velocity_pot();
	write_string_UART("Controle pelo potenciometro. Motor girando a ");
	write_number_UART(velocity_percentage);
	write_string_UART("% da velocidade maxima.\n");
}

// Verifica o caractere lido e altera o sentido do motor se necessário
void verify_rotation(void) {
	if(readed_char_UART == 'h')
		motor_rotation = CLOCKWISE;
	else if(readed_char_UART == 'a')
		motor_rotation = COUNTER_CLOCKWISE;
}

// Verifica o caractere lido e altera o tipo do controle se necessário
void verify_control(void) {
	if(readed_char_UART == 't')
		control_type = TERMINAL;
	else if(readed_char_UART == 'p')
		control_type = POTENCIOMETER;
}

// Verifica o caractere lido e altera a velocidade do motor se necessário
void verify_velocity_terminal(void) {
	if(readed_char_UART == '0')
		velocity_percentage = 0;
	else if(readed_char_UART == '1')
		velocity_percentage = 50;
	else if(readed_char_UART == '2')
		velocity_percentage = 60;
	else if(readed_char_UART == '3')
		velocity_percentage = 70;
	else if(readed_char_UART == '4')
		velocity_percentage = 80;
	else if(readed_char_UART == '5')
		velocity_percentage = 90;
	else if(readed_char_UART == '6')
		velocity_percentage = 100;
}

// Atualiza a velocidade de acordo com o valor lido do potenciometro
void update_velocity_pot(void) {
	velocity_percentage = 100*value_pot/4095;
}

// Ativa o enable do motor e ativa a interrupção do timer
void enableMotor(void) {
	// ativa enable do motor (PF2)
	portF_Output(0x04);

	// começa parado
	pwm_state = SEMICICLO_NEGATIVO;
	portE_Output(0x00);

	// ativa interrupção do PWM
	TIMER1_TAILR_R = 100 * CLOCKS_PER_PERIOD_PERCENTAGE;
	TIMER1_ICR_R |= 0x01;
	TIMER1_CTL_R |= 0x01;
}

// Ativa o enable do motor e ativa a interrupção do timer
void unableMotor(void) {
	// desativa enable do motor (PF2)
	portF_Output(0x00);

	// para o motor
	pwm_state = SEMICICLO_NEGATIVO;
	portE_Output(0x00);

	// desativa interrupção do PWM
	TIMER1_CTL_R &= (~0x01u);
}

// Faz todas as configurações necessárias para utilização de comunicação serial entre a placa e um computador
void UART_Init(void) {
	// 1. Ativar o clock para o UART0
	uint32_t UART0 = SYSCTL_RCGCUART_R0;
	SYSCTL_RCGCUART_R = UART0;
	while ( (SYSCTL_RCGCUART_R & UART0) != UART0 ) {
		
	}
	
	UART0_CTL_R = 0;
	UART0_IBRD_R = 260;
	UART0_FBRD_R = 27;
	UART0_LCRH_R = 0x72;
	UART0_CC_R = 0;
	UART0_CTL_R = 0x301;

}

// Informa que um caractere foi lido e armazena o caractere em readed_char_UART
void read_char_UART(void) {
	if ((UART0_FR_R & 0x10) == 0x10) {
		// não há caractere para ser lido
		return;
	}
	
	readed_char_UART = UART0_DR_R;
}

// printa na tela um char
void write_char_UART(uint32_t data) {
	while ((UART0_FR_R & 0x20) == 0x20) {
		
	}
	
	UART0_DR_R = data;
}

// limpa a tela
void clear_UART(void) {
	// envia Esc[2J
	write_char_UART(0x1B);
	write_char_UART('[');
	write_char_UART('2');
	write_char_UART('J');

	// move o cursor para o inicio da tela

	// envia Esc[;H
	write_char_UART(0x1B);
	write_char_UART('[');
	write_char_UART(';');
	write_char_UART('H');
}


// Escreve na tela a string recebida
void write_string_UART(const char *word) {
	while (*word != '\0') {
		write_char_UART(*word);
		++word;
	}
}

// Escreve o número enviado no argumento, supondo que tem no máximo 16 dígitos
void write_number_UART(uint32_t numero) {
	char digitos_invertidos[16] = {'0'};
	uint32_t numero_digitos = 0;

	while (numero > 0) {
		digitos_invertidos[numero_digitos] = '0' + numero % 10;
		numero /= 10;
		++numero_digitos;
	}
	if (numero_digitos == 0) {
		// isso significa que é um zero
		numero_digitos = 1;
	}

	while (numero_digitos > 0) {
		--numero_digitos;
		write_char_UART(digitos_invertidos[numero_digitos]);
	}
}

// Faz a inicializacao do conversor AD
void ADC_Init(void) {
	// 1. Ativar o clock para o ADC
	uint32_t adc0 = SYSCTL_RCGCADC_R0;
	SYSCTL_RCGCADC_R = adc0;
	while ( (SYSCTL_PRADC_R & adc0) != adc0 ) {
		
	}
	
	ADC0_PC_R = 0x07;
	ADC0_SSPRI_R = (0 << 12) | (1 << 8) | (2 << 4) | 3;
	ADC0_ACTSS_R = 0;
	ADC0_EMUX_R = 0;
	ADC0_SSMUX3_R = 9;
	ADC0_SSCTL3_R = 6;
	ADC0_ACTSS_R = 8;
}

// le valor do pot e armazena em value_pot caso o novo valor seja maior que o limiar 20
void read_value_pot(void) {
	ADC0_PSSI_R = 8;

	if (ADC0_RIS_R != 8) {
		// resultado ainda não está pronto
		// retorna sem alterar tensaoPot
		return;
	}
	
	uint32_t new_value = ADC0_SSFIFO3_R;
	ADC0_ISC_R = 8;
	if (new_value - value_pot < 20) {
		// se o novo valor não é muito diferente, não é escrito
		return;
	}
	value_pot = new_value;
}

// Configura interrupção de estouro do timer 1 com 32 bits no modo periódico
void Timer_Init(void) {
	SYSCTL_RCGCTIMER_R |= 0x02;
	while ((SYSCTL_PRTIMER_R & 0x02) == 0) {
		
	}

	TIMER1_CTL_R &= ~(0x01u);
	TIMER1_CFG_R &= ~(0x07u);
	TIMER1_TAMR_R = (TIMER1_TAMR_R & ~(0x03u)) | 0x02;
	TIMER1_TAILR_R = 100 * CLOCKS_PER_PERIOD_PERCENTAGE;
	TIMER1_TAPR_R = 0;
	TIMER1_ICR_R |= 0x01;
	TIMER1_IMR_R |= 0x01;
	NVIC_PRI5_R = 4u << 13;
	NVIC_EN0_R = 1u << 21;
	// não ativa até que entremos em um dos estados girando
	//TIMER1_CTL_R |= 0x01;
}

// Faz o PWM do motor
void Timer1A_Handler(void) {
	// Se der problema, tratar diferente 0% e 100%
	uint32_t time = 0;
	if (velocity_percentage == 0) {
		pwm_state = SEMICICLO_NEGATIVO;
		time = 100 * CLOCKS_PER_PERIOD_PERCENTAGE;
	} else if (velocity_percentage == 100) {
		pwm_state = SEMICICLO_POSITIVO;
		time = 100 * CLOCKS_PER_PERIOD_PERCENTAGE;
	} else {
		if (pwm_state == SEMICICLO_NEGATIVO) {
			pwm_state = SEMICICLO_POSITIVO;
			time = velocity_percentage * CLOCKS_PER_PERIOD_PERCENTAGE;
		} else {
			pwm_state = SEMICICLO_NEGATIVO;
			time = (100 - velocity_percentage) * CLOCKS_PER_PERIOD_PERCENTAGE;
		}
	}

	if(motor_rotation == CLOCKWISE) {
		// Escreve o PWM no bit_0 e deixa o bit_1 zerado
		portE_Output((unsigned) pwm_state);
	} else {
		// Escreve o PWM no bit_1 e deixa o bit_0 zerado
		portE_Output((unsigned) pwm_state << 1);
	}

	TIMER1_TAILR_R = time;
	TIMER1_ICR_R |= 0x01;
}
