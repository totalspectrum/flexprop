/*
 * demo for use of LED MATRIX accessory board
 * Written by Eric R. Smith, placed in the public domain
 * compile with
 *    fastspin -2 cdemo.c
 */
#include <stdio.h>
#include <propeller.h>

struct __using("charlieplex_text.spin2") c;

int main()
{
    char buf[80];

    clkset(0x010007f8, 160000000);
    
    c.start();
    for (int i = 2; i < 12; i++) {
        sprintf(buf, "i=%d i*i=%d    ", i, i*i);
        c.str(buf);
        waitcnt(getcnt() + 160000000);
    }
    return 0;
}
