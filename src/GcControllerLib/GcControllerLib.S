#include <avr/io.h>

; io.h addresses are offset for memory-mapping
#define DIRECT_PORT(port) (port - 0x20)

; blink for 3 seconds
#define BLINK_TIME 3000

.global blinkTime
blinkTime:
ldi r24, (BLINK_TIME & 0xff)
ldi r25, (BLINK_TIME >> 8)
ret

.global isrHandler
isrHandler:
push r16;
push r1;
push r0;
in r0, DIRECT_PORT(SREG)
push r0

; prematurely shut off LED (pin 13) if pin 2 is connected to GND
in r16, DIRECT_PORT(PORTB)
andi r16, ~(1 << 5)
out DIRECT_PORT(PORTB), r16

pop r0
out DIRECT_PORT(SREG), r0
pop r0
pop r1
pop r16
reti
