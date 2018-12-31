'' simple hello world program
'' this is tested on P1 only
CON
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000

OBJ
  ser: "SimpleSerial"

PUB hello
  ser.start(115_200)
  repeat
    ser.str(string("Hello, world!", 13, 10))
