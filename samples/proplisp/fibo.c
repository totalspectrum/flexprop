#include <stdio.h>
#include <stdlib.h>
#include "lisplib.h"
#include "fibo.h"

#include <propeller.h>
#ifdef __P2__
#define P2_TARGET_MHZ 160
#include "sys/p2es_clock.h"
#define ARENA_SIZE 32768
#else
#define ARENA_SIZE 16000
#endif

int inchar() {
    return -1;
}
void outchar(int c) {
    if (c == '\n') {
        putchar('\r');
    }
    putchar(c);
}
void outstr(const char *s) {
    while (*s != 0) putchar(*s++);
}
int peekchar() { return -1; }

static intptr_t getcnt_fn()
{
    return CNT;
}
// wait for ms millisconds
static intptr_t waitms_fn(intptr_t ms)
{
#ifdef __FLEXC__
    pausems(ms);
#else    
    usleep(ms * 1000);
#endif    
    return ms;
}
static intptr_t pinout_fn(intptr_t pin, intptr_t onoff)
{
    unsigned mask = 1<<pin;
    DIRA |= mask;
    if (onoff) {
        OUTA |= mask;
    } else {
        OUTA &= ~mask;
    }
    return OUTA;
}
static intptr_t pinin_fn(intptr_t pin)
{
    unsigned mask=1<<pin;
    DIRA &= ~mask;
    return (INA & mask) ? 1 : 0;
}

LispCFunction defs[] = {
    { "getcnt",    "n",   (GenericFunc)getcnt_fn },
    { "pinout",    "nnn", (GenericFunc)pinout_fn },
    { "pinin",     "nn",  (GenericFunc)pinin_fn },
    { "waitms",    "nn", (GenericFunc)waitms_fn },
    { NULL, NULL, NULL },
};

char arena[ARENA_SIZE];

int
main(int argc, char **argv)
{
    Cell *err;
    int i;

#ifdef __P2__
    clkset(_SETFREQ, _CLOCKFREQ);
    _setbaud(230400);
    pausems(100);
#endif
    outstr("proplisp recursive fibo test\n");
    err = Lisp_Init(arena, sizeof(arena));
    for (i = 0; err && defs[i].name; i++) {
        err = Lisp_DefineCFunc(&defs[i]);
    }
    if (err == NULL) {
        printf("Initialization of interpreter failed!\n");
        return 1;
    }
    Lisp_Run(fibo_lsp, 0);
    return 0;
}
