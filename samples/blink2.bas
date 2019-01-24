''
'' use 2 COGs to blink 2 LEDs (on pins 16 and 17)
''
#ifdef __P2__
const LED1 = 56
const LED2 = 57
const _clkmode = 0x10c3f04
const _clkfreq = 160_000_000

clkset(_clkmode, _clkfreq)
_setbaud(230400)

#else
const LED1 = 16
const LED2 = 17
#endif

'' variable for the stack
dim shared cpustack(8)

'' this is the blink subroutine
'' pin is the pin to blink
'' naptime is the time to wait between transitions
''
sub blinker(pin as uinteger, naptime as uinteger)
  direction(pin) = output
  do
    output(pin) = 1
    pausems naptime
    output(pin) = 0
    pausems naptime
  loop
end sub

'' launch the blinker for LED1 in another COG
'' "500" is the milliseconds to wait
'' "@cpustack(1)" is the start of memory to use for stack
var x = cpu(blinker(LED1, 500), @cpustack(1))

'' blink LED2 slightly faster
blinker(LED2, 400)
