''
'' a simple PASM based server to blink an LED, running in
'' a COG
''
'' This demo is P2 specific, as it uses assembly code for the COG
''
'' Interface:
'' The COG server listens for messages in a mailbox. The message
'' specifies which pin it should blink, and how long to wait between
'' blinks. This can be changed "on the fly".
''
#ifndef __P2__
#error this demo is for P2 only
#endif

const _clkfreq = 160_000_000

''
'' assembly code for managing the LED
''
asm shared
	org	0
entry
        getct	now	' get the current time
	addct1	now, #0 ' set it as the ct1 target
mainloop
    	' if the timeout is non-zero, blink our pin
	cmp	delay, #0 wz
  if_nz	drvnot	pin
        mov	tmp, delay
        fge	tmp, #100	' minimum reasonable delay
	addct1	now, tmp
        rdlong	tmp, ptra wz	' check for command (any non-zero value)
  if_z	jmp	#no_new_cmd     ' if 0 then no new command
  	rdlong	pin, ptra[1]	' otherwise update pin and delay
  	rdlong	delay, ptra[2]
  	wrlong	#0, ptra        ' zero out the command so host knows we have read it
no_new_cmd          
        waitct1			' wait appropriate delay
        jmp	#mainloop	' and repeat

tmp	long	0
delay	long	0
pin	long	0
now	long	0     

end asm


''
'' this is the mailbox structure used to communicate with the COG
''   cmd: the command we want to send
''        this server understands only one command, SET (1)
''   pin: pin to blink
''   delay: cycles to delay between blinks
''
'' whenever cmd is non-zero, the server reads the rest of the mailbox and
'' acts on it. The server COG writes 0 back to cmd to indicate it has
'' finished acting on the cog.
''
class mailbox
    dim cmd as integer
    dim pin as uinteger
    dim delay as uinteger
end class

'' mailboxes for the two COGs we launch
dim mbox1, mbox2 as mailbox

'' send a command to a mailbox
sub update_mbox(box as mailbox, pin as integer, delay as uinteger)
    box.pin = pin
    box.delay = delay
    box.cmd = 1 '' always write this last

    '' wait for the COG to notice our change
    do
    loop while (box.cmd <> 0)
end sub

'' main program
#ifdef _BAUD
    _setbaud(_BAUD)
#endif    
    print "LED test server..."
    
    '' start up our COGS
    var cog1 = cpu(@entry, @mbox1)
    var cog2 = cpu(@entry, @mbox2)
    print "started cogs "; cog1; " and "; cog2
    pausems 2000  '' pause for user to read messages

    '' change settings for cog1
    print "telling cog1 to start blinking pin 56"
    update_mbox(mbox1, 56, CLKFREQ/2)
    pausems 2000

    '' change settings for cog2
    print "starting to blink pin 57"
    update_mbox(mbox2, 57, CLKFREQ/3)
    pausems 4000

    '' revise settings for cog1
    print "changing frequency on pin 56"
    update_mbox(mbox1, 56, CLKFREQ/8)

    pausems 8000
    print "shutting down blinking on pin 57"
    update_mbox(mbox2, 57, 0)
    do
    loop
