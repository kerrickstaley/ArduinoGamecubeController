#ifndef GC_CONTROLLER_LIB_H
#define GC_CONTROLLER_LIB_H

#include <inttypes.h>

extern "C" {
  uint16_t blinkTime();
}

// You may only instantiate a single instance of this class globally.
class GcController {
public:
    static void init();

    // time since last pin-low interrupt, in 10ths of a millisecond
    uint16_t time_since_pin_low();
};

extern GcController gc_controller;

#endif // GC_CONTROLLER_LIB_H
