;
; Lab4.asm
;
; Created: 3/27/2021 11:31:09 PM
; Author : Hongy Zeng, Louis M Solovy
;

.include "m328Pdef.inc"
;***** Subroutine Register Variables
.def	drem16uL=r14
.def	drem16uH=r15
.def	dd16uL	=r16
.def	dd16uH	=r17
.def	dv16uL	=r18
.def	dv16uH	=r19

.cseg
.org 0x0000
	rjmp start

.org 0x0006 ; button 
	rjmp button

.org 0x0008 ; A
	rjmp rpg
.org 0x000A ; B
	rjmp rpg
.org 0x0034
;LCDstr:.db 0x33,0x32,0x28,0x01,0x0c,0x06
;ldi r26, low(LCDstr) 
;ldi r27, high(LCDstr)
msg1: .db "DC = ", 0x00
msg2: .db "(%)", 0x00
msg3: .db "LEDs:", 0x00
msg4: .db "ON ",0x00 
msg5: .db "OFF", 0x00
; PB5 -> RS
; PB3 -> ENABLE
; PB0 -> BUTTON PCINT0
; PD7 -> CHANNEL B PCINT23
; PC5 -> CHANNEL A PCINT13
; PC0 -> D4
; PC1 -> D5
; PC2 -> D6
; PC3 -> D7
; PD3 -> PWM OC2B

start:
; set up I/O
ldi r16, (1<<DDB5) | (1<<DDB3)
out DDRB, r16
ldi r16, (1<<DDC3) | (1<<DDC2) | (1<<DDC1) | (1<<DDC0) 
out DDRC, r16
ldi r16, (1<<DDD3)
out DDRD, r16
ldi r16, 0x01
out PORTB, r16 ; PORTB0-2 set to high
ldi r16, 0b00100000
out PORTC, r16
ldi r16, 0b10000000
out PORTD, r16
; setup interrupt
ldi r16, 0b00000111
sts PCICR, r16
ldi r16, 0x01
sts PCMSK0, r16
ldi r16, 0b00100000
sts PCMSK1, r16
ldi r16, 0b10000000
sts PCMSK2, r16




;set up TC2 and OCR2B
ldi r16, 0b00100011 ; set to noninvert OC2B, fast PWM with threshold as OCR2B
sts TCCR2A, r16
ldi r16, 0b00000010 ; /8 
sts TCCR2B, r16 ; cannot use out as out of range
ldi r16, 127 ; when OCR2B match , controls DC
sts OCR2B, r16

rcall initialization
.set dcval = 500 ; controls the digits for DC display
ldi r28, low(dcval)
ldi r29, high(dcval)
ldi r19, 0b10000000 ; bit 7 for if LED should be on, 6 is button pressed , 3 for ccw, 2 for cw, 1 for reaching upper limit
main:
	sei 
	rcall display
refresh:
	rjmp refresh

display:
	; display 1st line
	ldi r30,LOW(2*msg1) ; Load Z register low
	ldi r31,HIGH(2*msg1) ; Load Z register high
	rcall displayCString
	
	;display DC
	rcall displayDC

	; display %
	ldi r30, low(2*msg2)
	ldi r31, high(2*msg2)
	rcall displayCString

	; move cursor to second line
	ldi r20, 0x0C
	out PORTC, r20
	rcall LCDStrobe
	rcall delay_100us
	ldi r20, 0x00
	out PORTC, r20
	rcall LCDStrobe
	rcall delay_100us	

	ldi r30,LOW(2*msg3) ; Load Z register low
	ldi r31,HIGH(2*msg3) ; Load Z register high
	rcall displayCString

	rcall displayONF
	ret

initialization: ; Z overwritten
	push r20
; 8 bit mode
	cbi PORTB, 5 ; RS = 0 , commands 
	.set count = 1000
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay ; delay 100ms

	ldi r20, 0x03
	out PORTC, r20
	rcall LCDStrobe
	.set count = 50
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay ; 5ms

	ldi r20, 0x03
	out PORTC, r20
	rcall LCDStrobe
	rcall delay_100us
	rcall delay_100us ; 200us

	ldi r20, 0x03
	out PORTC, r20
	rcall LCDStrobe
	rcall delay_100us
	rcall delay_100us ; 200us

	ldi r20, 0x02
	out PORTC, r20
	rcall LCDStrobe
	.set count = 50
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay ; 5ms 

