''
'' simple program to blink an LED in BASIC
''
#ifdef __P2__
const ledpin = 56               ' LED to blink (P2)
const _clkfreq = 160_000_000
#else
const ledpin = 16               ' LED to blink (P1)
#endif

'' set the pin to output
direction(ledpin) = output

do
  output(ledpin) = 1            ' set pin high
  pausems 500                   ' wait 1/2 second
  output(ledpin) = 0            ' set pin low
  pausems 500                   ' wait 1/2 second
loop
