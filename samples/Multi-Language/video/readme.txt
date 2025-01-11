P2 VGA/DVI text driver demonstration.
-------------------------------------

This zip file contains the following files:

readme.txt           - this file

Demo files:

helloworld.spin2     - very simple hello world example showing easy setup of the text driver with VGA output
helloworld_dvi.spin2 - same as helloworld.spin2 demo but with DVI output instead of VGA
textdemo.spin2       - a demonstration to show the text driver's features (VGA & DVI selectable)
widefont.spin2       - an example of using a 16 pixel wide font (outputs VGA)

Support files:

p2textdrv.spin2      - text driver interface wrapping the video driver
p2videodrv.spin2     - my P2 VGA/DVI/TV video driver
p2font16             - 8x16 pixel font resource file used by demos
widefont32           - 16x32 pixel font resource file used by demos
font6                - a tiny 8x6 scanline font resource file used by demos

Releases:

15 FEB 2021  v0.92b - initial Beta release  
 2 APR 2021  v0.93b - bugfix for newer FlexSpin compilers, now builds with 5.3.1 Flexspin

rogloh 
