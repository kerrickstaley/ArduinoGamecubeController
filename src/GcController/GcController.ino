#include <GcControllerLib.h>

void setup() {
  // initialize digital pin 13 as an output.
  pinMode(13, OUTPUT);

  // initialize digital pin 2 an input with pull-up
  pinMode(2, INPUT_PULLUP);

  enableInterrupt(digitalPinToInterrupt(2), LOW);
}

void loop() {
  digitalWrite(13, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(blinkTime());              // wait for a second
  digitalWrite(13, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);              // wait for a second
}
