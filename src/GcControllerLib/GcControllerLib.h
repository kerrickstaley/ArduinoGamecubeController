#ifndef GC_CONTROLLER_LIB_H
#define GC_CONTROLLER_LIB_H

#include <inttypes.h>

extern "C" {
  uint16_t blinkTime();
}

// Don't instantiate this class; instead, use the gc_controller instance already provided.
class GcController {
public:
    static void init();

    // time since last pin-low interrupt, in microseconds, with a granularity of 4 microseconds
    uint32_t time_since_pin_low();
    uint8_t latest_data(uint8_t*& data_ptr);
};

extern GcController gc_controller;

#endif // GC_CONTROLLER_LIB_H
