//
// simple test program for 9p access to host files
// reads the "fs9p.h" file from this directory
//

#ifndef __P2__
#error this demo is for P2 only
#endif
#ifndef _BAUD
#define _BAUD 230400
#endif

#include <string.h>
#include <stdint.h>
#include "fs9p.h"

struct __using("spin/SmartSerial") ser;

// receive 1 byte
unsigned int doGet1()
{
    int c;
    do {
        c = ser.rx();
    } while (c < 0);
    return c;
}

// receive an unsigned long
unsigned doGet4()
{
    unsigned r;
    r = doGet1();
    r = r | (doGet1() << 8);
    r = r | (doGet1() << 16);
    r = r | (doGet1() << 24);
    return r;
}

// send a buffer to the host
// then receive a reply
// returns the length of the reply, which is also the first
// longword in the buffer
//
// startbuf is that start of the buffer (used for both send and
// receive); endbuf is the end of data to send; maxlen is maximum
// size
int serSendRecv(uint8_t *startbuf, uint8_t *endbuf, int maxlen)
{
    int len = endbuf - startbuf;
    uint8_t *buf = startbuf;
    int i = 0;
    int left;
    
    startbuf[0] = len & 0xff;
    startbuf[1] = (len>>8) & 0xff;
    startbuf[2] = (len>>16) & 0xff;
    startbuf[3] = (len>>24) & 0xff;

    if (len <= 4) {
        return -1; // not a valid message
    }
    // loadp2's server looks for magic start sequence of $FF, $01
    ser.tx(0xff);
    ser.tx(0x01);
    while (len>0) {
        ser.tx(*buf++);
        --len;
    }
    len = doGet4();
    startbuf[0] = len & 0xff;
    startbuf[1] = (len>>8) & 0xff;
    startbuf[2] = (len>>16) & 0xff;
    startbuf[3] = (len>>24) & 0xff;
    buf = startbuf+4;
    left = len - 4;
    while (left > 0 && i < maxlen) {
        buf[i++] = doGet1();
        --left;
    }
    return len;
}

fs_file testfile;

// test program
int main()
{
    int r;
    char buf[80];
    _clkset(0x010007f8, 160000000);
    ser.start(63, 62, 0, _BAUD);
    ser.printf("9p test program...\r\n");
    ser.printf("Initializing...\r\n");
    r = fs_init(serSendRecv);
//    ser.printf("Init returned %d\n", r);
//    pausems(1000);
    if (r == 0) {
        r = fs_open(&testfile, (char *)"fs9p.h", 0);
        pausems(10);
        ser.printf("fs_open returned %d\r\n", r);
    }
    if (r == 0) {
        int i;
        int c;
        // read the file and show it
        ser.printf("FILE CONTENTS:\r\n");
        pausems(100);
        do {
            r = fs_read(&testfile, buf, sizeof(buf));
            for (i = 0; i < r; i++) {
                c = buf[i];
                if (c == 10)
                    ser.tx(13);
                if (c != 13)
                    ser.tx(c);
            }
        } while (r > 0);
        pausems(10);
        ser.printf("EOF\r\n");
        fs_close(&testfile);
    }
    return 0;
}
