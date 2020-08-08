#include <stdio.h>
#include <stdlib.h>
#include "lisplib.h"
#include "fibo.h"

#ifdef __propeller2__
# ifdef NEED_INLINES
#  error inlines not done
# else
#  include <propeller2.h>
# endif
#else
#include <propeller.h>
#endif


#define ARENA_SIZE 12000

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
#ifdef __propeller2__
    return _cnt();
#else    
    return CNT;
#endif    
}
static intptr_t pinout_fn(intptr_t pin, intptr_t onoff)
{
#ifdef __propeller2__
    if (onoff) {
        _pinh(pin);
    } else {
        _pinl(pin);
    }
    return 0;
#else    
    unsigned mask = 1<<pin;
    DIRA |= mask;
    if (onoff) {
        OUTA |= mask;
    } else {
        OUTA &= ~mask;
    }
    return OUTA;
#endif    
}
static intptr_t pinin_fn(intptr_t pin)
{
#ifdef __propeller2__
    return _pinr(pin);
#else    
    unsigned mask=1<<pin;
    DIRA &= ~mask;
    return (INA & mask) ? 1 : 0;
#endif    
}

LispCFunction defs[] = {
    { "getcnt",    "n",   (GenericFunc)getcnt_fn },
    { "pinout",    "nnn", (GenericFunc)pinout_fn },
    { "pinin",     "nn",  (GenericFunc)pinin_fn },
    { NULL, NULL, (GenericFunc)0 },
};

char arena[ARENA_SIZE];

int
main(int argc, char **argv)
{
    Cell *err;
    int i;

    outstr("proplisp recursive fibo test\n");
    err = Lisp_Init(arena, sizeof(arena));
    for (i = 0; err && defs[i].name; i++) {
        err = Lisp_DefineCFunc(&defs[i]);
    }
    if (err == NULL) {
        printf("Initialization of interpreter failed!\n");
        return 1;
    }
    Lisp_Run((const char *)fibo_lsp, 0);
    return 0;
}
