#include <GcControllerLib.h>

void setup() {
  // initialize digital pin 13 as an output.
  pinMode(13, OUTPUT);
  Serial.begin(9600);
  gc_controller.init();
}

void loop() {
  static int seconds_since_low = -1;
  int new_seconds_since_low = gc_controller.time_since_pin_low() / 10000;
  if (new_seconds_since_low != seconds_since_low) {
    Serial.print("Seconds since low: ");
    Serial.println(new_seconds_since_low);
    seconds_since_low = new_seconds_since_low;
  }
}
