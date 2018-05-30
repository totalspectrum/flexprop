'' simple hello world program
CON
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000

OBJ
  ser: "SimpleSerial"

PUB hello
  ser.start(115_200)
  repeat
    ser.str(string("hello, world!", 13, 10))
