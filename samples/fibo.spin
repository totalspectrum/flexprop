'' simple hello world program
CON
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000

OBJ
  ser: "NewSerial"

PUB demo | i, n, t
  ser.start(115_200)
  repeat i from 6 to 46 step 10
    t := CNT
    n := fibolp(i)
    t := CNT - t
    ser.printf( "fibo(%d) = %d; cycles = %d%n", i, n, t )
    
PUB fibolp(n) : r | lastr
  r := 1
  lastr := 0
  repeat n-1
    (lastr,r) := (r, r+lastr)
