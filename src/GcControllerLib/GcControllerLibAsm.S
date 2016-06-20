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
in r16, DIRECT_PORT(PIND)   ; (1)
andi r16, (1 << 2)          ; (1)
breq waitForHigh            ; (2/1)

eor r17, r17                ; (1)
waitForLow:
inc r17                     ; (1) line was already high once in waitForHigh so we count that
in r16, DIRECT_PORT(PIND)   ; (1)
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
; let's use < 5 as the cutoff for now.

; Finish setting up. We only did a minimal amount of this above because the ISR might be delayed and we want
; to catch the "high" fraction of the first bit as soon as possible.

push r31                    ; (2)
push r30                    ; (2)
push r29                    ; (2)
ldi r30, lo8(gcBufCtrl)     ; (1)
ldi r31, hi8(gcBufCtrl)     ; (1)
ldi r29, 1                  ; (1)

ld r16, Z                   ; (2)
ori r16, 1                  ; (1)
st Z, r16                   ; (2)
add r30, r16                ; (1)
ldi r16, 0                  ; (1)
adc r31, r16                ; (1)

; we've used 17 cycles

; High bit of r17 is always 1, when it overflows we know we've received a full byte.
cpi r17, 5                  ; (1)
ldi r17, 0b10               ; (1)
brlo sawZero                ; (2/1)
inc r17                     ; (1)
sawZero:

; we've used 21 cycles, now we nop for 6
nop_block 6

readBits:
in r16, DIRECT_PORT(PIND)   ; (1)

inc r29                     ; (1)
lsl r17                     ; (1)
andi r16, (1 << 2)          ; (1)
breq sawZero2               ; (2/1)
inc r17                     ; (1)
sawZero2:

; if we finished a byte write it out
mov r16, r29                ; (1)
andi r16, 0b111             ; (1)
breq store                  ; (2/1)
nop                         ; (1)
rjmp doneStore              ; (2)
store:
st z+, r17                  ; (2)
doneStore:

; 25 bits is the max packet size, if we are at 25 bits bail out
cpi r29, 25                 ; (1)
brge done                   ; (2/1)

; We've used 14 cycles, and we need to use 40. Nop for 26
nop_block 26

; Check if the line is zero and we should continue.
in r16, DIRECT_PORT(PIND)   ; (1)
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
std z+4, r29

; reset TIMER1
; have to write high byte first; the write is atomic
ldi r30, (TCNT1H & 0xFF)
ldi r31, (TCNT1H >> 8)
st z, r16
st -z, r16

; reset the interrupt register so we don't immediately re-enter the interrupt
ldi r16, 1
out DIRECT_PORT(EIFR), r16

; restore state
pop r29
pop r30
pop r31
pop r16
out DIRECT_PORT(SREG), r16
pop r16
pop r17

reti
