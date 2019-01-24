// P2 blinking lights and serial demo
// this requires a P2-EVAL board

#include <stdio.h>
#include <propeller.h>

#define FREQ 160000000
#define OSCMODE 0x10c3f04
#define BAUD 230400

#define PIN 58

void main()
{
    unsigned int pinmask = 1<<(PIN-32);
    unsigned i = 0;

    clkset(OSCMODE, FREQ);
    _setbaud(BAUD);
    printf("fastspin C demo\n");
    DIRB |= pinmask; // set pins as output
    for(;;) {
        OUTB ^= pinmask;
        waitcnt(getcnt() + CLKFREQ/4);
        printf("toggle %u\n", i++);
    }
}
