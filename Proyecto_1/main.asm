//***************************************************************************
// Universidad del Valle de Guatemala
// IE2023: Programación de Microcontroladores
// Autor: Ruben Granados
// Proyecto: Proyecto 1
// Hardware: ATMEGA328P
// Created: 22/03/2024
//***************************************************************************
// Proyecto 1
//***************************************************************************
.include "M328PDEF.inc"
.cseg
.def cont500ms = R18		; puede ser variable
.def cont1s = R19
.def estado = R20
;.def valorz = R27
.def useg = R21
.def dseg = R22
.def umin = R23
.def dmin = R24
.def uhor = R25
;.def dhor = R26
.def udia = R0
.def ddia = R1
.def umes = R2
.def dmes = R3
.def uamin = R4
.def damin = R5
.def uahor = R6
.def dahor = R7

.org 0x00
	jmp MAIN		; vector principal

.org 0x0006
	jmp ISR_PCINT0	; vector interrupción

.org 0x0020			; vector TIMER0
	jmp ISR_TIMER0_OVF
//***************************************************************************
// MAIN
//***************************************************************************
MAIN:
;Stack
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R17, HIGH(RAMEND)
	OUT SPH, R17

//***************************************************************************
// LISTA DE VALORES PARA DISPLAY
//***************************************************************************
T7S: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x39,0x71,0x76,0x37,0x06

//***************************************************************************
// SETUP
//***************************************************************************
SETUP:	
	
;INPUTS
	sbi PORTB, PB0
	cbi DDRB, PB0
	sbi PORTB, PB1
	cbi DDRB, PB1
	sbi PORTB, PB2
	cbi DDRB, PB2
;OUTPUT
	ldi R16, 0xFF		; display
	out DDRC, R16
	sbi DDRB, PB4		; g
	cbi PORTB, PB4
	
	sbi DDRB, PB3		; DD :
	cbi PORTB, PB3
	
	sbi DDRB, PB5		; alarma
	cbi PORTB, PB5
;OUTPUT TRANSISTORS
	ldi R16, 0xFF
	out DDRD, R16

	call Init_T0		; inicializar Timer0
;INTERRUPCIONES POR PULSADORES
//					PB2			PB1				PB0
	ldi R16, (1 << PCINT2)|(1 << PCINT1)|(1 << PCINT0)
	sts PCMSK0, R16		; habilitar

	ldi R16, (1 << PCIE0)
	sts PCICR, R16		; habilitar

	sei					; habilitar interrupciones globales
	
	clr R27				; valor que obtendrá de la lista 
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z
;valores iniciales
	clr cont500ms
	clr cont1s
	ldi estado, 0
	
	ldi R28, 0b1000_0000
	mov R8, R28

	clr R28
;hora
	ldi R26, 0
	ldi uhor, 0
	ldi dmin, 0 
	ldi umin, 0
	ldi dseg, 0
	ldi useg, 0
;fecha
	ldi R28, 0
	mov ddia, R28
	ldi R28, 1
	mov udia, R28
	
	ldi R28, 0
	mov dmes, R28
	ldi R28, 1
	mov umes, R28
;alarma
	ldi R28, 0
	mov dahor, R28
	ldi R28, 0
	mov uahor, R28

	ldi R28, 0
	mov damin, R28
	ldi R28, 0
	mov uamin, R28

	ldi R29, 0			; ON/OFF alarma

//***************************************************************************
// LOOP
//***************************************************************************
LOOP:
	;call TEST_DISPLAY
	;call TEST_LISTA_DISPLAY
	sbrs estado, 0		; estado bit0 = 1?
	jmp ESTADO_XXX0		; bit0 = 0
	jmp ESTADO_XXX1		; bit0 = 1
	
	rjmp PULSO

//***************************************************************************
// PULSO
//***************************************************************************
PULSO:
	cpi cont500ms, 50
	brne LOOP
	clr cont500ms
;encender o no: DOS PUNTOS
	sbrc R8, 7
	sbi PINB, PB3
	sbrs R8, 7
	cbi PORTB, PB3

	inc cont1s
	cpi cont1s, 2
	brne LOOP
	clr cont1s
; segundos
	ldi R28, 9
	cpse useg, R28
	call INC_USEG
	clr useg

	ldi R28, 5
	cpse dseg, R28
	call INC_DSEG
	clr dseg
; minutos
	ldi R28, 9
	cpse umin, R28
	call INC_UMIN
	clr umin

	ldi R28, 5
	cpse dmin, R28
	call INC_DMIN
	clr dmin

; horas
	ldi R28, 9
	cpse uhor, R28
	call INC_UHOR
	clr uhor

	ldi R28, 2
	cpse R26, R28
	call INC_DHOR
	clr R26

	rjmp LOOP	

//***************************************************************************
// DEFINIR ESTADOS
//***************************************************************************
ESTADO_XXX0:
	sbrs estado, 1
	jmp ESTADO_XX00
	jmp ESTADO_XX10

ESTADO_XX00:
	sbrs estado, 2
	jmp ESTADO_X000
	JMP ESTADO_X100

ESTADO_X000:
	sbrs estado, 3
	jmp ESTADO_0000
	jmp ESTADO_1000

ESTADO_XXX1:
	sbrs estado, 1
	jmp ESTADO_XX01
	jmp ESTADO_XX11

