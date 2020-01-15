'
' simple smart pin serial demo for P2 Eval board
' The "smart pin" code is in include/spin/SmartSerial.spin
'
#ifndef _BAUD
#define _BAUD 230_400
#endif

CON
  _clkfreq = 160_000_000
  baud = _BAUD

OBJ
  ser: "spin/SmartSerial"

VAR
  BYTE name[128]

PUB demo
  ser.start(63, 62, 0, baud)
  ser.printf("Hello, there! What is your name? ")
  getname
  ser.printf("Nice to meet you %s\n", @name)
  waitms(1000)

PUB getname | c, i
  i := 0
  repeat
    c := ser.rx
    if (c == 8)
      if i > 0
        --i
        ser.tx(c)
    elseif c == 13 or c == 10
        ser.tx(13)
        ser.tx(10)
        quit
    else
        name[i++] := c
        ser.tx(c)
  name[i] := 0
