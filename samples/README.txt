Here are some PASM, Spin, C, and Basic examples that you can try out
in spin2gui. They're all designed to work on the P2ES board, although
most will work on a Propeller1 board as well. Generally the samples
use #ifdef __P2__ to determine whether they are on a P2 or a P1.

blink1.bas: BASIC program to blink an LED
blink1.spin2: Same but for Spin (Only works on P2)
blink2.bas: BASIC program using 2 COGs to blink 2 LEDs
blink_all_cogs.spin: blink 8 LEDs using 8 COGs
classic.bi: header file to assist in compiling old BASIC programs
cdemo.c: C program to blink a pin and print a message on the terminal
fibo.bas: Recursive Fibonacci in BASIC
fibo.spin: Recursive Fibonacci in Spin
hello.spin: Print "Hello world" on the terminal
led_server_asm.c: Run an LED blinker in another COG (with C style assembly)
led_server_pasm.c: Run an LED blinker in another COG (with Spin style assembly)
led_server.bas: Run an LED blinker in another COG (BASIC version)
lunar.bas: Old-style BASIC program; land a rocket on the moon
multest.spin2: Test multiply speed on P2
  multiply.spin: routines used by multest.spin2
  multiply.cog.spin: multiply.spin running in its own COG
rtc.bas: simple real-time clock using a COG to keep track of time
smartpin.spin2: Print to serial port using smart pins

LED_Matrix: Samples for the P2 LED Matrix accessory board

proplisp: Lisp interpreter written in C
  proplisp/README.md: Documentation
  proplisp/lisp.c: Interactive interpreter
  proplisp/fibo.c: Recursive fibonacci in Lisp

upython: MicroPython interpreter for P2
  This is a binary-only package, which may be run using the `Special`
  menu or the `Run Binary` button. See the README for some information
  on micropython features.
  
