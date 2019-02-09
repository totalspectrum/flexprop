/*
 *
 * Copyright (c) 2017-2019 by Dave Hein
 * Based on p2load written by David Betz
 *
 * MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "osint.h"

#define LOAD_CHIP   0
#define LOAD_FPGA   1
#define LOAD_SINGLE 2

static int loader_baud = 2000000;
static int clock_mode = -1;
static int user_baud = 115200;
static int clock_freq = 80000000;
static int extra_cycles = 7;
static int load_mode = -1;
static int patch_mode = 0;
static int use_checksum = 1;

int get_loader_baud(int ubaud, int lbaud);

#if defined(__CYGWIN__) || defined(__MINGW32__) || defined(__MINGW64__)
  #define PORT_PREFIX "com"
#elif defined(__APPLE__)
  #define PORT_PREFIX "/dev/cu.usbserial"
#else
  #define PORT_PREFIX "/dev/ttyUSB"
#endif

char *MainLoader =
" 00 1e 60 fd 13 00 88 fc 20 7e 65 fd 24 08 60 fd 24 28 60 fd 1f 20 60 fd 08 06 dc fc 40 7e 74 fd 01 28 84 f0 1f 22 60 fd 18 28 44 f0 15 28 60 fd f6 25 6c fb 00 00 7c fc 13 00 e8 fc";

char *MainLoader1 =
" 00 26 60 fd 86 01 80 ff 1f 80 66 fd 03 26 44 f5 00 26 60 fd 17 00 88 fc 20 7e 65 fd 24 08 60 fd 24 28 60 fd 1f 28 60 fd 08 06 dc fc 40 7e 74 fd 01 30 84 f0 1f 2a 60 fd 18 30 44 f0 15 30 60 fd f6 2d 6c fb 00 00 7c fc 17 00 e8 fc";

static int32_t ibuf[256];
static int32_t ibin[32];
static char *buffer = (char *)ibuf;
static char *binbuffer = (char *)ibin;
static int verbose = 0;
static int waitAtExit = 0;

/* promptexit: print a prompt if waitAtExit is set, then exit */
void
promptexit(int r)
{
    int c;
    if (waitAtExit) {
        fflush(stderr);
        printf("Press enter to continue...\n");
        fflush(stdout);
        do {
            c = getchar();
        } while (c > 0 && c != '\n' && c != '\r');
    }
    exit(r);
}

/* Usage - display a usage message and exit */
static void Usage(void)
{
printf("\
loadp2 - a loader for the propeller 2 - version 0.013, 2019-02-06\n\
usage: loadp2\n\
         [ -p port ]               serial port\n\
         [ -b baud ]               user baud rate (default is %d)\n\
         [ -l baud ]               loader baud rate (default is %d)\n\
         [ -f clkfreq ]            clock frequency (default is %d)\n\
         [ -m clkmode ]            clock mode in hex (default is %02x)\n\
         [ -s address ]            starting address in hex (default is 0)\n\
         [ -t ]                    enter terminal mode after running the program\n\
         [ -T ]                    enter PST-compatible terminal mode\n\
         [ -v ]                    enable verbose mode\n\
         [ -k ]                    wait for user input before exit\n\
         [ -? ]                    display a usage message and exit\n\
         [ -CHIP ]                 set load mode for CHIP\n\
         [ -FPGA ]                 set load mode for FPGA\n\
         [ -SINGLE ]               set load mode for single stage\n\
         [ -PATCH ]                patch in clock frequency and serial parms\n\
         file                      file to load\n", user_baud, loader_baud, clock_freq, clock_mode);
    promptexit(1);
}

void txval(int val)
{
    sprintf(buffer, " %2.2x %2.2x %2.2x %2.2x",
        val&255, (val >> 8) & 255, (val >> 16) & 255, (val >> 24) & 255);
    tx((uint8_t *)buffer, strlen(buffer));
}

int compute_checksum(int *ptr, int num)
{
    int checksum = 0;

    while (num-- > 0)
        checksum += *ptr++;

    return checksum;
}

