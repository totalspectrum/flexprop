#ifndef __propeller2__
#error this demo is for prop2 only
#endif

con
  _clkfreq = 180_000_000 ' define P2 clock frequency
  
var
  long stack1[16]  ' a stack for the first COG to run
  long stack2[16]  ' a stack for the second COG to run
  
pub demo
  cognew(runblink(56, _clkfreq/4), @stack1) ' start a COG to blink pin 56
  cognew(runblink(57, _clkfreq/10), @stack2) ' start a COG to blink pin 57
  runblink(58, _clkfreq/3) ' now blink pin 58 in this COG

pub runblink(pin, delay)
  repeat
    pintoggle(pin)
    waitx(delay)
