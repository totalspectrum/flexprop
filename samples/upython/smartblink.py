# blink a pin using smart pins

import pyb
p = pyb.Pin(56)
p.makeinput()   # makes the pin an input, do this before setting up smartpin
p.mode(0x4c)    # set to NCO frequency mode
p.xval(16000)   # set bit period
p.yval(858993)  # set increment
p.makeoutput()  # enables smartpin
