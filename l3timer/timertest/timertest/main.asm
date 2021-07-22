;
; timertest.asm
;
; Created: 3/22/2021 2:44:18 PM
; Author : zdszy
;


; Replace with your application code
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


.cseg
.org 0


ldi r23, 0x02 ; /64 normal
out TCCR0B, r23 ;
ldi r30, 0
ldi r31, 0

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
	rcall delay_100us_TC0
	.set count = 5 ; 5s
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay_long\
	.set count = 5 ; 5s
	ldi r30, low(count)
	ldi r31, high(count)
	rcall delay
	rjmp start
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