int loadfilesingle(char *fname)
{
    FILE *infile;
    int num, size, i;
    int patch = patch_mode;
    int totnum = 0;
    int checksum = 0;
    
    infile = fopen(fname, "rb");
    if (!infile)
    {
        printf("Could not open %s\n", fname);
        return 1;
    }
    fseek(infile, 0, SEEK_END);
    size = ftell(infile);
    fseek(infile, 0, SEEK_SET);
    if (verbose) printf("Loading %s - %d bytes\n", fname, size);
    hwreset();
    msleep(50);
    tx((uint8_t *)"> Prop_Hex 0 0 0 0", 18);

    while ((num=fread(binbuffer, 1, 128, infile)))
    {
        if (patch)
        {
            patch = 0;
            memcpy(&binbuffer[0x14], &clock_freq, 4);
            memcpy(&binbuffer[0x18], &clock_mode, 4);
            memcpy(&binbuffer[0x1c], &user_baud, 4);
        }
        if (use_checksum)
        {
            num = (num + 3) & ~3;
            checksum += compute_checksum(ibin, num/4);
        }
        for( i = 0; i < num; i++ )
            sprintf( &buffer[i*3], " %2.2x", binbuffer[i] & 255 );
        strcat(buffer, " > ");
        tx( (uint8_t *)buffer, strlen(buffer) );
        totnum += num;
    }
    if (use_checksum)
    {
        char *ptr = (char *)&checksum;
        checksum = 0x706f7250 - checksum;
        for( i = 0; i < 4; i++ )
            sprintf( &buffer[i*3], " %2.2x", ptr[i] & 255 );
        tx( (uint8_t *)buffer, strlen(buffer) );
        tx((uint8_t *)"?", 1);
        wait_drain();
        num = rx_timeout((uint8_t *)buffer, 1, 100);
        if (num >= 0) buffer[num] = 0;
        else buffer[0] = 0;
        if (strcmp(buffer, "."))
        {
            printf("%s failed to load\n", fname);
            printf("Error response was \"%s\"\n", buffer);
            promptexit(1);
        }
        if (verbose)
            printf("Checksum validated\n");
    }
    else
    {
        tx((uint8_t *)"~", 1);   // Added for Prop2-v28
        wait_drain();
    }

    msleep(50);
    if (verbose) printf("%s loaded\n", fname);
    return 0;
}

int loadfile(char *fname, int address)
{
    FILE *infile;
    int num, size;
    int totnum = 0;
    int patch = patch_mode;
    
    if (load_mode == LOAD_SINGLE)
        return loadfilesingle(fname);

    infile = fopen(fname, "rb");
    if (!infile)
    {
        printf("Could not open %s\n", fname);
        return 1;
    }
    fseek(infile, 0, SEEK_END);
    size = ftell(infile);
    fseek(infile, 0, SEEK_SET);
    if (verbose) printf("Loading %s - %d bytes\n", fname, size);
    hwreset();
    msleep(50);
    tx((uint8_t *)"> Prop_Hex 0 0 0 0", 18);
    if (load_mode == LOAD_FPGA)
        tx((uint8_t *)MainLoader, strlen(MainLoader));
    else
        tx((uint8_t *)MainLoader1, strlen(MainLoader1));
    txval(clock_mode);
    txval((3*clock_freq+loader_baud)/(loader_baud*2)-extra_cycles);
    txval((clock_freq+loader_baud/2)/loader_baud-extra_cycles);
    txval(size);
    txval(address);
    tx((uint8_t *)"~", 1);
    msleep(100);
    while ((num=fread(buffer, 1, 1024, infile)))
    {
        if (patch)
        {
            patch = 0;
            memcpy(&buffer[0x14], &clock_freq, 4);
            memcpy(&buffer[0x18], &clock_mode, 4);
            memcpy(&buffer[0x1c], &user_baud, 4);
        }
        tx((uint8_t *)buffer, num);
        totnum += num;
    }
    wait_drain();
    msleep(50);
    if (verbose) printf("%s loaded\n", fname);
    return 0;
}

int findp2(char *portprefix, int baudrate)
{
    int i, num;
    char Port[100];
    char buffer[101];

    if (verbose) printf("Searching serial ports for a P2\n");
    for (i = 0; i < 20; i++)
    {
        sprintf(Port, "%s%d", portprefix, i);
        if (serial_init(Port, baudrate))
        {
            hwreset();
            msleep(50);
            tx((uint8_t *)"> Prop_Chk 0 0 0 0  ", 20);
            msleep(50);
            num = rx_timeout((uint8_t *)buffer, 100, 10);
            if (num >= 0) buffer[num] = 0;
            else buffer[0] = 0;
            if (!strncmp(buffer, "\r\nProp_Ver ", 11))
            {
                if (verbose) printf("P2 version %c found on serial port %s\n", buffer[11], Port);
                if (load_mode == -1)
                {
                    if (buffer[11] == 'A')
                    {
                        load_mode = LOAD_CHIP;
                        if (verbose) printf("Setting load mode to CHIP\n");
                    }
                    else if (buffer[11] == 'B')
                    {
                        load_mode = LOAD_FPGA;
                        if (verbose) printf("Setting load mode to FPGA\n");
                    }
                    else
                    {
                        printf("Unknown version %c\n", buffer[11]);
                        exit(1);
                    }
                }
                return 1;
            }
            serial_done();
        }
    }
    return 0;
}

int atox(char *ptr)
{
    int value;
    sscanf(ptr, "%x", &value);
    return value;
}

int get_clock_mode(int sysfreq)
{
    int xtalfreq = 20000000;
    int xdiv = 4;
    int xdivp = 2;
    int xosc = 2;
    int xmul, xpppp, setfreq;
    //int xsel = 3;
    //int enafreq;

    if (sysfreq > 180)
    {
        xdiv = 10;
        xdivp = 1;
    }

    xmul = sysfreq/100*xdiv*xdivp/(xtalfreq/100);

    xpppp = ((xdivp >> 1) + 15) & 0xf;
    setfreq = (1 << 24) + ((xdiv-1) << 18) + ((xmul - 1) << 8) + (xpppp << 4) + (xosc << 2);
    //enafreq = setfreq + xsel;

    //printf("SYSFREQ = %d, XMUL = %d, SETFREQ = %8.8x, ENAFREQ = %8.8x\n", sysfreq, xmul, setfreq, enafreq);
    //printf("VCOFREQ = %d\n", xtalfreq/xdiv*xmul);

    return setfreq;
}

