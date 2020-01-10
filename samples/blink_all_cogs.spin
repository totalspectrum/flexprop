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
  _clkfreq = 160_000_000
#else  
  _clkmode = xtal1 + pll16x
  _clkfreq = 80_000_000
#endif  

DAT
stack
    long 0[64]

PUB demo | cognum, delay
  delay := clkfreq
  repeat cognum from 7 to 1
    delay -= clkfreq / 10
    coginit(cognum, doblink(cognum, delay), @stack[cognum*4])
  doblink(0, delay)
  
PUB doblink(id, delay) | pin
  pin := id + BASEPIN
  
  DIRREG[pin] := 1
  
  repeat
    OUTREG[pin] ^= 1
    waitcnt(CNT + delay)
