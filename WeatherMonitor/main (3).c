/*
 * WeatherMonitor.c
 *
 * Created: 4/26/2021 8:59:35 PM
 * Author : hONGYU LOUIS 
 */ 


/*
* to do list:
* valid sampling time interval is between 2s to 48 hours (inclusive) 
* 
*/


// https://www.tutorialspoint.com/cprogramming/c_passing_arrays_to_functions.htm
// https://stackoverflow.com/questions/37487528/how-to-get-the-value-of-every-bit-of-an-unsigned-char
//

// define clock frequency and calculate the corresponding baudrate
#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#define USART_BAUDRATE 9600
#define UBRR_VALUE (((F_CPU / (USART_BAUDRATE * 16UL))) - 1)

#include <stdio.h>
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

void usart_init();
void ADC_init();
unsigned char usart_receives();
void usart_transmit(char arr[]);
void readDHT();
void displayDHT(char outstr[]);
void displayTemp();
void readBrightness();
void displayBrightness();
void LightnessOutside();
void delayOverall();
void debounce();

// global variables
int sec = 5;
int minute = 0;
int hour = 0;
uint8_t DHTresult[5] = {0,0,0,0,0}; // DHT11 data array
char command[20];
int changed = 0; // if the button is pressed and command is given 
int pressed = 0; // if the button is pressed
int brightness = 0;
int RHenable = 1; // Humidity data reading enables
int TEMPenable = 1; // Temp data reading enables
int BRenbale = 1; // light sensor data reading enables
int ReadingEnables = 111; //RH,Temp,Brightness

