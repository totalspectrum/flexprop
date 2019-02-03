'' simple hello world program

CON
#ifdef __P2__
  mode = $010007f8
  freq = 160_000_000
  baud = 230_400
#else
  mode = xtal1 + pll16x
  freq = 80_000_000
  baud = 115_200
#endif

OBJ
  ser: "SimpleSerial"

PUB hello
  clkset(mode, freq)
  ser.start(baud)
  repeat
    ser.str(string("Hello, world!", 13, 10))
