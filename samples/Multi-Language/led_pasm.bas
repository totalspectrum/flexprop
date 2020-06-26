''
'' simple demonstration of running PASM code from
'' a BASIC program
''

'' "asm shared" is like the DAT block in Spin; it creates
'' global data shared by all instances of an object

'' we create a simple PASM program to run in another cog and
'' monitor a mailbox for data to write to the LEDs
'' like all PASM programs, at entry ptra contains the parameter
'' passed to coginit, and ptrb points at "entry"

asm shared
	org 0	' running in a new COG, so start at 0
entry
	' 4 LEDS (pins 56, 57, 58, 59) will be written to
	' these are located in the OUTB register
	' on the eval board, the LEDs are turned on by driving the
	' corresponding pin LOW; this is the reverse of how one
	' might expect things to work, so we flip that in this code
	
	drvh	#(3<<6) + 56	' drive high 4 pins starting at 56
loop	
	rdlong	flags, ptra	' read the values to write to LEDs
	and	flags, #$f	' only bottom 4 bits are significant
	xor	flags, #$f	' flip meaning (1 means light the LED)
  	shl	flags, #(56-32)	' put in upper bits
	mov	outb, flags	' write to the bits
	jmp	#loop 		' and repeat

	' the variables used by this cog
flags	long	0

end asm

'' variable to share with the ASM code
var flagvar = 0

'' temporary variable
var n = 0

''
'' here is the BASIC code
''

' start the PASM in another COG
var cogid = cpu(@entry, @flagvar)

print "started server on cog "; cogid

' now loop, asking for input on which leds to toggle
do
  input "Enter a number from 0 to 15 (-1 to quit): ", n
  flagvar = n
loop while n <> -1

flagvar = 0

print "done"
