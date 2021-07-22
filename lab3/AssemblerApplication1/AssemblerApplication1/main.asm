;
; AssemblerApplication1.asm
;
; Created: 3/11/2021 2:42:53 PM
; Author : hongyzeng, Ethan, group 20
; Password: A678

.include "m328Pdef.inc"
.equ MBAR = 0b01000000
.equ LBAR = 0b00001000
.equ ZERO  = 0b00111111
.equ ONE = 0b00000110
.equ TWO = 0b01011011
.equ THREE = 0b01001111
.equ FOUR = 0b01100110
.equ FIVE = 0b01101101
.equ SIX = 0b01111101
.equ SEVEN = 0b00000111
.equ EIGHT = 0b01111111
.equ NINE = 0b01101111
.equ CHARA = 0b01110111
.equ CHARB = 0b01111100
.equ CHARC = 0b00111001
.equ CHARD = 0b01011110
.equ CHARE = 0b01111001
.equ CHARF = 0b01110001
.def first = r18
.def second = r19
.def third = r20
.def fourth = r21

.cseg
.org 0
sbi DDRB, 0; -- 8,PB0 RCLK
sbi DDRB, 1; -- 9,PB1 SER
sbi DDRB, 2; -- 10,PB2 SRCLK
cbi DDRB, 3; -- 11,PB3 Button
sbi DDRB, 5; -- yellow LED
cbi PORTB, 5
sbi PORTB, 3;
cbi DDRD, 7; -- 7, PD7, B 
cbi DDRD, 6; -- 6, PD6, A
sbi PORTD, 7; B
sbi PORTD, 6; A

ldi r23, 0x02 ; /8 normal
out TCCR0B, r23 ;
; r16 for bitmap
; r17 for decimal value for digit
; r18-r21 storing input
; r22 store the reg num to memorize next code; read pinD
; r23 temp: sample times -> 
; r24 temp: 
; r25 temp: 
; r26 r27 debounce counter
; r28 input counter
; r29 state holder
; r30 r31 delay temp 

; start by default
start: ; goes right to digit_sel
	cbi PORTB, 5 ; turn off led
; bit 7 is button pressed
; bit 5: is 1 when digit_sel
; bit 3 is 1 when ccw, bit 2 is 1 when cw

	ldi r29, 0b00000000
	ldi r22, 18
	ldi r28, 0 ; number of digit inputed (button pushed)
	ldi r17, 16 ; decimal value for digit being displayed, 16 for midder bar and 17 for lower bar
	rcall load_pattern ; load R16 with correct bit map for "-"
	rcall display; display "-"
	sbr r29, 0b00100000 ; change state 0b00100000

digit_sel: 
	;only executed when detent, else then looping in rotating
	andi r29, 0b00100000 ; reset rotation direction,  0b00100000
	rcall debounce ; get value from PIND
	sbrs r25, 6 ; don't skip if A active low
	rcall rotating 
	sbrc r29, 2 ; if cw
	rjmp aftercycle
	sbrs r25, 7 ; B active
	rcall rotating
aftercycle:
	rcall display
	rcall buttonCheck
	rcall checkInputFull 
	sbrc r29, 5 ; if full
	rjmp digit_sel
	rjmp codeCheck1

rotating:
	;determine direction
	sbrs r25, 6
	ori  r29, 0b00000100 ; clockwise 0b00100100
	sbrs r25, 7 
	ori r29, 0b00001000 ; ccw , 0b00101000
;	.set count = 3 ; 
;	ldi r30, low(count)
;	ldi r31, high(count)
rotating_helper: ; loop till detent	
;	rcall delay ; delay for 2.5 ms
	rcall debounce ; reads the value
	cpi r25, 0b11000000 ; compare to detent
	brne rotating_helper ; incpmlete cycle
	sbrc r29, 2 ;don't skip if cw
	rcall maybeincrease
	sbrc r29, 3 ; if cww
	rcall maybedecrease
	ret


