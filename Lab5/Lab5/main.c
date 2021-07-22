/*
 * Lab5.c
 *
 * Created: 4/9/2021 12:09:14 PM
 * Author : Hongyu Louis
 * source used: https://embedds.com/programming-avr-usart-with-avr-gcc-part-1/
 * https://www.learncpp.com/cpp-tutorial/passing-arguments-by-address/
 * https://maker.pro/custom/tutorial/how-to-take-analog-readings-with-an-avr-microcontroller
 * https://stackoverflow.com/questions/905928/using-floats-with-sprintf-in-embedded-c
 * https://stackoverflow.com/questions/3889992/how-does-strtok-split-the-string-into-tokens-in-c
 * https://www.tutorialspoint.com/c_standard_library/c_function_sscanf.htm
 * usart_prints and usart_putc are only used when building and testing the program, no longer needed
 */ 

// define clock frequency and calculate the corresponding baudrate 
#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#define USART_BAUDRATE 9600
#define UBRR_VALUE (((F_CPU / (USART_BAUDRATE * 16UL))) - 1)

#include <stdio.h>
#include <avr/io.h>
#include <util/delay.h>
#include <avr/pgmspace.h>

void usart_init();
//void usart_prints(const char arr[]); 
unsigned char usart_receives(); 
//void usart_putc(char t);
void usart_transmit(char arr[]);
void readADC(float *ptr); 
void delay1s();


int main(void)
{
	// temp char for holding received command char
	unsigned char c;
	// holding command
	char command[25];
	// holding string output
	char outstr[25];
	// holding float value for voltage
	float v;
	// how many times we should sample, based on M command argument
	int sampletimes;
	// sampling intervals based on M command argument
	int interval;
	// whether the M command arguments are valid 
	int valid; // 0 is invalid
	// initialize usart
	usart_init();
	// initialize ADC
	ADC_init();
	// repeatly running the program
	while (1) {
		valid = 1;
		int i = 0;
		int counter = 0;
		usart_transmit("Please Give Command: ");
		for (i=0;i<=24;i++){
			c = usart_receives(); // Get character
			command[i] = c;
			if (c == ' ') {
				break; // space bar indicate the end of a command
			}
		}
		command[i] = '\0';
		// echo the command back to the screen
		usart_transmit(command);
		usart_transmit("\n"); 
		// G type
		if (command[0] == 'G') {
			usart_transmit("G type\n");
			readADC(&v); // get adc reading and convert it to voltages, store in v
			sprintf(outstr, "v = %.3f V\n", v); // give output to the serial monitor
			usart_transmit(outstr);
		} else { // M type
			usart_transmit("M type\n");
			char *pch;  // points to the start of the next string fragment 
			pch = strtok(command, ",");
			while (pch != NULL) { // split the M command to get sampling times and intervals
				if (counter == 0) {
					usart_transmit("It's M\n");
				} else if (counter == 1) {
					sscanf(pch, "%d", &sampletimes);
				} else if (counter == 2) {
					sscanf(pch, "%d", &interval);
				}
				counter ++;
				pch = strtok (NULL, ","); // memories the modifed string so NULL for no new input 
			}
			if (sampletimes < 2 || sampletimes > 20) { // checking if sampling times is valid
				usart_transmit("Invalid sampling times!\n");
				valid = 0;
			} 
			if (interval < 1 || interval > 10 ) { // checking if the interval is valid
				usart_transmit("Invalid interval!\n");
				valid = 0;
			}
			//usart_transmit("interval is: ");
			//char temp[10];
			//sprintf(temp, "%d\n", interval);
			//usart_transmit(temp);
			if (valid == 1) { // if all argumetns are valid
				int j = 0;
				int curtime = 0;
				int k;
				while(1) { // keeps giving samples until break
					readADC(&v); // keep calling G command
					sprintf(outstr, "t = %d s, ", curtime);
					usart_transmit(outstr);
					sprintf(outstr, "v = %.3f V\n", v);
					usart_transmit(outstr);
					if (j >= sampletimes - 1) {
						break; // reaches the sampling times give
					}
					j++;
					curtime += interval;
					delay1s(); 
					for (k = 0; k < interval; k++) { // delay specific amount of time
						delay1s();
					}
				}
			}
		}
		
	}
}

void usart_init() {
	// Set baud rate
	UBRR0H = (unsigned char)(UBRR_VALUE>>8);
	UBRR0L = (unsigned char)UBRR_VALUE;
	// Set frame format to 8 data bits, no parity, 1 stop bit
	UCSR0C |= (1<<UCSZ01)|(1<<UCSZ00);
	//enable transmission and reception
	UCSR0B |= (1<<RXEN0)|(1<<TXEN0);
}

/*void usart_prints(const char arr[]){
	// Uses polling (and it blocks).
	int j;
	for (j = 0; j <= strlen(arr)-1; j++) {
		while (!( UCSR0A & (1<<UDRE0))) {};
		UDR0 = arr[j];
	}
} */

unsigned char usart_receives() {
	// Wait for byte to be received
	while(!(UCSR0A&(1<<RXC0))){}; 
	// Return received data
	return UDR0; // get char from buffer
}

/*void usart_putc(char t) {
	while (!( UCSR0A & (1<<UDRE0))) {};
	UDR0 = t;
} */

void usart_transmit(char arr[]) {
	// Uses polling (and it blocks). 
	int j;
	for (j = 0; j <= strlen(arr)-1; j++) {
		while (!( UCSR0A & (1<<UDRE0))) {}; // until buffer empty
		UDR0 = arr[j]; // put the char to the buffer
	}
}

void ADC_init() {
	ADMUX = (1 << REFS0); //  AVCC with external capacitor at AREF pin
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // enable ADC and set prescalar to /128
}

void readADC(float *ptr) {
	ADCSRA |= 1 << ADSC; // start conversion
	while (ADCSRA & (1 << ADSC)) { // until finished conversion	
	}
	
	uint16_t digitalV = ADC;  // get ADC reading
	//char temp[20];
	//sprintf(temp, "%d", digitalV);
	//usart_transmit(temp);
	*ptr = (digitalV/1024.0)*5.0; // change value where ptr is pointing at
	//*ptr = 6/5.0;
}

void delay1s() {
	_delay_ms(1000);
}