; 4bit mode
	ldi r20, 0x02
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay ; 1.7ms
	ldi r20, 0x08
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay 

	ldi r20, 0x00
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay
	ldi r20, 0x08
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay

	ldi r20, 0x00
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay
	ldi r20, 0x01
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay

	ldi r20, 0x00
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay
	ldi r20, 0x06
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay

	ldi r20, 0x00
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay
	ldi r20, 0x0C
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay

	pop r20
	ret


displayCString: ; modify r0
	sbi PORTB, 5
	lpm r0, Z+ ; r0 <-- first byte
	tst r0 ; Reached end of message ?
	breq done ; Yes => quit
	swap r0 ; Upper nibble in place
	out PORTC,r0 ; Send upper nibble out
	rcall LCDStrobe ; Latch nibble '
	rcall delay_100us
	swap r0 ; Lower nibble in place
	out PORTC,r0 ; Send lower nibble out
	rcall LCDStrobe ; Latch nibble
	rcall delay_100us
	rjmp displayCstring
done:
	cbi PORTB, 5
	ret

displayDstring: ; modify r0  
	sbi PORTB, 5   
	ld r0,Z+
	tst r0 ; Reached end of message ?
	breq done_dsd ; Yes => quit
	swap r0 ; Upper nibble in place
	out PORTC,r0 ; Send upper nibble out
	rcall LCDStrobe ; Latch nibble 
	rcall delay_100us
	swap r0 ; Lower nibble in place
	out PORTC,r0 ; Send lower nibble out
	rcall LCDStrobe ; Latch nibble
	rcall delay_100us
	rjmp displayDString
done_dsd:
	cbi PORTB, 5
	ret

LCDStrobe:
	sbi PORTB, 3
	nop
	nop
	nop
	nop
	cbi PORTB, 3
	ret
displayONF:
	sbrc r19, 7
	rjmp displayON
	rjmp displayOFF

displayON:
	ldi r30,LOW(2*msg4) ; Load Z register low
	ldi r31,HIGH(2*msg4) ; Load Z register high
	rcall displayCString
	ret

displayOFF:
	ldi r30,LOW(2*msg5) ; Load Z register low
	ldi r31,HIGH(2*msg5) ; Load Z register high
	rcall displayCString
	ret
displayDC:
.dseg
	dtxt: .BYTE 6 ; Allocation

.cseg
	push r14
	push r15
	push r16 
	push r17
	push r18
	push r19
	push r30
	push r31
	mov dd16uL,r28 ; LSB of number to display
	mov dd16uH,r29 ; MSB of number to display 

	ldi dv16uL,low(10)
	ldi dv16uH,high(10)
; Store terminating for the string.
	ldi r20,0x00 ; Terminating NULL 
	sts dtxt+5,r20 ; Store in RAM     
; Divide the number by 10 and format remainder.
	rcall div16u ; Result: r17:r16, rem: r15:r14
	ldi r20,0x30
	add r14,r20 ; Convert to ASCII
	sts dtxt+4,r14 ; Store in RAM
; Generate decimal point.
	ldi r20,0x2E ; ASCII code for .
	sts dtxt+3,r20 ; Store in RAM 
; Generate unit
	rcall div16u
	ldi r20,0x30
	add r14, r20
	sts dtxt+2, r14
; Generate tens
	rcall div16u
	ldi r20,0x30
	add r14, r20
	sts dtxt+1, r14

; genearte hundreds
	rcall div16u
	ldi r20,0x30
	add r14, r20
	sts dtxt, r14

	ldi r30, low(dtxt)
	ldi r31, high(dtxt)
	rcall displayDstring

	pop r31
	pop r30
	pop r19
	pop r18
	pop r17
	pop r16
	pop r15
	pop r14
	ret