ESTADO_XX01:
	sbrs estado, 2
	jmp ESTADO_X001
	jmp ESTADO_X101
ESTADO_X001:
	sbrs estado, 3
	jmp ESTADO_0001
	jmp ESTADO_1001
ESTADO_XX10:
	sbrs estado, 2
	jmp ESTADO_X010
	jmp ESTADO_X110
ESTADO_X010:
	sbrs estado, 3
	jmp ESTADO_0010
	jmp	ESTADO_1010
ESTADO_XX11:
	sbrs estado, 2
	jmp	ESTADO_X011
	jmp ESTADO_X111
ESTADO_X011:
	sbrs estado, 3
	jmp ESTADO_0011
	jmp ESTADO_1011
ESTADO_X100:
	sbrs estado, 3
	jmp ESTADO_0100
	jmp LOOP
	;jmp ESTADO_1100
ESTADO_X101:
	sbrs estado, 3
	jmp ESTADO_0101
	;jmp ESTADO_1101
ESTADO_X110:
	sbrs estado, 3
	jmp ESTADO_0110
	;jmp ESTADO_1110
ESTADO_X111:
	sbrs estado, 3
	jmp ESTADO_0111
	;jmp ESTADO_1111

//***************************************************************************
// ESTADOS
//***************************************************************************
;                                     0000
ESTADO_0000:
	ldi R28, 0b1000_0000
	mov R8, R28
	;ldi useg, 0
	call USEG_DISPLAY
	call DSEG_DISPLAY
	call UMIN_DISPLAY
	call DMIN_DISPLAY
	call UHOR_DISPLAY
	call DHOR_DISPLAY

	sbrs R29, 0
	cbi PORTB, PB5
	sbrc R29, 0
	call ALARMA

	rjmp PULSO
	jmp LOOP
;                                     0001
ESTADO_0001:
	clr R8
	call UDIA_DISPLAY
	call DDIA_DISPLAY
	call UMES_DISPLAY
	call DMES_DISPLAY
	rjmp PULSO
	jmp LOOP
;                                     0010
ESTADO_0010:
	sbi PORTB, PB3
	call UAMIN_DISPLAY
	call DAMIN_DISPLAY
	call UAHOR_DISPLAY
	call DAHOR_DISPLAY
	sbrs R29, 0
	call ALARMA_OFF_DISPLAY
	sbrc R29, 0
	call ALARMA_ON_DISPLAY
	clr R8
	rjmp PULSO
	jmp LOOP
;                                     0011
ESTADO_0011:
	clr R8
	call UHOR_DISPLAY
	call DHOR_DISPLAY
	call H_DISPLAY
	rjmp PULSO
	jmp LOOP
;                                     0100
ESTADO_0100:
	ldi R28, 12
	call UDIA_DISPLAY
	call DDIA_DISPLAY
	call F_DISPLAY
	rjmp PULSO
	jmp LOOP
;                                     0101
ESTADO_0101:
	call UAHOR_DISPLAY
	call DAHOR_DISPLAY
	call A_DISPLAY
	rjmp PULSO
	jmp LOOP
;                                     0110
ESTADO_0110:
	clr R8
	call UMIN_DISPLAY
	call DMIN_DISPLAY
	call H_DISPLAY
	rjmp PULSO
	jmp LOOP
;                                     0111
ESTADO_0111:
	call UMES_DISPLAY
	call DMES_DISPLAY
	call F_DISPLAY
	rjmp PULSO
	jmp LOOP
;                                     1000
ESTADO_1000:
	call UAMIN_DISPLAY
	call DAMIN_DISPLAY
	call A_DISPLAY
	rjmp PULSO
	jmp LOOP
;                                     1001
ESTADO_1001:
	ldi R29, 0
	call O_DISPLAY
	call F_DISPLAY
	rjmp PULSO
	jmp LOOP
;                                     1010
ESTADO_1010:
	ldi R29, 1
	call O_DISPLAY
	call N_DISPLAY
	jmp LOOP
;									1011
ESTADO_1011:
	clr R8
	sbi PORTB, PB3
	sbi PORTB, PB5
	call UMIN_DISPLAY
	call DMIN_DISPLAY
	call UHOR_DISPLAY
	call DHOR_DISPLAY
	call A_DISPLAY
	rjmp PULSO
	jmp LOOP

//***************************************************************************
// ALARMA ON
//***************************************************************************
ALARMA_ON_DISPLAY:
	call O_DISPLAY
	call N_DISPLAY
	ret
//***************************************************************************
// ALARMA OFF
//***************************************************************************
ALARMA_OFF_DISPLAY:
	call O_DISPLAY
	call F_DISPLAY
	ret

//***************************************************************************
// ALARMA COMPARACION
//***************************************************************************
ALARMA:
	cpse dahor, R26
	ret
	cpse uahor, uhor
	ret
	cpse damin, dmin
	ret
	cpse uamin, umin
	ret
	ldi estado, 11
	ret
	
//***************************************************************************
// TIMER0
//***************************************************************************
Init_T0:
	ldi R16, (1 << CS02)|(1 << CS00)	;config prescaler 1024
	out TCCR0B, R16
	ldi R16, 99							;valor desbordamiento
	out TCNT0, R16						; valor inicial contador
	ldi R16, (1 << TOIE0)
	sts TIMSK0, R16
	ret