int main(int argc, char **argv)
{
    int i;
    int runterm = 0;
    int pstmode = 0;
    char *fname = 0;
    char *port = 0;
    int address = 0;

    // Initialize the loader baud rate
    loader_baud = get_loader_baud(user_baud, loader_baud);

    // Parse the command-line parameters
    for (i = 1; i < argc; i++)
    {
        if (argv[i][0] == '-')
        {
            if (argv[i][1] == 'p')
            {
                if(argv[i][2])
                    port = &argv[i][2];
                else if (++i < argc)
                    port = argv[i];
                else
                    Usage();
            }
            else if (argv[i][1] == 'b')
            {
                if(argv[i][2])
                    user_baud = atoi(&argv[i][2]);
                else if (++i < argc)
                    user_baud = atoi(argv[i]);
                else
                    Usage();
            }
            else if (argv[i][1] == 'l')
            {
                if(argv[i][2])
                    loader_baud = atoi(&argv[i][2]);
                else if (++i < argc)
                    loader_baud = atoi(argv[i]);
                else
                    Usage();
            }
            else if (argv[i][1] == 'X')
            {
                if(argv[i][2])
                    extra_cycles = atoi(&argv[i][2]);
                else if (++i < argc)
                    extra_cycles = atoi(argv[i]);
                else
                    Usage();
            }
            else if (argv[i][1] == 'f')
            {
                if(argv[i][2])
                    clock_freq = atoi(&argv[i][2]);
                else if (++i < argc)
                    clock_freq = atoi(argv[i]);
                else
                    Usage();
            }
            else if (argv[i][1] == 'k')
            {
                waitAtExit = 1;
            }
            else if (argv[i][1] == 'm')
            {
                if(argv[i][2])
                    clock_mode = atox(&argv[i][2]);
                else if (++i < argc)
                    clock_mode = atox(argv[i]);
                else
                    Usage();
            }
            else if (argv[i][1] == 's')
            {
                if(argv[i][2])
                    address = atox(&argv[i][2]);
                else if (++i < argc)
                    address = atox(argv[i]);
                else
                    Usage();
            }
            else if (argv[i][1] == 't')
                runterm = 1;
            else if (argv[i][1] == 'T')
                runterm = pstmode = 1;
            else if (argv[i][1] == 'v')
                verbose = 1;
            else if (!strcmp(argv[i], "-PATCH"))
                patch_mode = 1;
            else if (!strcmp(argv[i], "-CHIP"))
                load_mode = LOAD_CHIP;
            else if (!strcmp(argv[i], "-FPGA"))
                load_mode = LOAD_FPGA;
            else if (!strcmp(argv[i], "-SINGLE"))
                load_mode = LOAD_SINGLE;
            else
            {
                printf("Invalid option %s\n", argv[i]);
                Usage();
            }
        }
        else
        {
            if (fname) Usage();
            fname = argv[i];
        }
    }

    if (!fname && (!port || !runterm)) Usage();

    // Determine the user baud rate
    if (user_baud == -1)
    {
        user_baud = clock_freq / 10 * 9 / 625;
        if (verbose) printf("Setting user_baud to %d\n", user_baud);
    }

    // Determine the P2 serial port
    if (!port)
    {
        if (!findp2(PORT_PREFIX, loader_baud))
        {
            printf("Could not find a P2\n");
            promptexit(1);
        }
    }
    else if (1 != serial_init(port, loader_baud))
    {
        printf("Could not open port %s\n", port);
        promptexit(1);
    }
    
    if (fname)
    {
        if (load_mode == LOAD_CHIP)
        {
            if (clock_mode == -1)
            {
                clock_mode = get_clock_mode(clock_freq);
                if (verbose) printf("Setting clock_mode to %x\n", clock_mode);
            }
        }
        else if (load_mode == LOAD_FPGA)
        {
            int temp = clock_freq / 312500; // * 256 / 80000000
            int temp1 = temp - 1;
            if (clock_mode == -1)
            {
                clock_mode = temp1;
                if (verbose) printf("Setting clock_mode to %x\n", temp1);
            }
        }
        else if (load_mode == -1)
        {
            load_mode = LOAD_SINGLE;
            if (verbose) printf("Setting load mode to SINGLE\n");
        }

        if (loadfile(fname, address))
        {
            serial_done();
            promptexit(1);
        }
    }

    if (runterm)
    {
        serial_baud(user_baud);
        printf("( Entering terminal mode.  Press Ctrl-] to exit. )\n");
        terminal_mode(1,pstmode);
        waitAtExit = 0; // no need to wait, user explicitly quite
    }

    serial_done();
    promptexit(0);
}