delay: ; based on Z (r31 r30) value, delay for Z times 100us. 50000 for 5s, 12000 for 12 s
	rcall delay_100us
	sbiw Z, 1 ;R30, R31 16 bit loop
	brne delay
	ret
delay_100us: ; store Z to stack and reuse them
	push r30	
	push r31
	;stop timer
	ldi r31, 0x00 ; stop timer
	out TCCR0B, r31 ; 
	; clear overflow flag
	in r31, TIFR0 
	sbr r31, 1<<TOV0 ; clear TOV0, write logic 1
	; set count
	out TIFR0, r31
	ldi r31, 56
	;start timer with new initial count
	out TCNT0, r31 ; load counter
	ldi r30, 2
	out TCCR0B, r30 ; restart timer/8
wait:
	in r31, TIFR0 ; 
	sbrs r31, TOV0 ; check overflow, if overflow then skip  
	rjmp wait 
	pop r31
	pop r30
	ret


;***************************************************************************
;*
;* "div16u" - 16/16 Bit Unsigned Division
;*
;* This subroutine divides the two 16-bit numbers 
;* "dd8uH:dd8uL" (dividend) and "dv16uH:dv16uL" (divisor). 
;* The result is placed in "dres16uH:dres16uL" and the remainder in
;* "drem16uH:drem16uL".
;*  
;* Number of words	:196 + return
;* Number of cycles	:148/173/196 (Min/Avg/Max)
;* Low registers used	:2 (drem16uL,drem16uH)
;* High registers used  :4 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH)
;*
;***************************************************************************


;***** Code

div16u:	
	clr	drem16uL	;clear remainder Low byte
	sub	drem16uH,drem16uH;clear remainder High byte and carry

	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_1		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_2		;else
d16u_1:	sec			;    set carry to be shifted into result

d16u_2:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_3		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_4		;else
d16u_3:	sec			;    set carry to be shifted into result

d16u_4:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_5		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_6		;else
d16u_5:	sec			;    set carry to be shifted into result

d16u_6:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_7		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_8		;else
d16u_7:	sec			;    set carry to be shifted into result

d16u_8:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_9		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_10		;else
d16u_9:	sec			;    set carry to be shifted into result

d16u_10:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_11		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_12		;else
d16u_11:sec			;    set carry to be shifted into result

d16u_12:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_13		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_14		;else
d16u_13:sec			;    set carry to be shifted into result

d16u_14:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_15		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_16		;else
d16u_15:sec			;    set carry to be shifted into result

d16u_16:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_17		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_18		;else
d16u_17:	sec			;    set carry to be shifted into result

d16u_18:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_19		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_20		;else
d16u_19:sec			;    set carry to be shifted into result

d16u_20:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_21		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_22		;else
d16u_21:sec			;    set carry to be shifted into result

d16u_22:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_23		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_24		;else
d16u_23:sec			;    set carry to be shifted into result

d16u_24:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_25		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_26		;else
d16u_25:sec			;    set carry to be shifted into result

d16u_26:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_27		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_28		;else
d16u_27:sec			;    set carry to be shifted into result

d16u_28:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_29		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_30		;else
d16u_29:sec			;    set carry to be shifted into result

d16u_30:rol	dd16uL		;shift left dividend
	rol	dd16uH
	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_31		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_32		;else
d16u_31:sec			;    set carry to be shifted into result

d16u_32:rol	dd16uL		;shift left dividend
	rol	dd16uH
	ret

buttonDeb: ; if pressed, set r19 bit 6 to 1, else 0
	push r22
	push r23
	push r26
	ldi r23, 9 ; reset sample counter
	ldi r26, 0 ; 
bDeb_loop:
	in r22, PINB
	sbrs r22, 0
	inc r26 ; number of times button is pressed
	rcall delay_100us
	dec r23
	brne bDeb_loop
	subi r26, 4
	brpl setbuttonP
	andi r19, 0b10111111 ; set to not pressed if less than 5
	rjmp bDeb_done
setbuttonP:
	ori r19, 0b01000000 ; set to pressed if more than 5