//***************************************************************************
// ISR Timer 0 Overflow
//***************************************************************************
ISR_TIMER0_OVF:
	;push R17				; guardar en pila R16
	;in R17, sreg
	;push R17				; guardar en pila SREG

	ldi R17, 99				; cargar el valor de desbordamiento
	out TCNT0, R17			; cargar valor inicial
	sbi TIFR0, TOV0			; borrar bandra TOV0
	inc cont500ms					; incrementar contador 10 ms

	;pop R17					; obtener SREG
	;out sreg, R17			; restaurar valor antiguo SREG
	;pop R17					; obtener valor R16
	reti

//***************************************************************************
// ISR PCINT0
//***************************************************************************
ISR_PCINT0:
	push R16
	in R16, SREG
	push R16

	sbrs estado, 0		; estado bit0 = 1?
	jmp ISR_ESTADO_XXX0		; bit0 = 0
	jmp ISR_ESTADO_XXX1		; bit0 = 1

//***************************************************************************
// DEFINIR ISR_ESTADOS
//***************************************************************************
ISR_ESTADO_XXX0:
	sbrs estado, 1
	jmp ISR_ESTADO_XX00
	jmp ISR_ESTADO_XX10

ISR_ESTADO_XX00:
	sbrs estado, 2
	jmp ISR_ESTADO_X000
	JMP ISR_ESTADO_X100

ISR_ESTADO_X000:
	sbrs estado, 3
	jmp ISR_ESTADO_0000
	jmp ISR_ESTADO_1000

ISR_ESTADO_XXX1:
	sbrs estado, 1
	jmp ISR_ESTADO_XX01
	jmp ISR_ESTADO_XX11

ISR_ESTADO_XX01:
	sbrs estado, 2
	jmp ISR_ESTADO_X001
	jmp ISR_ESTADO_X101
ISR_ESTADO_X001:
	sbrs estado, 3
	jmp ISR_ESTADO_0001
	jmp ISR_ESTADO_1001
ISR_ESTADO_XX10:
	sbrs estado, 2
	jmp ISR_ESTADO_X010
	jmp ISR_ESTADO_X110
ISR_ESTADO_X010:
	sbrs estado, 3
	jmp ISR_ESTADO_0010
	jmp	ISR_ESTADO_1010
ISR_ESTADO_XX11:
	sbrs estado, 2
	jmp	ISR_ESTADO_X011
	jmp ISR_ESTADO_X111
ISR_ESTADO_X011:
	sbrs estado, 3
	jmp ISR_ESTADO_0011
	jmp ISR_ESTADO_1011
ISR_ESTADO_X100:
	sbrs estado, 3
	jmp ISR_ESTADO_0100
	jmp ISR_POP_PCINT0
	;jmp ESTADO_1100
ISR_ESTADO_X101:
	sbrs estado, 3
	jmp ISR_ESTADO_0101
	jmp ISR_POP_PCINT0
	;jmp ESTADO_1101
ISR_ESTADO_X110:
	sbrs estado, 3
	jmp ISR_ESTADO_0110
	jmp ISR_POP_PCINT0
	;jmp ESTADO_1110
ISR_ESTADO_X111:
	sbrs estado, 3
	jmp ISR_ESTADO_0111
	jmp ISR_POP_PCINT0
	;jmp ESTADO_1111

//***************************************************************************
// ISR_ESTADOS
//***************************************************************************
;                                     0000
ISR_ESTADO_0000:
	in R16, PINB
	sbrs R16, PB0
	ldi estado, 1			; PB0 = 0
	in R16, PINB
	sbrs R16, PB1
	ldi estado, 2			; PB1 = 0
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 3			; PB2 = 0
	jmp ISR_POP_PCINT0
;                                     0001
ISR_ESTADO_0001:
	in R16, PINB
	sbrs R16, PB0
	ldi estado, 0			; PB0 = 0
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 7
	jmp ISR_POP_PCINT0
;                                     0010
ISR_ESTADO_0010:
	in R16, PINB
	sbrs R16, PB2			; PB2
	ldi estado, 5
	in R16, PINB
	sbrs R16, PB1
	ldi estado, 0			; PB1 = 0
	jmp ISR_POP_PCINT0
;                                     0011
ISR_ESTADO_0011:
	in R16, PINB
	sbrs R16, PB0
	jmp ISR_INC_UHOR			; PB0 = 0
	in R16, PINB
	sbrs R16, PB1
	jmp ISR_DEC_UHOR			; PB1 = 0
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 6			; PB2 = 0
	jmp ISR_POP_PCINT0
;                                     0100
ISR_ESTADO_0100:
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 1			; PB2 = 0
	in R16, PINB
	sbrs R16, PB0
	jmp ISR_INC_UDIA
	in R16, PINB
	sbrs R16, PB1
	jmp ISR_DEC_DIA
	jmp ISR_POP_PCINT0
;                                     0101
ISR_ESTADO_0101:
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 8
	in R16, PINB
	sbrs R16, PB0
	jmp ISR_INC_A_UHOR
	in R16, PINB
	sbrs R16, PB1
	jmp ISR_DEC_A_UHOR
	jmp ISR_POP_PCINT0
