// simple demo illustrating use of 64 bit cycle counter
// on Propeller 2

#include <stdio.h>
#include <stdint.h>

// struct to hold 64 bits
struct biglong {
    uint32_t lo;
    uint32_t hi;
};

// get the whole 64 bit counter
static void getcounter(struct biglong *b) {
    uint32_t hi, lo;
    __asm {
        getct hi wc
        getct lo
    };
    b->hi = hi;
    b->lo = lo;
}

// and the main program
void main() {
    struct biglong b;
    
    for(;;) {
        getcounter(&b);
        printf("counter= %08lx : %08lx\n", b.hi, b.lo);
        waitcnt(_getcnt() + 160000000);
    }
}
