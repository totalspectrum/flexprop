// P2 blinking lights and serial demo
// this requires a P2-EVAL board

// to get the frequency we desire, define _clkfreq in an enum
// to use a board with a different frequency, also define
// _xtalfreq
// do this *before* including propeller.h

enum {
    _clkfreq = 180'000'000,
};

#include <stdio.h>
#include <propeller.h>

#define PIN 56

void main()
{
    unsigned int pinmask = 1<<(PIN-32);
    unsigned i = 0;

    DIRB |= pinmask; // set pins as output
    for(;;) {
        OUTB ^= pinmask;
        waitcnt(getcnt() + _clkfreq/4);
        printf("Toggle %u\n", i++);
    }
}
