#ifndef GC_CONTROLLER_LIB_H
#define GC_CONTROLLER_LIB_H

#include <avr/interrupt.h>
#include "EnableInterrupt.h"

// not sure why the above include doesn't work, but the .ino file complains it doesn't see the function declaration
void enableInterrupt(uint8_t interruptNum, int mode);

// INT0_vect is the interrupt for change on pin 2
ISR(INT0_vect, ISR_NAKED) {
  asm volatile(
    "jmp isrHandler"
  );
}

extern "C" {
  uint16_t blinkTime();
}

#endif // GC_CONTROLLER_LIB_H
