'
' simple 640x480 text demo
' as set up, this uses a 16x32 font, but see below for how to
' change it to 8x16 (or 8x8)
'
CON
  pixel_clock_freq = 25_000_000

  COLS = 40	   ' or 80, if you use the 8x16 unscii font
  ROWS = 15	   ' or 30, if you use the 8x16 unscii font
  FONT_WIDTH = 16  ' or 8, if you use the 8x16 unscii font
  FONT_HEIGHT = 32  ' or 16 you have probably guessed the pattern by now!
  CELL_SIZE = 8  ' bytes per character: use 4 for 8bpp colors, 8 for 24bpp colors
	
DAT
'
' font buffer
'
	long
fontdata
	file "spleen-16x32.bin"
	file "unscii-16.bin"
'	file "unscii-8-fantasy.bin"

VAR
    long params[40] ' parameters for running the VGA tile driver
    long screen_buffer[COLS*ROWS*(CELL_SIZE/4)]
    
OBJ
    vga: "vga_tile_driver.spin"

PUB start(pinbase) | i, pclkscale, pclk, sysclk, x
  ' calculate clock frequency
  pclk := pixel_clock_freq ' pixel clock
  sysclk := clkfreq  ' system clock
  ' calculate scale := $8000_0000 * pclk / sysclk
  ' this is equal to pclk / (sysclk / $8000_000)
  pclkscale := calcscale(pclk, sysclk)

  i := 0
  params[i++] := pinbase
  params[i++] := @screen_buffer	' screen buffer
  params[i++] := COLS           ' screen columns
  params[i++] := ROWS           ' screen rows
  params[i++] := @fontdata	' font data
  params[i++] := FONT_WIDTH	' font width
  params[i++] := FONT_HEIGHT    ' font height
  params[i++] := pclkscale 'fset           ' pixel clock scaling value
  params[i++] := 16             ' horizontal front porch
  params[i++] := 96             ' hsync pulse
  params[i++] := 48             ' horizontal back porch
  params[i++] := 10             ' vertical front porch
  params[i++] := 2              ' vertical sync lines
  params[i++] := 33             ' vertical back porch
  params[i++] := %11            ' polarity (1 == negative)
  params[i++] := CELL_SIZE
  
  x := vga.start(@params)
  init_terminal
  return x

PUB stop
  vga.stop
  
#include "vga_text_routines.spinh"
#include "spin/std_text_routines.spinh"
