; blink for 3 seconds
#define BLINK_TIME 3000

.global blinkTime
blinkTime:
ldi r24, (BLINK_TIME & 0xff)
ldi r25, (BLINK_TIME >> 8)
ret

.global isrHandler
isrHandler:
reti
