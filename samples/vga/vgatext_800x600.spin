''
'' 800x600 VGA sample
'' as-is this is set up for an 8x15 font, but that's easily
'' changed in the settings below
''

''
'' clock frequency settings
'' for 800x600 we use a 40 MHz pixel clock
'' which x4 gives a 160 MHz system clock
'' or x5 gives a 200 MHz system clock
'' those are probably good choices for running
'' with this
''
CON

  pixel_clock_freq = 40_000_000

  COLS = 100   ' (8*100 == 800)
  ROWS = 40    ' (40*15 == 600)
  FONT_WIDTH = 8
  FONT_HEIGHT = 15
  CELL_SIZE = 4  ' bytes per character: use 1 for monochrome, 2 for 4 bit color, 4 for 8bpp colors, 8 for 24bpp colors

DAT
'
' font buffer
'
	long
fontdata
	file "unscii-16.bin"

VAR
    long params[40]
    byte screen_buffer[COLS*ROWS*CELL_SIZE]

OBJ
    vga: "vga_tile_driver.spin"

PUB start(pinbase) | i, pclkscale, pclk, sysclk, x, fontptr
  ' calculate clock frequency
  pclk := pixel_clock_freq
  sysclk := clkfreq  ' system clock
  ' calculate scale := $8000_0000 * pclk / sysclk

  pclkscale := calcscale(pclk, sysclk)

  fontptr := @fontdata
  if FONT_HEIGHT == 15
    fontptr += 256 ' skip a row

  i := 0
  params[i++] := pinbase
  params[i++] := @screen_buffer	' screen buffer
  params[i++] := COLS           ' screen columns
  params[i++] := ROWS           ' screen rows
  params[i++] := fontptr	' font data: skip first row for 8x15
  params[i++] := FONT_WIDTH	' font width
  params[i++] := FONT_HEIGHT    ' font height
  params[i++] := pclkscale 'fset           ' pixel clock scaling value
  params[i++] := 40           ' horizontal front porch
  params[i++] := 128             ' hsync pulse
  params[i++] := 88        ' horizontal back porch
  params[i++] := 1              ' vertical front porch
  params[i++] := 4              ' vertical sync lines
  params[i++] := 23             ' vertical back porch
  params[i++] := %00            ' vertical/horizontal polarity
  params[i++] := CELL_SIZE
  x := vga.start(@params)
  init_terminal
  return x

PUB stop
  vga.stop
  
#include "vga_text_routines.spinh"
#include "spin/std_text_routines.spinh"