ISR (INT0_vect) { // interrupt function to display msg to serial monitor along with receiving input
	debounce(); 
	if (pressed) { 
		int timebuffer = 0; // buffer for number extracted from command
		// reset 
		char c;
		char echo[100]; 
		int i;
		int valid = 1; // assume valid input at first, if invalid, clear to 0
		usart_transmit("Please enter command for configs: (hour,minute,second,3 bits command for readings(example: 111)+SPACEBAR)\n");
		for (i=0;i<24;i++){
			c = usart_receives(); // Get character
			command[i] = c;
			if (c == ' ') {
				break; // space bar indicate the end of a command
			}
		}
		command[i] = '\0';
		char *pch;  // points to the start of the next string fragment
		int counter = 0;
		pch = strtok(command, ",");
		while (pch != NULL) { // split the M command to get sampling times and intervals
			if (counter == 0) { // hour input
				sscanf(pch, "%d", &timebuffer);
				if (timebuffer >= 48) {
					usart_transmit("Invalid time settings.\n");
					valid = 0;
					break;
				} else {
					hour = timebuffer;
				}
			} else if (counter == 1) { // minute input
				sscanf(pch, "%d", &timebuffer);
				minute = timebuffer;
			} else if (counter == 2) { // sec input
				sscanf(pch, "%d", &timebuffer);
				if (timebuffer <= 1 && hour == 0 && minute == 0) {
					usart_transmit("Invalid time settings.\n");
					valid = 0;
					break;
				} else {
					sec = timebuffer;
				}
			} else if (counter == 3) { // data enables input
				sscanf(pch, "%d", &ReadingEnables);
			} else {
				usart_transmit("Something went wrong.\n");
			}
			counter ++;
			pch = strtok (NULL, ","); // memories the modifed string so NULL for no new input
		}
		if (valid) { // valid time settings
			// modify enables
			if (ReadingEnables == 0) { 
				usart_transmit("Warning: No readings enabled.\n");
			} else {
				if ((ReadingEnables / 100) != 0) { // extract MSB for Humidity data reading enables
					RHenable = 1;
					usart_transmit("Humidity readings enabled.\n");
					ReadingEnables = ReadingEnables % 100;
				} else {
					RHenable = 0;
					usart_transmit("Humidity readings disabled.\n");
					ReadingEnables = ReadingEnables % 100;
				}
				if ((ReadingEnables / 10) != 0) { // extract middle bit for Temp data reading enables
					TEMPenable = 1;
					usart_transmit("Temperature readings enabled.\n");
					ReadingEnables = ReadingEnables % 10 ;
				} else {
					TEMPenable = 0;
					usart_transmit("Temperature readings disabled.\n");
					ReadingEnables = ReadingEnables % 10 ;
				}
				if (ReadingEnables != 0) { // LSB for light sensor data enables
					BRenbale = 1;
					usart_transmit("Light Sensor enabled.\n");
				} else {
					BRenbale = 0;
					usart_transmit("Light Sensor disabled.\n");
				}
			}
			// echo the command back to the screen
			sprintf(echo, "Interval set: %d Hour, %d Minute, %d Second.\n ", hour, minute, sec);
			usart_transmit(echo);
			changed = 1;
			// hold if still pressed
			while((PIND&(1<<PIND2)) == 0);
			pressed = 0;
		} else { // if command is invalid
			usart_transmit("Old settings used\n");
			sprintf(echo, "Interval set: %d Hour, %d Minute, %d Second.\n ", hour, minute, sec);
			usart_transmit(echo);
			if (ReadingEnables == 0) { 
				usart_transmit("Warning: No readings enabled.\n");
				} else {
				if ((ReadingEnables / 100) != 0) {
					RHenable = 1;
					usart_transmit("Humidity readings enabled.\n");
					ReadingEnables = ReadingEnables % 100;
					} else {
					RHenable = 0;
					usart_transmit("Humidity readings disabled.\n");
					ReadingEnables = ReadingEnables % 100;
				}
				if ((ReadingEnables / 10) != 0) {
					TEMPenable = 1;
					usart_transmit("Temperature readings enabled.\n");
					ReadingEnables = ReadingEnables % 10 ;
					} else {
					TEMPenable = 0;
					usart_transmit("Temperature readings disabled.\n");
					ReadingEnables = ReadingEnables % 10 ;
				}
				if (ReadingEnables != 0) {
					BRenbale = 1;
					usart_transmit("Light Sensor enabled.\n");
					} else {
					BRenbale = 0;
					usart_transmit("Light Sensor disabled.\n");
				}
			}
			changed = 1;
			// hold if still pressed
			while((PIND&(1<<PIND2)) == 0);
			pressed = 0;
		}
	}
} 

		
int main(void)
{	
	// holding string output
	char outstr[100];
	// initialize usart
	usart_init();
	// initialize ADC
	ADC_init();
	// PC3 output buffer set to 0
	PORTC &= ~(1<<3);
	// PD2 to input PBS
	DDRD = 0;
	PORTD = 0x04;
	// setup interrupt
	EICRA = 2; // falling edge on INT0
	EIMSK = 1; 
	sei();
	usart_transmit("Default sampling time: 5sec.\n");
	usart_transmit("All readings enabled by default.\n");
	sprintf(outstr, "Interval set: %d Hour, %d Minute, %d Second.\n ", hour, minute, sec);
	usart_transmit(outstr);
	while(1) {
		if (TEMPenable == 1 || RHenable == 1) {
			readDHT();
			displayDHT(outstr);
		}
		if (BRenbale == 1) {
			readBrightness();
			displayBrightness();
		}
		delayOverall();
	}
}



void usart_init() {
	// Set baud rate
	UBRR0H = (unsigned char)(UBRR_VALUE>>8);
	UBRR0L = (unsigned char)UBRR_VALUE;
	// Set frame format to 8 data bits, no parity, 1 stop bit
	UCSR0C |= (1<<UCSZ01)|(1<<UCSZ00);
	//enable transmission and reception, enable receive interrupt
	UCSR0B |= (1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0);
	
}

unsigned char usart_receives() {
	// Wait for byte to be received
	while(!(UCSR0A&(1<<RXC0))){};
	// Return received data
	return UDR0; // get char from buffer
}

void usart_transmit(char arr[]) {
	// Uses polling (and it blocks). 
	int j;
	for (j = 0; j <= strlen(arr)-1; j++) {
		while (!( UCSR0A & (1<<UDRE0))) {}; // until buffer empty
		UDR0 = arr[j]; // put the char to the buffer
	}
}

