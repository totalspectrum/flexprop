'' simple hello world program
CON
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000

OBJ
  ser: "SimpleSerial"

PUB demo | i, n, t
  ser.start(115_200)
  repeat i from 6 to 46 step 10
    ser.str(string("fibo("))
    ser.dec(i)
    ser.str(string(") "))
    t := CNT
    n := fibolp(i)
    t := CNT - t
    ser.dec(t)
    ser.str(string(" cycles, result = "))
    ser.dec(n)
    ser.str(string(13, 10))

PUB fibolp(n) : r | lastr
  r := 1
  lastr := 0
  repeat n-1
    (lastr,r) := (r, r+lastr)
