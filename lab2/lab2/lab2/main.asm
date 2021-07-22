;
; lab2.asm
;
; Created: 2/19/2021 11:06:01 AM
; Author : Hongyzeng
;
.include "m328Pdef.inc"
.cseg
.org 0

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
.equ TEN = 0b10111111
.equ ELEVEN = 0b10000110
.equ TWELVE = 0b11010011
.equ THIRTEEN = 0b11001111
.equ FOURTEEN = 0b11100110
.equ FIFTEEN = 0b11101101
.equ SIXTEEN = 0b11111101
.equ SEVENTEEN = 0b10000111
.equ EIGHTEEN = 0b11111111
.equ NINETEEN = 0b11101111


sbi DDRB, 0; -- 8,PB0 RCLK
sbi DDRB, 1; -- 9,PB1 SER
sbi DDRB, 2; -- 10,PB2 SRCLK
cbi DDRB, 3; -- 11,PB3 Inc Button
cbi DDRB, 4; -- 12,PB4 Dec Button
sbi PORTB, 3;
sbi PORTB, 4;               
	
in R21, PINB
ldi R16, ZERO
ldi R22, 0
ldi R29, 0b000000000  ; 0 means not pressed


main:
	rcall display ; call display subroutine
	rcall button_check
	rjmp main
		

button_check:
	ldi R17, 9
	ldi R26, 0 ; inc
	ldi R27, 0 ; dec
	
debounce:
	in R21, PINB
	SBRS R21, 3
	inc R26
	SBRS R21, 4
	inc R27
	rcall delay_short
	dec R17
	brne debounce
	subi R26, 4 ; pressed state
	brpl maybeincrease
	andi R29, 0b01111111
	subi R27, 4
	brpl maybedecrease
	andi R29, 0b10111111
	ret


maybeincrease:
	SBRS R29, 7 ; if previous state is also pressed the skip
	rjmp maybeincreasehelper
	ret

maybeincreasehelper:
	cpi R22, 19
	brne dginc
	ret

dginc:
	ori R29, 0b10000000
	inc R22
	rjmp load_pattern
	ret


maybedecrease:
	SBRS R29, 6 ; if the bit is 1 (pressed then skip)
	rcall maybedecreasehelper
	ret

maybedecreasehelper:
	cpi R22, 0
	brne dgdec
	ret

dgdec:
	ori R29, 0b01000000
	dec R22
	rcall load_pattern
	ret





load_pattern:
	cpi R22, 0
	brne on
	ldi R16, ZERO
	ret
on:
	cpi R22, 1
	brne tw
	ldi R16, ONE
	ret
tw:
	cpi R22, 2
	brne th
	ldi R16, TWO
	ret
th:
	cpi R22, 3
	brne fo
	ldi R16, THREE
	ret
fo:
	cpi R22, 4
	brne fi
	ldi R16, FOUR
	ret
fi:
	cpi R22, 5
	brne si
	ldi R16, FIVE
	ret'
si:
	cpi R22, 6
	brne seve
	ldi R16, SIX
	ret
seve:
	cpi R22, 7
	brne ei
	ldi R16, SEVEN
	ret
ei:
	cpi R22, 8
	brne ni
	ldi R16, EIGHT
	ret
ni:
	cpi R22, 9
	brne te
	ldi R16, NINE
	ret
te:
	cpi R22, 10
	brne ele
	ldi R16, TEN
	ret
ele:
	cpi R22, 11
	brne twel
	ldi R16, ELEVEN
	ret
twel:
	cpi R22, 12
	brne tht
	ldi R16, TWELVE
	ret
tht:
	cpi R22, 13
	brne fot
	ldi R16, THIRTEEN
	ret
fot:
	cpi R22, 14
	brne fift
	ldi R16, FOURTEEN
	ret
fift:
	cpi R22, 15
	brne sixt
	ldi R16, FIFTEEN
	ret
sixt:
	cpi R22, 16
	brne sevent
	ldi R16, SIXTEEN
	ret
sevent:
	cpi R22, 17
	brne eit
	ldi R16, SEVENTEEN
	ret
eit:
	cpi R22, 18
	brne nit
	ldi R16, EIGHTEEN
	ret
nit:
	ldi R16, NINETEEN
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

;0.3212 s
delay_long:
		ldi   r23,38      ; r23 <-- Counter for outer loop
	d1: ldi   r24,183     ; r24 <-- Counter for level 2 loop
	d2: ldi   r25,184     ; r25 <-- Counter for inner loop
	d3: dec   r25
		nop               ; no operation
		brne  d3
		dec   r24
		brne  d2
		dec   r23
		nop
		nop
		brne  d1
		ret

; modify to 10 ms
delay_short:
		ldi   r23, 133      ; r23 <-- Counter for outer loop
	d4: ldi   r24, 11     ; r24 <-- Counter for level 2 loop
	d5: ldi   r25, 35     ; r25 <-- Counter for inner loop
	d6: dec   r25
		brne  d6
		dec   r24
		brne  d5
		dec   r23
		brne  d4
		ret
.exit           