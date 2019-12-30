#include <stdio.h>
#include <stdint.h>

struct biglong {
    uint32_t lo;
    uint32_t hi;
};

static void getcounter(struct biglong *b) {
    uint32_t hi, lo;
    asm {
        getct hi wc
        getct lo
    };
    b->hi = hi;
    b->lo = lo;
}

void main() {
    struct biglong b;
    
    for(;;) {
        getcounter(b);
        printf("counter= %08lx : %08lx\n", b->hi, b->lo);
        waitcnt(_getcnt() + 160000000);
    }
}