;                                     0110
ISR_ESTADO_0110:
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 0			; PB2 = 0
	in R16, PINB
	sbrs R16, PB0
	jmp ISR_INC_UMIN
	in R16, PINB
	sbrs R16, PB1
	jmp ISR_DEC_UMIN
	jmp ISR_POP_PCINT0
;                                     0111
ISR_ESTADO_0111:
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 4			; PB2 = 0
	in R16, PINB
	sbrs R16, PB0
	jmp ISR_INC_UMES
	in R16, PINB
	sbrs R16, PB1
	jmp ISR_DEC_UMES
	jmp ISR_POP_PCINT0
;                                     1000
ISR_ESTADO_1000:
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 9
	in R16, PINB
	sbrs R16, PB0
	jmp ISR_INC_A_UMIN
	in R16, PINB
	sbrs R16, PB1
	jmp ISR_DEC_A_UMIN
	jmp ISR_POP_PCINT0
;                                     1001
ISR_ESTADO_1001:
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 2
	in R16, PINB
	sbrs R16, PB0
	ldi estado, 10
	jmp ISR_POP_PCINT0
;                                     1010
ISR_ESTADO_1010:
	in R16, PINB
	sbrs R16, PB2
	ldi estado, 2
	in R16, PINB
	sbrs R16, PB1
	ldi estado, 9
	jmp ISR_POP_PCINT0
;									1011
ISR_ESTADO_1011:
	in R16, PINB
	sbrs R16, PB2
	jmp ISR_ESTADO_1011_2
	jmp ISR_POP_PCINT0

ISR_ESTADO_1011_2:
	ldi R29, 0
	ldi estado, 0
	cbi PORTB, PB5
	jmp ISR_POP_PCINT0

//***************************************************************************
// ISR_POP_PCINT0
//***************************************************************************
ISR_POP_PCINT0:
	sbi PCIFR, PCIF0

	pop R16
	out SREG, R16
	pop R16
	reti
//***************************************************************************
// TEST DISPLAY
//***************************************************************************
TEST_DISPLAY:
	sbi PINC, PC0
	sbi PINC, PC1
	sbi PINC, PC2
	sbi PINC, PC3
	sbi PINC, PC4
	sbi PINC, PC5
	sbi PINB, PB4
	;sbi PORTB, PB3
	;sbi PINB, PB5

	sbi PIND, PD2
	sbi PIND, PD3
	sbi PIND, PD4
	sbi PIND, PD5
	sbi PIND, PD6
	sbi PIND, PD7
	
	ret

//***************************************************************************
// TEST LISTA DISPLAY
//***************************************************************************
TEST_LISTA_DISPLAY:
	;ldi useg, 0 
	mov R27, useg
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PIND, PD7

	ret

//***************************************************************************
// USEG DISPLAY
//***************************************************************************
USEG_DISPLAY:	
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	

	mov R27, useg
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD7
	
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6

	ret

//***************************************************************************
// DSEG DISPLAY
//***************************************************************************
DSEG_DISPLAY:
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD7

	mov R27, dseg
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD6
	
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD7

	ret

//***************************************************************************
// UMIN DISPLAY
//***************************************************************************
UMIN_DISPLAY:
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, umin
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD5
	
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// DMIN DISPLAY
//***************************************************************************
DMIN_DISPLAY:
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, dmin
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD4
	
	cbi PORTD, PD2
	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret

//***************************************************************************
// UHOR DISPLAY
//***************************************************************************
UHOR_DISPLAY:
	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, uhor
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD3
	
	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret

//***************************************************************************
// DHOR DISPLAY
//***************************************************************************
DHOR_DISPLAY:
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, R26
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD2
	
	cbi PORTD, PD3
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret

//***************************************************************************
// UDIA DISPLAY
//***************************************************************************
UDIA_DISPLAY:
	cbi PORTD, PD5
	cbi PORTD, PD4
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, udia
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD5
	cbi PORTD, PD4
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD3
	
	cbi PORTD, PD5
	cbi PORTD, PD4
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// DDIA DISPLAY
//***************************************************************************
DDIA_DISPLAY:
	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD4
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, ddia
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD4
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD2
	
	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD4
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// UMES DISPLAY
//***************************************************************************
UMES_DISPLAY:
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, umes
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD5
	
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// DMES DISPLAY
//***************************************************************************
DMES_DISPLAY:
	cbi PORTD, PD2
	cbi PORTD, PD5
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, dmes
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD5
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD4
	
	cbi PORTD, PD2
	cbi PORTD, PD5
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// UAMIN DISPLAY
//***************************************************************************
UAMIN_DISPLAY:
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, uamin
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD5
	
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// DAMIN DISPLAY
//***************************************************************************
DAMIN_DISPLAY:
	cbi PORTD, PD5
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, damin
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD5
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD4
	
	cbi PORTD, PD5
	cbi PORTD, PD3
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// UAHOR DISPLAY
//***************************************************************************
UAHOR_DISPLAY:
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, uahor
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD3
	
	cbi PORTD, PD4
	cbi PORTD, PD5
	cbi PORTD, PD2
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// UAMIN DISPLAY
//***************************************************************************
DAHOR_DISPLAY:
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	mov R27, dahor
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD2
	
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD5
	cbi PORTD, PD6
	cbi PORTD, PD7

	ret
//***************************************************************************
// LETRA A DISPLAY
//***************************************************************************
A_DISPLAY:
	ldi R28, 10

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	mov R27, R28
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD7
	
	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	ret

