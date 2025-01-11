'*********************************************
' global definitions
'*********************************************

' clock frequency: 252 MHz is a good one for VGA
const _clkfreq = 252_000_000

' screen size; we're using 16bpp, so it can't be
' too large!
const SCRN_WIDTH = 320
const SCRN_HEIGHT = 240

' VGA definitions
' this gives the base pin that the A/V Expansion Board is
' plugged in to
' We can define either VGA_BASE_PIN or DVI_BASE_PIN
#define USE_DVI

#ifdef USE_DVI
const DVI_BASE_PIN = 0
#else
const VGA_BASE_PIN = 48
const VGA_VSYNC_PIN = VGA_BASE_PIN + 4
#endif

' serial definition
' _BAUD is defined automatically by flexgui, but for other
' platforms provide a default value

#ifndef _BAUD
#define _BAUD 230_400
#endif

' the video object, Roger Loh's great P2 video code
dim vid as class using "video/p2videodrv.spin2"

' the C turtle drawing code imported as an object
dim t as class using "turtle/turtle.c"

' space for video driver display and region info
dim display1(14) as long
dim first(14) as long     ' first region
' this definition is used by the video driver
' it is the maximum size of a full video scanline in bytes
const LINEBUFSIZE = 1920*2 ' enough room for a scanline at full colour bit depth
dim shared linebuffer1(LINEBUFSIZE) as ubyte

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' main program
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' video setup should be first, because it can change the clock
Setup_Video()

' set the baud rate and print a message
_setbaud(_BAUD)
print "Turtle test program"

' set up the host file system for screenshots
' we could use an SD card instead, of course, but
' saving directly to the PC is more convenient
mount "/host", _vfs_open_host()  ' for PC
' mount "/host", _vfs_open_sdcard() ' for SD card

' initialize the turtle graphics library
t.turtle_init(@frameBuffer(0), SCRN_WIDTH, SCRN_HEIGHT)

' and draw some stuff
t.turtle_forward(50)
t.turtle_turn_left(90)
t.turtle_forward(50)
t.turtle_turn_left(90)
t.turtle_forward(50)

' now draw the turtle itself
t.turtle_draw_turtle()

'' save a screenshot
print "saving screenshot"
t.turtle_save_bmp("/host/p2screen.bmp")
print "done"

'''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' video setup code
'' creates a 640x480 screen
'''''''''''''''''''''''''''''''''''''''''''''''''''''''
sub Setup_Video()
#ifdef USE_DVI
  vid.initDisplay(-1, @display1, vid.DVI, DVI_BASE_PIN, 0, vid.RGBHV, @lineBuffer1, LINEBUFSIZE, 0, 0, 0)
#else
  ' create a VGA display
  var timing = vid.getTiming(vid.RES_640x480)

  vid.initDisplay(-1, @display1, vid.VGA, VGA_BASE_PIN, VGA_VSYNC_PIN, vid.RGBHV, @lineBuffer1, LINEBUFSIZE, timing, 0, 0)
#endif

  if (SCRN_HEIGHT = 480) then
    vid.initRegion(@first, vid.RGB16, 480, 0, 0, 0, 8, @frameBuffer(0), 0)
  else
    vid.initRegion(@first, vid.RGB16, 480, vid.DOUBLE_WIDE+vid.DOUBLE_HIGH, 0, 0, 8, @frameBuffer(0), 0)
  endif
  
  ' enable display list
  vid.setDisplayRegions(@display1, @first)
end sub

'' this variable holds the whole screen
dim shared framebuffer(SCRN_WIDTH*SCRN_HEIGHT) as ushort
