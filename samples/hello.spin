'' simple hello world program

CON
#ifdef __P2__
  mode = $010007f8
  freq = 160_000_000
  baud = 230_400
  rx_pin = 63
  tx_pin = 62
#else
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000
  baud = 115_200
  rx_pin = 31
  tx_pin = 30
#endif

OBJ
#ifdef __P2__
  ser: "spin/SmartSerial"
#else
  ser: "spin/FullDuplexSerial"
#endif

PUB hello
#ifdef __P2__
  clkset(mode, freq)
#endif  
  ser.start(rx_pin, tx_pin, 0, baud)
  repeat
    ser.printf("Hello, world!\n")

