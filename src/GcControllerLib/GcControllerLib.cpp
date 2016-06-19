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

GcController::GcController() {
  // initialize digital pin 2 an input with pull-up
  // TODO REMOVE THIS BEFORE INTERFACING WITH A REAL WII?GC
  pinMode(2, INPUT_PULLUP);
  enableInterrupt(digitalPinToInterrupt(2), LOW);
}

GcController gc_controller;