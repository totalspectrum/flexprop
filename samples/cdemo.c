// P2 blinking lights and serial demo
// this requires a P2-EVAL board

#include <stdio.h>
#include <propeller.h>

// to get the frequency we desire, we
// specify P2_TARGET_MHZ then include "sys/p2es_clock.h"
// e.g. to get 160_000_000, define P2_TARGET_MHZ to 160
// p2es_clock.h defines constants _SETFREQ and _CLOCKFREQ
// which we can then use to set the clock
//
// note that this is not the only way to set the clock; you can
// certainly calculate the desired clock mode based on the frequency
// and pass the resulting mode and frequency directly to clkset()
// p2es_clock.h is just a convenience header
#define P2_TARGET_MHZ 160
#include "sys/p2es_clock.h"
#define BAUD 230400

#define PIN 58

void main()
{
    unsigned int pinmask = 1<<(PIN-32);
    unsigned i = 0;

    clkset(_SETFREQ, _CLOCKFREQ);
    _setbaud(BAUD);
    printf("fastspin C demo: clockmode is $%x, clock frequency %u Hz\n", _SETFREQ, _CLOCKFREQ);
    DIRB |= pinmask; // set pins as output
    for(;;) {
        OUTB ^= pinmask;
        waitcnt(getcnt() + CLKFREQ/4);
        printf("toggle %u\n", i++);
    }
}
