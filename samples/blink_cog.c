//
// blink an LED using another COG
//

#include <stdio.h>
#include <propeller2.h>

// define the pin to blink
#ifdef __P2__
#define BASEPIN 56
#else
#define BASEPIN 16
#endif

// define the delay between toggles
#define TOGGLE_DELAY 40'000'000

// size of stack for other COG bytes (should be at least 128)
#define STACKSIZE 256

unsigned char stack[256];

// arguments passed to the new COG
// in this case, we pass a pin number and delay
typedef struct cogargs {
    unsigned pin;
    unsigned delay;
} CogArgs;

// function to blink a pin
// the argument is passed as a "void *", but it's really a "CogArgs *"
void blink(void *arg_p)
{
    CogArgs *arg = (CogArgs *)arg_p;
    int pin = arg->pin;
    unsigned delay = arg->delay;

    // now just loop toggling the pin
    for(;;) {
        _pinnot(pin);
        _waitx(delay);
    }
}

// and now the main program
void main()
{
    CogArgs x;
    int cog;
    
    x.pin = BASEPIN;
    x.delay = TOGGLE_DELAY;
    cog = _cogstart_C(blink, &x, stack, sizeof(stack));
    printf("started cog %d to blink pin %d\n", cog, x.pin);

    // we could do other things here (like blink a different pin)
    for(;;)
        ;
}