debounce: ; get value for A B, storing in r25
	push r22
	ldi r23, 9 ; reset sample counter
	ldi r26, 0
	ldi r27, 0
	ldi r25, 0b11000000 ; load initial value 
debounce_loop:
	in r22, PIND
	sbrs r22, 6
	inc r26 ; number of times A is active 0
	sbrs r22, 7
	inc r27 
	rcall delay_100us_TC0
	dec r23
	brne debounce_loop
	subi r26, 4
	brpl A_on
	rjmp B
A_on:
	andi r25, 0b10111111
B:	subi r27, 4
	brpl B_on
	rjmp debounce_done
B_on:
	andi r25, 0b01111111
debounce_done:
	pop r22
	ret

maybeincrease:
	cpi r17, 16
	breq changeto0 ; if middle bar then change to 0
	rjmp maybeincreaseH ; if not middle bar then increase as usual
changeto0:
	ldi r17, 0
	rcall load_pattern
	ret
maybeincreaseH:
	cpi r17, 15
	brne dginc
	ret
dginc:
	inc r17
	rjmp load_pattern
	ret
maybedecrease:
	cpi r17, 0
	brne dgdec
	ret
dgdec:
	dec r17
	rcall load_pattern
	ret

buttonDeb: ; if pressed, set r29 bit 7 to 1, else 0
	push r22
	ldi r23, 9 ; reset sample counter
	ldi r26, 0 ; 
bDeb_loop:
	in r22, PINB
	sbrs r22, 3
	inc r26 ; number of times button is pressed
	rcall delay_100us_TC0
	dec r23
	brne bDeb_loop
	subi r26, 4
	brpl setbuttonP
	andi r29, 0b01111111 ; set to not pressed if less than 5
	rjmp bDeb_done
setbuttonP:
	ori r29, 0b10000000 ; set to pressed if more than 5
bDeb_done:
	pop r22
	ret
	

buttonCheck: ; exit only not pressing
	rcall buttonDeb ; get the value of button
	sbrs r29, 7 ; return to digit_sel if not pressed
	ret 
	.set count = 3000 ; 
	ldi r30, low(count)
	ldi r31, high(count)
button_pressed:
	rcall buttonDeb ; 0.9 ms + someother loop so 1ms
	sbrc r29, 7
	sbiw Z, 1
	breq reset_code
	sbrc r29, 7
	rjmp button_pressed
	subi r31, 0b00000111
	brsh memorize_code
	ret ; to digit_sel

reset_code:
	ldi r28, 0 
	ldi r22, 18 ; reset which register for storing next code
	ldi r17, 16
	rcall load_pattern
	rcall display
reset_loop: ; reenter the digit_sel only if the button is released
	rcall buttonDeb ; 0.9 ms + someother loop so 1ms
	sbrc r29, 7
	rjmp reset_loop
	ret

memorize_code:
rc1:
	cpi r22, 18
	brne rc2
	mov first, r16 ; memory the bit map
	inc r22
	inc r28
	ret
rc2:
	cpi r22, 19
	brne rc3
	mov second, r16 ; memory the bit map
	inc r22
	inc r28
	ret
rc3:
	cpi r22, 20
	brne rc4
	mov third, r16 ; memory the bit map
	inc r22
	inc r28
	ret
rc4:
	mov fourth, r16 ; memory the bit map
	inc r22
	inc r28
	ret

checkInputFull: ; clear 5th bit in r29 if full
	cpi r28, 4
	breq full
	ret

full:
	andi r29, 0b11011111
	ret

codeCheck1:
	; determine if the password is correct
	cpi r18, CHARA
	breq codeCheck2
	rjmp incorrectState

codeCheck2:
	cpi r19, SIX
	breq codeCheck3
	rjmp incorrectState

codeCheck3:
	cpi r20, SEVEN
	breq codeCheck4
	rjmp incorrectState

codeCheck4:
	cpi r21, EIGHT
	breq correctState
	rjmp incorrectState

