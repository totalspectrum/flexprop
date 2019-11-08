'
' charlieplex demo in BASIC
' Written by Eric R. Smith, placed in the public domain
'
' compile with
'    fastspin -2 bdemo.bas
'

#ifndef __P2__
#error this demo only works on P2
#endif

' import the Spin2 charlieplex driver
dim c as class using "charlieplex_text.spin2"

' set up clock and baud rate
' (as it happens we don't need baud rate in this demo)
clkset(0x010007f8, 160_000_000)
_setbaud(230_400)

' start up the charlieplex driver
if c.start() == 0 then
  print "cannot start charlieplex driver"
  cogstop(cogid())
endif

' open a handle for it
' note that we cannot receive on this device, so the receive pointer
' is nil
open SendRecvDevice(@c.tx, nil, @c.stop) as #2

let i = 1
do
  print #2, "Hello, world!"
  print #2, i
  i = i + 1
  pausems 1000
loop
