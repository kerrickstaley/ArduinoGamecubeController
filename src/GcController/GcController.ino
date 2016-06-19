#include <GcControllerLib.h>

void setup() {
  // initialize digital pin 13 as an output.
  pinMode(13, OUTPUT);
  Serial.begin(9600);
  gc_controller.init();
}

void loop() {
  static uint16_t old_time_since_low = 0;
  uint16_t new_time_since_low = gc_controller.time_since_pin_low();
  if (old_time_since_low > new_time_since_low) {
    Serial.print("poll after ");
    Serial.print(old_time_since_low / 10);
    Serial.print('.');
    Serial.print(old_time_since_low % 10);
    Serial.println(" milliseconds");
  }
  old_time_since_low = new_time_since_low;
}
