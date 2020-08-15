'
' charlieplex demo in BASIC
' Written by Eric R. Smith, placed in the public domain
'
' compile with
'    fastspin -2 bdemo.bas
' assumes an LED matrix board connected to your P2ES board
' at pin 32; change charlieplex_text.spin to modify this

#ifdef __P2__
const _clkfreq = 200_000_000
#else
#error this demo only works on P2
#endif

' import the Spin2 charlieplex driver
dim c as class using "charlieplex_text.spin"

' start up the charlieplex driver
if c.start() == 0 then
  print "cannot start charlieplex driver"
  cogstop(cogid())
endif

' open a handle for it
' note that we cannot receive on this device, so the receive pointer
' is nil
open SendRecvDevice(@c.tx, nil, @c.stop) as #2

' now print to the newly opened device (#2)
' we'll also print an incrementing number too
let i = 1
do
  print #2, "Hello, world!"
  print #2, i
  i = i + 1
  pausems 1000  ' wait 1 second before sending next data
loop
