#include <avr/io.h>

; io.h addresses are offset for memory-mapping
#define DIRECT_PORT(port) (port - 0x20)

.macro nop_block nop_cnt
nop
.if \nop_cnt - 1
nop_block "(\nop_cnt-1)"
.endif
.endm

; blink for 3 seconds
#define BLINK_TIME 3000

.data
.comm gcBufCtrl, 14    ; Bit 3 indicates which buffer should be written. Bit 0 indicates whether new data is available.
/*
.comm gcInBuf1, 4, 1
.comm gcInBuf1Size, 4, 1  ; Only a 1-byte value but we add 3 bytes of padding
.comm gcInBuf1, 4, 1
.comm gcInBuf2Size, 1, 1
*/

.text
.global isrHandler
isrHandler:

; we've already burnt 3 cycles from the start of the ISR due to the JMP

; save r17, r16, and SREG
push r17                    ; (2)
push r16                    ; (2)
in r16, DIRECT_PORT(SREG)   ; (1)
push r16                    ; (2)

; wait for line to go high again
waitForHigh:
in r16, DIRECT_PORT(PORTD)  ; (1)
andi r16, (1 << 2)          ; (1)
breq waitForHigh            ; (2/1)

eor r17, r17                ; (1)
waitForLow:
inc r17                     ; (1) line was already high once in waitForHigh so we count that
in r16, DIRECT_PORT(PORTD)  ; (1)
andi r16, (1 << 2)          ; (1)
brne waitForLow             ; (2/1)

; We're now sync'd up with the external signal.
; We are, on average, 5 cycles after the start of "low" section
; We want to do our reads 32 cycles after the start of the "low" section, so we have 27 more cycles to use

; the waitForLow loop takes 5 cycles
; r17 is the number of times we saw the line high
; r17 should be around 16 / 5 = 3.2 if it was a 0
; r17 should be around 48 / 5 = 9.6 if it was a 1
; a good cutoff would be r17 < 7 -> 0, r15 >= 7 -> 1, although these might both be lower because it takes time for the
; signal to rise and Arduino operates at 5v whereas the signal is 3.3v
; let's use < 7 as the cutoff for now.

; Finish setting up. We only did a minimal amount of this above because the ISR might be delayed and we want
; to catch the "high" fraction of the first bit as soon as possible.

push r31                    ; (2)
push r30                    ; (2)
push r29                    ; (2)
ldi r30, lo8(gcBufCtrl) ; (1)
ldi r31, hi8(gcBufCtrl)   ; (1)
ldi r29, 1                  ; (1)

ld r16, Z                   ; (1)
ori r16, 1                  ; (1)
st Z, r16                   ; (1)
add r30, r16                ; (1)
ldi r16, 0                  ; (1)
adc r31, r16                ; (1)

; we've used 15 cycles

; High bit of r17 is always 1, when it overflows we know we've received a full byte.
cpi r17, 7                  ; (1)
ldi r17, 0b10               ; (1)
brlo sawZero                ; (2/1)
inc r17                     ; (1)
sawZero:

; we've used 19 cycles, now we nop for 8
nop_block 8

readBits:
in r16, DIRECT_PORT(PORTD)  ; (1)

inc r29                     ; (1)
lsl r17                     ; (1)
andi r16, (1 << 2)          ; (1)
breq sawZero2               ; (2/1)
inc r17                     ; (1)
sawZero2:

; if we finished a byte write it out
andi r29, 0b111             ; (1)
breq noStore                ; (2/1)
st z+, r17                  ; (1)
noStore:

; 25 bits is the max packet size, if we are at 25 bits bail out
cpi r29, 25                 ; (1)
brge done                  ; (2/1)

; We've used 11 cycles, and we need to use 40. Nop for 29
nop_block 29

; Check if the line is zero and we should continue.
in r16, DIRECT_PORT(PORTD)  ; (1)
andi r16, (1 << 2)          ; (1)
brne done                   ; (2/1)

; We've used 3 cycles, and we need to use 24. Nop for 19 (because of the rjmp).
nop_block 19
rjmp readBits

done:
; no longer time critical

; store the last byte
st z, r17

; store the byte count in the relevant gcInBufSize field
; first reset Z to point back to gcInBuf
mov r16, r17
lsr r16
lsr r16
lsr r16
sub r30, r16
ldi r16, 0
sbc r31, r16

; now store
std z+4, r17

; reset TIMER1
; have to write high byte first; the write is atomic
ldi r30, (TCNT1H & 0xFF)
ldi r31, (TCNT1H >> 8)
st z, r16
st -z, r16

; restore state
pop r29
pop r30
pop r31
pop r16
out DIRECT_PORT(SREG), r16
pop r16
pop r17

reti
