'' simple hello world program

CON
#ifdef __P2__
  mode = $010007f8
  freq = 160_000_000
  baud = 230_400
  rx_pin = 63
  tx_pin = 62
#else
  mode = xtal1 + pll16x
  freq = 80_000_000
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
  clkset(mode, freq)
  ser.start(rx_pin, tx_pin, 0, baud)
  repeat
    ser.printf("Hello, world!\n")

