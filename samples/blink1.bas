''
'' simple program to blink an LED in BASIC
''
#ifdef __P2__
const ledpin = 56
const _clkmode = 0x10007f8
const _clkfreq = 160_000_000

clkset(_clkmode, _clkfreq)
_setbaud(230400)
#else
const ledpin = 16
#endif

'' set the pin to output
direction(ledpin) = output

do
  output(ledpin) = 1
  pausems 500
  output(ledpin) = 0
  pausems 500
loop