//***************************************************************************
// LETRA H DISPLAY
//***************************************************************************
H_DISPLAY:
	ldi R28, 13

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	mov R27, R28
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD7
	
	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	ret
//***************************************************************************
// LETRA F DISPLAY
//***************************************************************************
F_DISPLAY:
	ldi R28, 12

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	mov R27, R28
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD7
	
	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	ret
//***************************************************************************
// LETRA N DISPLAY
//***************************************************************************
N_DISPLAY:
	ldi R28, 14

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	mov R27, R28
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD7
	
	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD6
	cbi PORTD, PD5

	ret
//***************************************************************************
// LETRA O DISPLAY
//***************************************************************************
O_DISPLAY:
	ldi R28, 0

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD7
	cbi PORTD, PD5

	mov R27, R28
	ldi ZH, HIGH(T7S << 1)
	ldi ZL, LOW(T7S << 1)
	add ZL, R27
	lpm R27, Z

	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD7
	cbi PORTD, PD5

	sbrc R27, PC6
	sbi PORTB, PB4
	sbrs R27, PC6
	cbi PORTB, PB4

	out PORTC, R27
	sbi PORTD, PD6
	
	cbi PORTD, PD2
	cbi PORTD, PD4
	cbi PORTD, PD3
	cbi PORTD, PD7
	cbi PORTD, PD5

	ret
//***************************************************************************
// INCREMENTAR RELOJ
//***************************************************************************
INC_USEG:
	inc useg
	rjmp LOOP
INC_DSEG:
	inc dseg
	rjmp LOOP
INC_UMIN:
	inc umin
	rjmp LOOP
INC_DMIN:
	inc dmin
	rjmp LOOP
INC_UHOR:
	ldi R28, 2
	cpse R26, R28
	call INC_UHOR_2
	ldi R28, 3
	cpse uhor, R28
	call INC_UHOR_2
	clr uhor
	clr R26
	call INC_UDIA
	rjmp LOOP
INC_UHOR_2:
	inc uhor
	rjmp LOOP
INC_DHOR:
	inc R26
	rjmp LOOP

//***************************************************************************
// INCREMENTAR FECHA
//***************************************************************************
INC_UDIA:
	ldi R28, 0
	cpse R28, dmes
	rjmp MES_1X
	rjmp MES_0X

INC_UDIA_2:
	inc udia
	rjmp LOOP
INC_DDIA:
	inc ddia
	rjmp LOOP
INC_UMES:
	ldi R28, 1
	cpse dmes, R28
	call INC_UMES_3
	
	ldi R28, 2
	cpse umes, R28
	call INC_UMES_2
	ldi R28, 1
	mov umes, R28
	clr dmes
	rjmp LOOP
INC_UMES_3: 
	ldi R28, 9
	cpse umes, R28
	call INC_UMES_2
	clr umes
	rjmp INC_DMES
INC_UMES_2:
	inc umes
	rjmp LOOP
INC_DMES:
	ldi R28, 2
	cpse umes, R28
	call INC_DMES_2
	clr dmes
	rjmp LOOP
INC_DMES_2:
	inc dmes
	rjmp LOOP
//***************************************************************************
// MESES PARTE 2
//***************************************************************************
MES_31D_2:
;CONTINUIDAD DE DIAS 
	ldi R28, 9
	cpse udia, R28
	call INC_UDIA_2
	clr udia
; LIMITE MES
	ldi R28, 3
	cpse ddia, R28
	call INC_DDIA
	clr ddia			; RESET
	ldi R28, 1
	mov udia, R28

	rjmp LOOP
//***************************************************************************
MES_30D_2:
;CONTINUIDAD DE DIAS
	ldi R28, 9
	cpse udia, R28
	call INC_UDIA_2
	clr udia
; LIMITE MES
	ldi R28, 3
	cpse ddia, R28
	call INC_DDIA
	clr ddia			; RESET
	ldi R28, 1
	mov udia, R28

	rjmp LOOP
//***************************************************************************
MES_28D_2:
;CONTINUIDAD DE DIAS
	ldi R28, 9
	cpse udia, R28
	call INC_UDIA_2
	clr udia
; LIMITE MES
	ldi R28, 2
	cpse ddia, R28
	call INC_DDIA
	clr ddia			; RESET
	ldi R28, 1			
	mov udia, R28

	rjmp LOOP
//***************************************************************************
// MES 28 DIAS
//***************************************************************************
MES_28D:
	ldi R28, 2			; LIMITE DECENAS
	cpse ddia, R28
	rjmp MES_28D_2

	ldi R28, 8			; LIMITE UNIDADES
	cpse udia, R28
	call INC_UDIA_2
	ldi R28, 1			; RESET
	mov udia, R28
	clr ddia

	rjmp INC_UMES
//***************************************************************************
// SELECCIONAR MES 0X
//***************************************************************************
MES_0X:
	mov R28, umes
	cpi R28, 1
	breq MES_31D
	cpi R28, 2
	breq MES_28D
	cpi R28, 3
	breq MES_31D
	cpi R28, 4
	breq MES_30D
	cpi R28, 5
	breq MES_31D
	cpi R28, 6
	breq MES_30D
	cpi R28, 7
	breq MES_31D
	cpi R28, 8
	breq MES_31D
	cpi R28, 9
	breq MES_30D
	rjmp LOOP
