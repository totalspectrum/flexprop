''
'' serial port definitions
''
'' this is for a very simple serial port
'' (transmit only, and only on the default pin for now)
''
#ifdef __P2__
#define OUT OUTB
#define DIR DIRB
#else
#define OUT OUTA
#define DIR DIRA
#endif

CON
  txpin = 30
  
VAR
  long bitcycles
   
PUB start(baudrate)
  DIR[txpin] := 1
  OUT[txpin] := 1
  pause(1)
  bitcycles := clkfreq / baudrate
  return 1
  
PUB pause(n)
  waitcnt(CNT + n*clkfreq)
  
PUB tx(c) | val, nextcnt
  OUT[txpin] := 1
  DIR[txpin] := 1

  val := (c | 256) << 1
  nextcnt := CNT
  repeat 10
     waitcnt(nextcnt += bitcycles)
     OUT[txpin] := val
     val >>= 1

PUB str(s = string("")) | c
  REPEAT WHILE ((c := byte[s++]) <> 0)
    tx(c)


''
'' print an number with a given base
'' we do this by finding the remainder repeatedly
'' this gives us the digits in reverse order
'' so we store them in a buffer; the worst case
'' buffer size needed is 32 (for base 2)
''
''
'' signflag indicates how to handle the sign of the
'' number:
''   0 == treat number as unsigned
''   1 == print nothing before positive numbers
''   anything else: print before positive numbers
'' for signed negative numbers we always print a "-"
''
'' we will print at least prec digits
''
VAR
  byte buf[32]

PUB Num(val, base = 10, signflag = 1, digitsNeeded = 0) | i, digit, r1, q1

  '' if signflag is nonzero, it indicates we should treat
  '' val as signed; if it is > 1, it is a character we should
  '' print for positive numbers (typically "+")
  
  if (signflag)
      if (val < 0)
        signflag := "-"
	val := -val
	
  '' make sure we will not overflow our buffer
  if (digitsNeeded > 32)
    digitsNeeded := 32

  '' accumulate the digits
  i := 0
  repeat
    if (val < 0)
      ' synthesize unsigned division from signed
      ' basically shift val right by 2 to make it positive
      ' then adjust the result afterwards by the bit we
      ' shifted out
      r1 := val&1  ' capture low bit
      q1 := val>>1 ' divide val by 2
      digit := r1 + 2*(q1 // base)
      val := 2*(q1 / base)
      if (digit => base)
        val++
	digit -= base
    else
      digit := val // base
      val := val / base

    if (digit => 0 and digit =< 9)
       digit += "0"
    else
       digit := (digit - 10) + "A"
    buf[i++] := digit
    --digitsNeeded
  while (val <> 0 or digitsNeeded > 0) and (i < 32)
  if (signflag > 1)
    tx(signflag)
    
  '' now print the digits in reverse order
  repeat while (i > 0)
    tx(buf[--i])

'' print a signed decimal number
PUB dec(val)
  Num(val)

'' print an unsigned decimal number with the specified
'' number of digits; 0 means just use as many as we need
PUB decuns(val, digits = 0)
  Num(val, 10, 0, digits)

'' print a hex number with the specified number
'' of digits; 0 means just use as many as we need
PUB hex(val, digits = 8) | mask
  num(val, 16, 0, digits)

'' print a newline
PUB nl
  tx(13)
  tx(10)

''
'' formatted print
''
PUB printf(fmt = string(""), an=0, bn=0, cn=0, dn=0, en=0, fn=0) | c, valptr, val
  valptr := @an
  repeat
    c := byte[fmt++]
    if (c == 0)
      quit
    if (c <> "%")
      tx(c)
      next
    c := byte[fmt++]
    if (c == 0)
      quit
    if (c == "n")
      tx(13)
      tx(10)
    else
      if (c == "%")
        tx(c)
	next
      val := long[valptr]
      valptr += 4
      case c
	"d": dec(val)
	"u": decuns(val)
	"x": hex(val)
	"s": str(val)
        "c": tx(val)
