'' simple fibonacci program
CON
#ifdef __P2__
  _clkmode = $010c3f04
  _clkfreq = 160_000_000
  baud = 230_400
#else
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000
  baud = 115_200
#endif

OBJ
  ser: "PrintfSerial"

PUB demo | i, n, t
  clkset(_clkmode, _clkfreq)
  ser.start(baud)
  repeat i from 1 to 9 step 1
    t := CNT
    n := fiborec(i)
    t := CNT - t
    ser.printf( "fibo(%d) = %d; cycles = %d%n", i, n, t )

'' iterative version
PUB fibolp(n) : r | lastr
  r := 1
  lastr := 0
  repeat n-1
    (lastr,r) := (r, r+lastr)

'' recursive version
PUB fiborec(n)
  return (n < 2) ? n : fiborec(n-1)+fiborec(n-2)
