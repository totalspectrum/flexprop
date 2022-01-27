''
'' clock frequency settings
'' for 640x480 we use a 25 MHz pixel clock
'' for 800x600 we use a 40 MHz pixel clock
'' for 1024x768 we use a 65 MHz pixel clock
''
'' for best results the system clock should be a multiple of
'' the pixel clock
''
'' 200 MHz is a convenient one for many purposes, and
'' is only a slight overclocking
''
CON
  PINBASE = 48
  
  _XTALFREQ     = 20_000_000                                    ' crystal frequency
  _XDIV         = 1                                            ' crystal divider to give 1MHz
  _XMUL         = 10                                          ' crystal / div * mul
  _XDIVP        = 1                                             ' crystal / div * mul /divp to give _CLKFREQ (1,2,4..30)
  _XOSC         = %10                                  'OSC    ' %00=OFF, %01=OSC, %10=15pF, %11=30pF
  _XSEL         = %11                                   'XI+PLL ' %00=rcfast(20+MHz), %01=rcslow(~20KHz), %10=XI(5ms), %11=XI+PLL(10ms)
  _XPPPP        = ((_XDIVP>>1) + 15) & $F                       ' 1->15, 2->0, 4->1, 6->2...30->14
  _CLOCKFREQ    = _XTALFREQ / _XDIV * _XMUL / _XDIVP            ' internal clock frequency                
  _SETFREQ      = 1<<24 + (_XDIV-1)<<18 + (_XMUL-1)<<8 + _XPPPP<<4 + _XOSC<<2  ' %0000_000e_dddddd_mmmmmmmmmm_pppp_cc_00  ' setup  oscillator

  sys_clock_freq = _CLOCKFREQ
  sys_clock_mode = _SETFREQ

DAT

democolors
    long $FF000000, $FFFF0000, $00FF0000, $00FFFF00
    long $0000FF00, $FF00FF00, $FFFFFF00, $00000000
    long $7F000000, $007F7F00, $007F0000


OBJ
'   scrn: "vgatext_640x480.spin"
   scrn: "vgatext_800x600.spin"
'   scrn: "vgatext_1024x768.spin"
   ser: "spin/SmartSerial"
   
PUB demo | x, y, fgcol, bgcol, ch, grey, col1, col2, idx
    clkset(sys_clock_mode, sys_clock_freq)  ' 20 MHz crystal * 8

    ' start up serial for debugging
    ser.start(63, 62, 0, 230_400)
    ser.printf("VGA text demo\n")

    ' start up the VGA driver
    scrn.start(PINBASE)
    ser.printf("screen started\n")
    
    ch := 0

    repeat y from 0 to scrn#ROWS-1
        grey := y<<3
        bgcol := (grey<<24) | (grey<<16) | (grey<<8)
        repeat x from 0 to scrn#COLS-1
          grey := (x & 15)
          idx := x / 16
          col1 := democolors[idx]
          col2 := democolors[idx+1]
          fgcol := colorblend(col1, col2, (grey<<4) + grey)
          scrn.glyphat(x, y, ch++, fixupcol(fgcol), fixupcol(bgcol), $20)
    waitms(10000)
    runtext

PUB colorblend(a, b, mix)
  asm
    setpiv mix
    blnpix a, b
  endasm
  return a

PUB fixupcol(a) | r, g, b, x
  b := (a>>8) & $FF
  g := (a>>16) & $FF
  r := a>>24
  x := scrn.getrgbcolor(r, g, b)
  'ser.printf("fixupcol(%x, %x, %x) -> %x\n", r, g, b, x)
  return x
  
PUB runtext | n
  scrn.str(string(27, "[1;1H"))
  scrn.str(string(27, "[0J"))

  n := 0
  repeat
    scrn.nl
    scrn.str(string("Hello! ", 27, "[BCursor down"))
    scrn.str(string(27, "[31mRed text "))
    scrn.str(string(27, "[1;31mBright Red text"))
    scrn.str(string(27, "[7mInverse "))
    scrn.str(string(27, "[22;31mBold off "))
    scrn.str(string(27, "[4mUnderline", 27, "[24m"))
    scrn.str(string(27, "[9mStrikethru"))
    scrn.str(string(27, "[0mEffects off "))
    scrn.dec(n)
    n++
    waitms(100)
