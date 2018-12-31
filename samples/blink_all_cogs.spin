'' blink LEDs corresponding to active COGs

#ifdef __P2__
#define DIRREG DIRB
#define OUTREG OUTB
#define BASEPIN (56-32)
#else
#define DIRREG DIRA
#define OUTREG OUTA
#define BASEPIN 16
#endif

CON
#ifdef __P2__
  _clkmode = $010c3f04
  _clkfreq = 160_000_000
#else  
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000
#endif  

DAT
stack
    long 0[64]

PUB demo | cognum
  clkset(_clkmode, _clkfreq)
  repeat cognum from 7 to 1
    coginit(cognum, doblink(cognum), @stack[cognum*4])
  doblink(0)
  
PUB doblink(id) | pin, delay
  pin := id + BASEPIN
  delay := (id+1) * (_clkfreq/4)
  
  DIRREG[pin] := 1
  
  repeat
    OUTREG[pin] ^= 1
    waitcnt(CNT + delay)
