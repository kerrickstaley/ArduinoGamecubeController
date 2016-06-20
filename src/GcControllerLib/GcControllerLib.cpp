#include <GcControllerLib.h>
#include <Arduino.h>
#include <avr/interrupt.h>
#include "EnableInterrupt.h"

// INT0_vect is the interrupt for change on pin 2
ISR(INT0_vect, ISR_NAKED) {
  asm volatile(
    "jmp isrHandler"
  );
}

void GcController::init() {
  // initialize digital pin 2 as an input
  pinMode(2, INPUT);
  enableInterrupt(digitalPinToInterrupt(2), LOW);

  TCCR1A = 0;
  // set timer1 prescaler to 64 -> 250000 ticks per second
  TCCR1B = (TCCR1B & 0b11111000) | 0x3;

  // disable timer0
  TCCR0B &= ~0b111;
}

uint32_t GcController::time_since_pin_low() {
    uint32_t timer = TCNT1L;
    timer |= TCNT1H << 8;
    return timer * 4;
}

extern "C" {
  extern uint8_t gcBufCtrl[14];
}

uint8_t GcController::latest_data(uint8_t*& data_ptr) {
  // returns size
  // todo rewrite in assembly
  data_ptr = NULL;

  cli();
  if (*gcBufCtrl & 1) {
    data_ptr = gcBufCtrl + *gcBufCtrl;
    *gcBufCtrl = (*gcBufCtrl & ~1) ^ 0b1000;
  }
  sei();

  if (data_ptr == NULL) {
    return 0;
  }

  return *(data_ptr + 4);
}

GcController gc_controller;
