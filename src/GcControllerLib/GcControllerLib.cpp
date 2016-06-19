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
  // initialize digital pin 2 an input with pull-up
  // TODO REMOVE THIS BEFORE INTERFACING WITH A REAL WII?GC
  pinMode(2, INPUT_PULLUP);
  enableInterrupt(digitalPinToInterrupt(2), LOW);

  TCCR1A = 0;
  // set timer0 prescaler to 1024 -> 15625 ticks per second
  TCCR1B = (TCCR1B & 0b11111000) | 0x5;
}

uint16_t GcController::time_since_pin_low() {
    uint16_t timer = TCNT1L;
    timer |= TCNT1H << 8;
    return (uint32_t)timer * 10000 / 15625;
}

GcController gc_controller;
