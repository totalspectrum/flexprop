Here are some demos illustrating multi-language programming on the P2
using fastspin, All of them are intended for the P2 EVAL board, and
the video ones do VGA output using the A/V accessory board and with
a base pin of 48. That's easily changed in the source code for each
demo.

hello_c.spin:
   Hello world in Spin, using the C standard library.
   
led_interactive.bas:
   A simple BASIC program to control a PASM program running in another
   COG (it can light 4 LEDs based on a number from 0-15).

mandelbrot.c:
   Fancy graphical mandelbrot fractal display; written in C, uses
   Roger Loh's Spin video driver.

pure_pasm.spin2:
pure_pasm.c:
   Pure PASM code. Illustrates how you can embed PASM in C.

turtle_demo.bas:
   Turtle graphics demo in BASIC using Roger Loh's video driver (Spin)
   and a C turtle graphics library. Also illustrates use of the 9P
   file server for saving screenshots.

Helper objects:

video:
   Roger Loh's excellent video driver for the P2. Written in Spin. See
   the various files within the directory.

turtle:
   A GPL'd turtle graphics library.