correctState:
	;light up yellow LED
	sbi PORTB, 5
	.set count = 5000 ; 5s
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay_long
	rjmp start

incorrectState:
	; display lowb
	ldi r17, 17
	ldi r16, LBAR
	rcall display ; lower bar
	.set count = 12000 ; 12s in delay long
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay_long
	rjmp start
	
load_pattern:
mb: cpi r17, 16
	brne zo
	ldi R16, MBAR
	ret
zo:	cpi r17, 0
	brne on
	ldi R16, ZERO
	ret
on:
	cpi r17, 1
	brne tw
	ldi R16, ONE
	ret
tw:
	cpi r17, 2
	brne th
	ldi R16, TWO
	ret
th:
	cpi r17, 3
	brne fo
	ldi R16, THREE
	ret
fo:
	cpi r17, 4
	brne fi
	ldi R16, FOUR
	ret
fi:
	cpi r17, 5
	brne si
	ldi R16, FIVE
	ret'
si:
	cpi r17, 6
	brne seve
	ldi R16, SIX
	ret
seve:
	cpi r17, 7
	brne ei
	ldi R16, SEVEN
	ret
ei:
	cpi r17, 8
	brne ni
	ldi R16, EIGHT
	ret
ni:
	cpi r17, 9
	brne ca
	ldi R16, NINE
	ret
ca:
	cpi r17, 10
	brne cb
	ldi R16, CHARA
	ret
cb:
	cpi r17, 11
	brne cc
	ldi R16, CHARB
	ret
cc:
	cpi r17, 12
	brne cd
	ldi R16, CHARC
	ret
cd:
	cpi r17, 13
	brne ce
	ldi R16, CHARD
	ret
ce:
	cpi r17, 14
	brne cf
	ldi R16, CHARE
	ret
cf:
	cpi r17, 15
	brne lowb
	ldi R16, CHARF
	ret
lowb:
	ldi R16, LBAR
	ret

display: ; backup used registers on stack
 	push R16
	push R17
	in R17, SREG             
	push R17

	ldi R17, 8 ; loop --> test all 8 bits
loop:
	rol R16 ; rotate left trough Carry
	BRCS set_ser_in_1 ; branch if Carry is set
	; put code here to set SER to 0...
	cbi PORTB,1;
	rjmp end

set_ser_in_1:
	; put code here to set SER to 1...
	sbi PORTB,1;

end:
	; put code here to generate SRCLK pulse...
	sbi PORTB,2;
	cbi PORTB,2;
	dec R17 
	brne loop
	; put code here to generate RCLK pulse...
	sbi PORTB,0;
	cbi PORTB,0;

	; restore registers from stack
	pop R17
	out SREG, R17
	pop R17
 	pop R16
	ret


delay: ; based on Z (r31 r30) value, delay for Z times 100us. 50000 for 5s, 12000 for 12 s
	rcall delay_100us_TC0
	sbiw Z, 1 ;R30, R31 16 bit loop
	brne delay
	ret
delay_100us_TC0: ; store r23, r24 to stack and reuse them
	push r23	
	push r24
	;stop timer
	in r23, TCCR0B ; save config
	ldi r24, 0x00 ; stop timer
	out TCCR0B, r24 ; 
	; clear overflow flag
	in r24, TIFR0 
	sbr r24, 1<<TOV0 ; clear TOV0, write logic 1
	; set count
	out TIFR0, r24
	ldi r24, 56
	;start timer with new initial count
	out TCNT0, r24 ; load counter
	out TCCR0B, r23 ; restart timer
wait:
	in r24, TIFR0 ; 
	sbrs r24, TOV0 ; check overflow, if overflow then skip
	rjmp wait 
	pop r24
	pop r23
	ret


delay_long:
	rcall delay_oms
	sbiw Z, 1
	brne delay_long
	ret
delay_oms:
	push r28
	ldi r28, 10
oms_loop:
	rcall delay_100us_TC0
	dec r28
	brne oms_loop
	pop r28
	ret	