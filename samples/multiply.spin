''
'' module for testing various forms of multiply on P2
''
PUB builtinmul(a, b) : r1, r2, t
  t := CNT
  r1 := a*b
  r2 := a**b
  t := CNT - t

PUB cordicmul(a, b) : lo, hi, t | m1, m2
  t := CNT
  asm
    qmul a, b
    getqx lo
    getqy hi
  endasm
  t := CNT - t

PUB hwmul(a, b) : lo, hi, t | ahi, bhi
  t := CNT
  asm
    getword ahi, a, #1
    getword bhi, b, #1
    mov lo, a
    mul lo, b
    mov hi, ahi
    mul hi, bhi
    mul ahi, b
    mul bhi, a
    add ahi, bhi wc
    getword bhi, ahi, #1
    bitc bhi,#16
    shl ahi, #16
    add  lo, ahi wc
    addx hi, bhi
  endasm
  t := CNT - t

{
PRI add64(alo, ahi, blo, bhi): rlo, rhi
  rlo := alo
  rhi := ahi
  asm
    add rlo, blo wc
    addx rhi, bhi
  endasm
}
 
PUB swmul(a, b): lo, hi, t | bhi
  t := CNT
  lo := 0
  hi := 0
  bhi := 0
  repeat while (a <> 0)
    if (a&1)
      ''(lo,hi) := add64(lo, hi, b, bhi)
      asm
        add lo, b wc
        addx hi, bhi
      endasm
    '
    '(b, bhi) := add64(b, bhi, b, bhi)
    asm
      add b, b wc
      addx bhi, bhi
    endasm
    a >>= 1
 
  t := CNT - t