//***************************************************************************
// SELECCIONAR MES 1X
//***************************************************************************
MES_1X:
	mov R28, umes
	cpi R28, 0
	breq MES_31D
	cpi R28, 1
	breq MES_30D
	cpi R28, 2
	breq MES_31D
	rjmp LOOP
//***************************************************************************
// MES 31 DIAS
//***************************************************************************
MES_31D:
	ldi R28, 3			; LIMITE DECENAS
	cpse ddia, R28
	rjmp MES_31D_2

	ldi R28, 1			; LIMITE UNIDADES
	cpse udia, R28
	call INC_UDIA_2
	ldi R28, 1			; RESET
	mov udia, R28
	clr ddia

	rjmp INC_UMES
//***************************************************************************
// MES 30 DIAS
//***************************************************************************
MES_30D:
	ldi R28, 3			; LIMITE DECENAS
	cpse ddia, R28
	rjmp MES_30D_2

	ldi R28, 0			; LIMITE UNIDADES
	cpse udia, R28	
	call INC_UDIA_2
	ldi R28, 1			; RESET
	mov udia, R28
	clr ddia
	rjmp INC_UMES

//***************************************************************************
// HORA INTERRUPCIONES
//***************************************************************************

//***************************************************************************
//  minutos interrupciones
//***************************************************************************
ISR_INC_UMIN:						; incrementar
	ldi R28, 9
	cpse umin, R28
	jmp ISR_INC_UMIN_2
	clr umin
	jmp ISR_INC_DMIN
ISR_INC_UMIN_2:
	inc umin
	jmp ISR_POP_PCINT0
ISR_INC_DMIN:
	ldi R28, 5
	cpse dmin, R28
	jmp ISR_INC_DMIN_2
	clr dmin
	jmp ISR_POP_PCINT0
ISR_INC_DMIN_2:
	inc dmin
	jmp ISR_POP_PCINT0
ISR_DEC_UMIN:						; decrementar
	ldi R28, 0
	cpse umin, R28
	jmp ISR_DEC_UMIN_2
	ldi umin, 9
	ldi R28, 0
	cpse dmin, R28
	jmp ISR_DEC_UMIN_3
	ldi dmin, 5
	jmp ISR_POP_PCINT0
ISR_DEC_UMIN_2:
	dec umin
	jmp ISR_POP_PCINT0
ISR_DEC_UMIN_3:
	dec dmin
	jmp ISR_POP_PCINT0
//***************************************************************************
//  horas interrupciones
//***************************************************************************
ISR_INC_UHOR:						; incrementar
	ldi R28, 2
	cpse R26, R28			
	jmp ISR_INC_UHOR_2
	ldi R28, 3
	cpse uhor, R28
	jmp ISR_INC_UHOR_2
	clr uhor
	clr R26
	jmp ISR_POP_PCINT0
ISR_INC_UHOR_2:
	ldi R28, 9
	cpse uhor, R28
	jmp ISR_INC_UHOR_3
	clr uhor
	inc R26
	jmp ISR_POP_PCINT0
ISR_INC_UHOR_3:
	inc uhor
	jmp ISR_POP_PCINT0
ISR_DEC_UHOR:						; decrementar
	ldi R28, 0
	cpse R26, R28
	jmp ISR_DEC_UHOR_3
	ldi R28, 0
	cpse uhor, R28
	jmp ISR_DEC_UHOR_2
	ldi R26, 2
	ldi uhor, 3
	jmp ISR_POP_PCINT0
ISR_DEC_UHOR_2:
	dec uhor
	jmp ISR_POP_PCINT0
ISR_DEC_UHOR_3:
	ldi R28, 0
	cpse uhor, R28
	jmp ISR_DEC_UHOR_2
	ldi uhor, 9
	dec R26
	jmp ISR_POP_PCINT0

//***************************************************************************
// ALARMA INTERRUPCIONES
//***************************************************************************

//***************************************************************************
//  minutos interrupciones
//***************************************************************************
ISR_INC_A_UMIN:						; incrementar
	ldi R28, 9
	cpse uamin, R28
	jmp ISR_INC_A_UMIN_2
	clr uamin
	jmp ISR_INC_A_DMIN
ISR_INC_A_UMIN_2:
	inc uamin
	jmp ISR_POP_PCINT0
ISR_INC_A_DMIN:
	ldi R28, 5
	cpse damin, R28
	jmp ISR_INC_A_DMIN_2
	clr damin
	jmp ISR_POP_PCINT0
ISR_INC_A_DMIN_2:
	inc damin
	jmp ISR_POP_PCINT0
ISR_DEC_A_UMIN:						; decrementar
	ldi R28, 0
	cpse uamin, R28
	jmp ISR_DEC_A_UMIN_2
	ldi R28, 9
	mov uamin, R28
	ldi R28, 0
	cpse damin, R28
	jmp ISR_DEC_A_UMIN_3
	ldi R28, 5
	mov damin, R28
	jmp ISR_POP_PCINT0
ISR_DEC_A_UMIN_2:
	dec uamin
	jmp ISR_POP_PCINT0
ISR_DEC_A_UMIN_3:
	dec damin
	jmp ISR_POP_PCINT0
