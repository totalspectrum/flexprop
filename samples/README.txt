Here are some PASM, Spin, C, and Basic examples that you can try out
in spin2gui. They're all designed to work on the P2ES board, although
most will work on a Propeller1 board as well. Generally the samples
use #ifdef __P2__ to determine whether they are on a P2 or a P1.

blink1.bas:     BASIC program to blink an LED
blink1.spin2:   Same but for Spin (Only works on P2)
blink2.bas:     BASIC program using 2 COGs to blink 2 LEDs
blink3.spin:    Spin program to blink 3 LEDs using Spin method
blink_all_cogs.spin: blink 8 LEDs using 8 COGs
classic.bi:     header file to assist in compiling old BASIC programs
cdemo.c:        C program to blink a pin and print a message on the terminal
c_time.c:       C program to illustrate settimeofday/gettimeofday
fibo.bas:       Recursive Fibonacci in BASIC
fibo.spin:      Recursive Fibonacci in Spin
hello.spin:     Print "Hello world" on the terminal
led_server_asm.c: Run an LED blinker in another COG (with C style assembly)
led_server_pasm.c: Run an LED blinker in another COG (with Spin style assembly)
led_server.bas: Run an LED blinker in another COG (BASIC version)
lunar.bas:      Old-style BASIC program; land a rocket on the moon
mandelbrot.bas: Display a Mandelbrot set on a terminal 
multest.spin:   Test multiply speed on P2
  multiply.spin: routines used by multest.spin2
  multiply.cog.spin: multiply.spin running in its own COG
rtc.bas:        Simple real-time clock using a COG to keep track of time
smartpin.spin:  Print to serial port using smart pins (P2 only)
timer.c:        Shows use of the 64 bit counter on P2

fileserver: Samples for the loadp2 9P file server
  ls.spin:  list the current directory
  test9p.c: read the file "fs9p.h"
  writer.bas: writes a file "hello.txt"
  
LED_Matrix: Samples for the P2 LED Matrix accessory board

Multi-Language:
  Various programs to illustrate programming in PASM, Spin, C,
  and BASIC. Also included is Roger Loh's P2 video driver.
  
proplisp: Lisp interpreter written in C
  README.md: Documentation
  lisp.c: Interactive interpreter
  fibo.c: Recursive fibonacci in Lisp

upython: MicroPython interpreter for P2
  This is a binary-only package, which may be run using the `Special`
  menu or the `Run Binary` button. See the README for some information
  on micropython features.
  
vga: Simple VGA text
  This is a demo of ANSI compatible VGA text output.