bDeb_done:
	pop r26
	pop r23
	pop r22
	ret

button:
	rcall buttonDeb
	sbrs r19, 6
	reti
button_pressed:
	rcall buttonDeb ; 0.9 ms + someother loop so 1ms
	sbrc r19, 6
	rjmp button_pressed
	andi r19, 0b10111111 ; button no longer pressed
	sbrs r19, 7 ; don't skip if was light off
	rjmp lighton 
lightoff:
	ldi r20, 0b00000000 ; disconnect OC2B
	sts TCCR2A, r20
	andi r19, 0b01111111
	rcall clearDisplay
	rcall display
	reti
lighton:
	ldi r20, 0b00100011 ; set to noninvert OC2B
	sts TCCR2A, r20
	ori r19, 0b10000000
	rcall clearDisplay
	rcall display
	reti


rpg:
	push r25
	sbrs r19, 7
	rjmp aftercycle
	andi r19, 0b11110011; reset rotating direction
	rcall rpgdebounce
	sbrs r25, 6
	rcall rotating
	sbrc r29, 2
	rjmp aftercycle
	sbrs r25, 7
	rcall rotating
aftercycle:
	rcall clearDisplay
	rcall display
	pop r25
	reti


rpgdebounce:
	push r22
	push r23
	push r26
	push r27
	ldi r23, 9 ; reset sample counter
	ldi r26, 0
	ldi r27, 0
	ldi r25, 0b11000000 ; load initial value 
rpgdebounce_loop:
	in r22, PINC
	sbrs r22, 5
	inc r26 ; number of times A is active 0
	in r22, PIND
	sbrs r22, 7
	inc r27 
	rcall delay_100us
	dec r23
	brne rpgdebounce_loop
	subi r26, 4    
	brpl A_on
	rjmp B
A_on:
	andi r25, 0b10111111
B:	subi r27, 4
	brpl B_on
	rjmp rpgdebounce_done
B_on:
	andi r25, 0b01111111
rpgdebounce_done:
	pop r27
	pop r26
	pop r23
	pop r22
	ret


rotating:
	;determine direction
	sbrs r25, 6
	ori  r19, 0b00000100 ; clockwise
	sbrs r25, 7 
	ori r19, 0b00001000 ; ccw 
rotating_helper: ; loop till detent	
	rcall rpgdebounce ; reads the value
	cpi r25, 0b11000000 ; compare to detent
	brne rotating_helper ; incpmlete cycle
	sbrc r19, 2 ;don't skip if cw
	rcall maybeincrease
	sbrc r19, 3 ; if cww
	rcall maybedecrease
	ret


maybeincrease:     ;       
	cpi r16, 255
	brne maybeincreaseH
	ret
maybeincreaseH:
	cpi r16, 244            
	breq totop
	cpi r16, 13
	breq incto23
	ldi r20, 13
	add r16, r20
	sts OCR2B, r16
	rcall incDC
	ret
totop:
	ldi r16, 255
	sts OCR2B, r16
	ori r19, 0b00000010
	rcall incDC
	ret
incto23:
	ldi r16, 23
	sts OCR2B, r16
	rcall incDC
	ret

maybedecrease:
	cpi r16, 13
	brne maybedecreaseH
	ret
maybedecreaseH:
	cpi r16, 23
	breq tobottom
	cpi r16, 255
	breq decto244
	subi r16, 13
	sts OCR2B, r16
	rcall decDC
	ret
tobottom:
	ldi r16, 13
	sts OCR2B, r16
	rcall decDC
	ret
decto244:
	ldi r16, 244
	andi r19, 0b11111101
	sts OCR2B, r16
	rcall decDC
	ret

incDC:
	adiw Y, 50;
	ret
decDC:
	sbiw Y, 50;
	ret


clearDisplay:
	push r20
	push r30
	push r31
	ldi r20, 0x00
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay
	ldi r20, 0x01
	out PORTC, r20
	rcall LCDStrobe
	.set count = 17
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay
	pop r31
	pop r30
	pop r20
	ret