//***************************************************************************
//  horas interrupciones
//***************************************************************************
ISR_INC_A_UHOR:						; incrementar
	ldi R28, 2
	cpse dahor, R28			
	jmp ISR_INC_A_UHOR_2
	ldi R28, 3
	cpse uahor, R28
	jmp ISR_INC_A_UHOR_2
	clr uahor
	clr dahor
	jmp ISR_POP_PCINT0
ISR_INC_A_UHOR_2:
	ldi R28, 9
	cpse uahor, R28
	jmp ISR_INC_A_UHOR_3
	clr uahor
	inc dahor
	jmp ISR_POP_PCINT0
ISR_INC_A_UHOR_3:
	inc uahor
	jmp ISR_POP_PCINT0
ISR_DEC_A_UHOR:						; decrementar
	ldi R28, 0
	cpse dahor, R28
	jmp ISR_DEC_A_UHOR_3
	ldi R28, 0
	cpse uahor, R28
	jmp ISR_DEC_A_UHOR_2
	ldi R28, 2
	mov dahor, R28
	ldi R28, 3
	mov uahor, R28
	jmp ISR_POP_PCINT0
ISR_DEC_A_UHOR_2:
	dec uahor
	jmp ISR_POP_PCINT0
ISR_DEC_A_UHOR_3:
	ldi R28, 0
	cpse uahor, R28
	jmp ISR_DEC_A_UHOR_2
	ldi R28, 9
	mov uahor, R28
	dec dahor
	jmp ISR_POP_PCINT0

//***************************************************************************
// FECHA INTERRUPCIONES
//***************************************************************************

//***************************************************************************
//  meses interrupciones
//***************************************************************************
ISR_INC_UMES:
	ldi R28, 0
	cpse dmes, R28
	jmp ISR_INC_UMES_3
	ldi R28, 9
	cpse umes, R28
	jmp ISR_INC_UMES_2
	clr umes
	ldi R28, 1
	mov dmes, R28
	jmp ISR_POP_PCINT0
ISR_INC_UMES_2:	
	inc umes
	jmp ISR_POP_PCINT0
ISR_INC_UMES_3:
	ldi R28, 2
	cpse umes, R28
	jmp ISR_INC_UMES_2
	ldi R28, 1
	mov umes, R28
	clr dmes
	jmp ISR_POP_PCINT0
ISR_DEC_UMES:
	ldi R28, 0
	cpse dmes, R28
	jmp ISR_DEC_UMES_2
	ldi R28, 1
	cpse umes, R28
	jmp ISR_DEC_UMES_3
	ldi R28, 2
	mov umes, R28
	ldi R28, 1
	mov dmes, R28
	jmp ISR_POP_PCINT0
ISR_DEC_UMES_2:
	ldi R28, 0
	cpse umes, R28
	jmp ISR_DEC_UMES_3
	ldi R28, 9
	mov umes, R28
	dec dmes
	jmp ISR_POP_PCINT0
ISR_DEC_UMES_3:
	dec umes
	jmp ISR_POP_PCINT0
//***************************************************************************
//  dias interrupciones incrementar
//***************************************************************************
ISR_INC_UDIA:
	ldi R28, 0
	cpse R28, dmes
	jmp ISR_MES_1X
	jmp ISR_MES_0X
ISR_MES_28D:
	ldi R28, 2			; LIMITE DECENAS
	cpse ddia, R28
	jmp ISR_MES_28D_2

	ldi R28, 8			; LIMITE UNIDADES
	cpse udia, R28
	jmp ISR_INC_UDIA_2
	ldi R28, 1			; RESET
	mov udia, R28
	clr ddia

	jmp ISR_POP_PCINT0
//***************************************************************************
// SELECCIONAR MES 0X
//***************************************************************************
ISR_MES_0X:
	mov R28, umes
	cpi R28, 1
	breq ISR_MES_31D
	cpi R28, 2
	breq ISR_MES_28D
	cpi R28, 3
	breq ISR_MES_31D
	cpi R28, 4
	breq ISR_MES_30D
	cpi R28, 5
	breq ISR_MES_31D
	cpi R28, 6
	breq ISR_MES_30D
	cpi R28, 7
	breq ISR_MES_31D
	cpi R28, 8
	breq ISR_MES_31D
	cpi R28, 9
	breq ISR_MES_30D
	jmp ISR_POP_PCINT0
ISR_MES_1X:
	mov R28, umes
	cpi R28, 0
	breq ISR_MES_31D
	cpi R28, 1
	breq ISR_MES_30D
	cpi R28, 2
	breq ISR_MES_31D
	jmp ISR_POP_PCINT0
ISR_MES_31D:
	ldi R28, 3			; LIMITE DECENAS
	cpse ddia, R28
	jmp ISR_MES_31D_2

	ldi R28, 1			; LIMITE UNIDADES
	cpse udia, R28
	jmp ISR_INC_UDIA_2
	ldi R28, 1			; RESET
	mov udia, R28
	clr ddia
	jmp ISR_POP_PCINT0
//***************************************************************************
ISR_MES_30D:
	ldi R28, 3			; LIMITE DECENAS
	cpse ddia, R28
	jmp ISR_MES_30D_2

	ldi R28, 0			; LIMITE UNIDADES
	cpse udia, R28	
	jmp ISR_INC_UDIA_2
	ldi R28, 1			; RESET
	mov udia, R28
	clr ddia
	jmp ISR_POP_PCINT0

