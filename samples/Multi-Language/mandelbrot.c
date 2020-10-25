//
// Simple Mandelbrot demo program
// Written by Eric R. Smith, based on code by forum user yeti
// Distributed under the MIT License
//
#include <stdio.h>
#include <propeller2.h>
#include <stdlib.h>

//
// global definitions
//

// if defined, use fixed point math
// the number of bits of precision is given here
// make sure the numbers won't overflow before increasing this!
#define FIXED_POINT 24

// baud rate for serial
#ifndef _BAUD
#define _BAUD 230400
#endif

// max number of CPUs to use
#define MAXCPUs 6
    
// size of stack for each CPU
#define STACKSIZE 80

// screen size
#define SCRN_WIDTH 640
#define SCRN_HEIGHT 480

// VGA definitions
#define VGA_BASE_PIN 48
#define VGA_VSYNC_PIN (VGA_BASE_PIN + 4)

// enough room for a scanline at full colour bit depth
#define LINEBUFSIZE (1920*4)

// the video object
struct __using("video/p2videodrv.spin2") vid;

// space for video driver display and region info
int display1[14];
int first[14];

// the actual frame and line buffer
char frameBuffer[SCRN_WIDTH*SCRN_HEIGHT];
int lineBuffer[LINEBUFSIZE];

// variable: number of CPUs to use in rendering
int NUMCPUs;

// stack for running other COGS
int stack[STACKSIZE*MAXCPUs];

// forward declarations
void Setup_Video(void);
void rendermandel(int offset);

//'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// math helpers
//'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
#ifdef FIXED_POINT

// conversion utilities to/from fixed point for
// fixed point numbers with FIXED_POINT bits of precision
typedef int Real;

Real toReal(float a)
{
    return (int)(a * (float)(1<<FIXED_POINT));
}

float fromReal(Real a)
{
    return ((float)a) / (float)(1<<FIXED_POINT);
}

// simple routine to square a
Real square(Real a)
{
    // full precision
    unsigned hi, lo;
    __asm {
        abs a
        qmul a, a
        getqx lo
        getqy hi
    };
    return (hi<<(32-FIXED_POINT)) | (lo>>FIXED_POINT);
}
#else
typedef float Real;

Real toReal(float a)
{
    return a;
}
float fromReal(Real a)
{
    return a;
}

Real square(Real a)
{
    return a*a;
}
#endif

//'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// main program
//'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
int main()
{
    int i;
    int cog; // cog number of helper cog
    char buf[80], *ptr;  // space for user input string
    
    Setup_Video();

    _setbaud(_BAUD);
    
    printf("Mandelbrot test program\n");
    _waitms(1);

    // start up with just one CPU
    NUMCPUs = 1;
    
    // now loop and do the rendering
    for(;;) {
        printf("rendering with %d cogs\n", NUMCPUs);

        // clear the screen
        memset(frameBuffer, 0, SCRN_WIDTH*SCRN_HEIGHT);
        
        // launch helper  CPUs
        // the helper function rendermandel takes a void * (as do all
        // COG functions) hence the (void *) cast
        
        for (i = 1; i < NUMCPUs; i++) {
            cog = _cogstart(rendermandel, (void *)i, &stack[(i-1)*STACKSIZE], STACKSIZE);
            printf("started cog %d\n", cog);
        }
        rendermandel((void *)0);

        // read user input
        printf("Enter # of CPUs to use this time: ", NUMCPUs);
        ptr = fgets(buf, sizeof(buf), stdin);
        if (!ptr) break;

        // convert to integer
        NUMCPUs = atoi(ptr);

        // sanity check
        if (NUMCPUs < 1) {
            NUMCPUs = 1;
        } else if (NUMCPUs > MAXCPUs) {
            NUMCPUs = MAXCPUs;
        }
    }
}

// routine to plot a point at screen coordinate (x,y) and color "color"
void plot(int x, int y, int color)
{
    frameBuffer[y*SCRN_WIDTH+x] = color;
}

//
// the actual Mandelbrot renderer program
// this isn't very well commented, sorry, but you can find
// the Mandelbrot set algorithm on the web
// To enable 2 cpu rendering, each cpu does every other line;
// for 3 cpus, every 3rd line; etc. We have to know which line
// to start on (the "offset") but otherwise all the CPUs can follow
// the same algorithm
//
// a slightly odd point: the prototype for _cogstart requires that
// the function being called take a void * parameter (normally used
// to pass a pointer to a mailbox). We only need one parameter, so
// we'll actually pass the offset in that and cast it to integer.
//
void rendermandel(void *arg)
{
    int offset = (int)arg;
    int skip = NUMCPUs;  // each CPU can skip the others' lines
    const Real xmin = toReal(-2.1);
    const Real xmax =  toReal(0.7);

    const Real ymin = toReal(-1.2);
    const Real ymax = toReal(1.2);

    const Real c4 = toReal(4.0); // square of escape radius
    
    const int maxiter = 32;


    Real dx, dy;
    Real x, y, x2, y2, cx, cy;
    
    int iter, color;
    int px, py;
    
    dx = toReal( fromReal(xmax - xmin) / SCRN_WIDTH );
    dy = toReal( fromReal(ymax - ymin) / SCRN_HEIGHT );
  
    cy = ymin + offset*dy;
    dy = skip * dy;

    for (py = offset; py < SCRN_HEIGHT; py += skip) {
        cx = xmin;
        for (px = 0; px < SCRN_WIDTH; px++) {
            x = 0;
            y = 0;
            x2 = 0;  // value of x^2
            y2 = 0;  // value of y^2
            iter = 0;
            while (iter < maxiter && x2+y2 <= c4) {
                //y = cy + (2.0*x*y);
                y = cy + (square(x+y) - x2 - y2);
                x = cx + (x2-y2);
                iter = iter+1;
                x2 = square(x);
                y2 = square(y);
            }
            cx = cx+dx;
            if (iter == maxiter) {
                // actual mandelbrot set is in black
                color = 0;
            } else {
                // set the color based on number of iterations
                // we're using RGBI color space
                //color = iter; // shades of a kind of orange
                //color = iter + 0b100_00000; // shades of red
                color = iter + 0b010_00000; // shades of green
                //color = iter + 0b010_00000; // shades of blue
                //color = iter + 0b111_00000; // greyscale
            }
            plot(px, py, color);
        }
        cy = cy+dy;
    }
}

//'''''''''''''''''''''''''''''''''''''''''''''''''''''''
//'' video setup code
//'' creates a 640x480 screen
//'''''''''''''''''''''''''''''''''''''''''''''''''''''''

void Setup_Video()
{
    vid.initDisplay(&display1, vid.VGA, VGA_BASE_PIN, VGA_VSYNC_PIN, vid.RGBHV, &lineBuffer[0], LINEBUFSIZE, 0);

    vid.initRegion(&first, vid.RGBI, 480, 0, 0, 0, 8, &frameBuffer[0], 0);
  
    // enable display list
    vid.setDisplayRegions(display1, first);
}