void readDHT() {
	uint8_t DHTbyte = 0;
	
	DDRC |= 1<<3; // set PC3 as output
	_delay_ms(18.0); // delay for 18ms to initiate the DHT
	DDRC &= ~(1<<3); // set PC3 as input

	while(  (PINC&(1<<PINC3)) != 8 ) ; // while still rising
	while(PINC&(1<<PINC3)) ; // while rised  
	while( (PINC&(1<<PINC3)) != 8 ) ; // while 0 at start
	while(PINC&(1<<PINC3)) ; // while 1 at start
	
	int received = 0; // number of bytes decoded
	int counter = 0; // number of bits decoded
	while(1) { // start decoding
		while((PINC&(1<<PINC3)) != 8 ) ; // while in gap
		_delay_us(35.0); // delay for 35 us  
		if (PINC&(1<<PINC3)) { // still 1   
			DHTbyte |= 1 << (7 - counter);
			while(PINC&(1<<PINC3)) ; // wait till gap 
		} 
		counter++;
		if (counter == 8) { // one byte complete
			DHTresult[received] = DHTbyte;
			DHTbyte = 0;
			counter = 0;
			received++; 
		}
		if (received == 5) { // all five bytes completed
			break;
		}
	}	
		
}


void ADC_init() {
	ADMUX = (1 << REFS0); //  AVCC with external capacitor at AREF pin
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // enable ADC and set prescalar to /128
}

void readBrightness() { //function to get the brightness (0-1023)
	ADCSRA |= 1 << ADSC; // start conversion
	while (ADCSRA & (1 << ADSC)) { // until finished conversion
	}
	
	uint16_t digitalV = ADC;  // get ADC reading
	//char temp[20];
	//sprintf(temp, "%d", digitalV);
	//usart_transmit(temp);
	brightness = digitalV; 
}

void displayBrightness() { // will display brightness
	if (BRenbale == 1) {
		char outstr[30];
		sprintf(outstr, "brightness = %d\n", brightness);
		usart_transmit(outstr);
		LightnessOutside();
	}
}

void LightnessOutside() { // will display message based on brightness
	if(brightness < 100){
		usart_transmit("Its night time\n");
	}
	else if(brightness > 100 && brightness < 300){
		usart_transmit("Its sunrise or dusk\n");
	}
	else if(brightness > 300 && brightness < 700){
		usart_transmit("Partially cloudy\n");
	}
	else{
		usart_transmit("The sun it out and shinning\n");
	}
}

void displayDHT(char outstr[]) {
	// check if result is valid (checksum digit)
	if (DHTresult[4] != (DHTresult[0] + DHTresult[1] + DHTresult[2] + DHTresult[3])) { 
		usart_transmit("INTERFERENCE WITH DHT READING\n");
	} else {
		if (RHenable == 1) {
			sprintf(outstr, "RH: %d.%d%% \n ", DHTresult[0], DHTresult[1]);
			usart_transmit(outstr);
		} 
		if (TEMPenable == 1) {
			sprintf(outstr, "Temp(Celsius): %d.%d \n", DHTresult[2], DHTresult[3]);
			usart_transmit(outstr);
			displayTemp();
		}
	}
}

void displayTemp(){ //will display a message a based on DHT
	if (DHTresult[2]< 0) {
		usart_transmit("BRRRR its very cold out\n");
	}
	else if(DHTresult[2]> 0 && DHTresult[2] < 11){
		usart_transmit("A light jacket would be advised\n");
	}
	else if(DHTresult[2] > 11 && DHTresult[2] < 20){
		usart_transmit("no need for a jacket enjoy the weather\n");
	}
	else if (DHTresult[2]> 20 && DHTresult[2] < 30){
		usart_transmit("shorts and t-shirt weather\n");
	} else {
		usart_transmit("HOT, stay hydrated\n");
	}
}

void delayOverall () { //delay function (timer)
	int s = 0;
	int m = 0;
	int h = 0;
	s = sec;
	m = minute;
	h = hour;
	// sec
	while (s > 0) {
		_delay_ms(1000); // delay 1s
		s--;
		if (changed) {
			changed = 0;
			return;
		}
	}
	// min
	while (m > 0) {
		for (int i = 0; i < 60; i++) {
			_delay_ms(1000);
			if (changed) {
				changed = 0;
				return;
			}
		}
		m--;
	}
	// hour 
	while (h > 0) {
		for (int i = 0; i < 3600; i++) {
			_delay_ms(1000);
			if (changed) {
				changed = 0;
				return;
			}
		}
		h--;
	}
}

void debounce() { // PBS debounce
	int counts = 0;
	for (int i = 0; i < 9; i++) {
		if ((PIND&(1<<PIND2)) == 0) {
			counts++;
		}
		_delay_ms(10.0);
	}
	if (counts >= 5) {
		pressed = 1;
	} else {
		pressed = 0;
	}
}