ISR_MES_31D_2:
;CONTINUIDAD DE DIAS 
	ldi R28, 9
	cpse udia, R28
	jmp ISR_INC_UDIA_2
	clr udia
; LIMITE MES
	ldi R28, 3
	cpse ddia, R28
	jmp ISR_INC_DDIA
	clr ddia			; RESET
	ldi R28, 1
	mov udia, R28

	jmp ISR_POP_PCINT0
ISR_INC_UDIA_2:
	inc udia
	jmp ISR_POP_PCINT0
ISR_INC_DDIA:
	inc ddia
	jmp ISR_POP_PCINT0
//***************************************************************************
ISR_MES_30D_2:
;CONTINUIDAD DE DIAS
	ldi R28, 9
	cpse udia, R28
	jmp ISR_INC_UDIA_2
	clr udia
; LIMITE MES
	ldi R28, 3
	cpse ddia, R28
	jmp ISR_INC_DDIA
	clr ddia			; RESET
	ldi R28, 1
	mov udia, R28
	jmp ISR_POP_PCINT0
//***************************************************************************
ISR_MES_28D_2:
;CONTINUIDAD DE DIAS
	ldi R28, 9
	cpse udia, R28
	jmp ISR_INC_UDIA_2
	clr udia
; LIMITE MES
	ldi R28, 2
	cpse ddia, R28
	jmp ISR_INC_DDIA
	clr ddia			; RESET
	ldi R28, 1			
	mov udia, R28
	jmp ISR_POP_PCINT0

//***************************************************************************
//  dias interrupciones decrementar
//***************************************************************************
ISR_DEC_DIA:
	ldi R28, 0
	cpse R28, dmes
	jmp ISR_DEC_MES_1X
	jmp ISR_DEC_MES_0X
//***************************************************************************
ISR_DEC_MES_28D:
	ldi R28, 0						; limite ddia
	cpse R28, ddia
	jmp ISR_DECREMENTAR_28D_2
	ldi R28, 1						; limite udia
	cpse R28, udia
	jmp ISR_DECREMENTAR_28D
	ldi R28, 8						; reset
	mov udia, R28
	ldi R28, 2
	mov ddia, R28
	jmp ISR_POP_PCINT0
ISR_DECREMENTAR_28D:
	dec udia
	jmp ISR_POP_PCINT0
ISR_DECREMENTAR_28D_2:
	ldi R28, 0
	cpse udia, R28
	jmp ISR_DECREMENTAR_28D 
	ldi R28, 9
	mov udia, R28
	dec ddia
	jmp ISR_POP_PCINT0
//***************************************************************************
// SELECCIONAR MES 0X
//***************************************************************************
ISR_DEC_MES_0X:
	mov R28, umes
	cpi R28, 1
	breq ISR_DEC_MES_31D
	cpi R28, 2
	breq ISR_DEC_MES_28D
	cpi R28, 3
	breq ISR_DEC_MES_31D
	cpi R28, 4
	breq ISR_DEC_MES_30D
	cpi R28, 5
	breq ISR_DEC_MES_31D
	cpi R28, 6
	breq ISR_DEC_MES_30D
	cpi R28, 7
	breq ISR_DEC_MES_31D
	cpi R28, 8
	breq ISR_DEC_MES_31D
	cpi R28, 9
	breq ISR_DEC_MES_30D
	jmp ISR_POP_PCINT0
ISR_DEC_MES_1X:
	mov R28, umes
	cpi R28, 0
	breq ISR_DEC_MES_31D
	cpi R28, 1
	breq ISR_DEC_MES_30D
	cpi R28, 2
	breq ISR_DEC_MES_31D
	jmp ISR_POP_PCINT0
//***************************************************************************
ISR_DEC_MES_31D:
	ldi R28, 0						; limite ddia
	cpse R28, ddia
	jmp ISR_DECREMENTAR_31D_2
	ldi R28, 1						; limite udia
	cpse R28, udia
	jmp ISR_DECREMENTAR_31D
	ldi R28, 1						; reset
	mov udia, R28
	ldi R28, 3
	mov ddia, R28
	jmp ISR_POP_PCINT0
ISR_DECREMENTAR_31D:
	dec udia
	jmp ISR_POP_PCINT0
ISR_DECREMENTAR_31D_2:
	ldi R28, 0
	cpse udia, R28
	jmp ISR_DECREMENTAR_31D 
	ldi R28, 9
	mov udia, R28
	dec ddia
	jmp ISR_POP_PCINT0
//***************************************************************************
ISR_DEC_MES_30D:
	ldi R28, 0						; limite ddia
	cpse R28, ddia
	jmp ISR_DECREMENTAR_30D_2
	ldi R28, 1						; limite udia
	cpse R28, udia
	jmp ISR_DECREMENTAR_30D
	ldi R28, 0						; reset
	mov udia, R28
	ldi R28, 3
	mov ddia, R28
	jmp ISR_POP_PCINT0
ISR_DECREMENTAR_30D:
	dec udia
	jmp ISR_POP_PCINT0
ISR_DECREMENTAR_30D_2:
	ldi R28, 0
	cpse udia, R28
	jmp ISR_DECREMENTAR_30D 
	ldi R28, 9
	mov udia, R28
	dec ddia
	jmp ISR_POP_PCINT0