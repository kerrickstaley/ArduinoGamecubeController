#include <GcControllerLib.h>

void setup() {
  // initialize digital pin 13 as an output.
  pinMode(13, OUTPUT);
  Serial.begin(9600);
  gc_controller.init();
}

void loop() {
  uint8_t* data_ptr;
  int bits = gc_controller.latest_data(data_ptr);
  if (bits > 0) {
    Serial.print("Received ");
    Serial.print(bits);
    Serial.println(" bits from console");
  }
}
