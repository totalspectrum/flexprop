''
'' serial port definitions
''
'' this is for a very simple serial port
'' (transmit only, and only on the default pin for now)
''
'' note that it uses fastspin specific features
''

#ifdef __P2__
#define OUT OUTB
#define DIR DIRB
#else
#define OUT OUTA
#define DIR DIRA
#endif

#define DEF string("")

CON
  txpin = 30
  
VAR
  long bitcycles
   
PUB start(baudrate)
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

PUB str(s) | c
  if (s == 0)
    return
  REPEAT WHILE ((c := byte[s++]) <> 0)
    tx(c)


PUB print(a0 = DEF, a1 = DEF, a2 = DEF, a3 = DEF, a4 = DEF, a5 = DEF, a6 = DEF, a7 = DEF)
  str(a0)
  str(a1)
  str(a2)
  str(a3)
  str(a4)
  str(a5)
  str(a7)
  
''
'' print an number with a given base
'' we do this by finding the remainder repeatedly
'' this gives us the digits in reverse order
'' so we store them in a buffer; the worst case
'' buffer size needed is 33 (for base 2 plus a 0)
'' Note that we want to allow up to 8 numbers to be printed,
'' so we use a circular buffer for handling the buffers
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
CON
  Max_Bytes_For_Num = 34
  Buf_Limit = 4 * Max_Bytes_For_Num
  
VAR
  long idx
  byte permabuf[Buf_Limit]
  byte buf[Max_Bytes_For_Num]
  
'' return a pointer to space for the next number
PRI AllocSpace(n) : r
  if idx + n => Buf_Limit
    idx := 0
  r := @permabuf[idx]
  idx += n
  
PUB Num(val, base, signflag, digitsNeeded) | i, digit, r1, q1, ptr, j

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
    buf[i++] := signflag
    
  '' now print the digits in reverse order
  ptr := AllocSpace(i+1)
  j := 0
  repeat while (i > 0)
    byte[ptr][j++] := buf[--i]
  byte[ptr][j] := 0
  return ptr
  
'' return a string for a signed decimal number
PUB dec(val)
  return num(val, 10, 1, 0)

'' return an unsigned decimal number with the specified
'' number of digits; 0 means just use as many as we need
PUB decuns(val, digits = 0)
  return num(val, 10, 0, digits)

'' return a hex number with the specified number
'' of digits; 0 means just use as many as we need
PUB hex(val, digits = 8) | mask
  return num(val, 16, 0, digits)

'' return a newline string
PUB nl
  return string(13, 10)

