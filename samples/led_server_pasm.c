//
// a simple PASM based server to blink an LED, running in
// a COG
//
//
// Interface:
// The COG server listens for messages in a mailbox. The message
// specifies which pin it should blink, and how long to wait between
// blinks. This can be changed "on the fly".
//
// uses the default clock frequency
//
#include <stdio.h>
#include <propeller2.h>

// the assembly code below is written Spin style, in a __pasm block,
// rather than C style in a __asm block

__pasm {
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
}

//
// this is the mailbox structure used to communicate with the COG
//   cmd: the command we want to send
//        this server understands only one command, SET (1)
//   pin: pin to blink
//   delay: cycles to delay between blinks
//
// whenever cmd is non-zero, the server reads the rest of the mailbox and
// acts on it. The server COG writes 0 back to cmd to indicate it has
// finished acting on the cog.
//
typedef struct {
    int cmd;
    unsigned pin;
    unsigned delay;
} mailbox;

// mailboxes for the two COGs we launch
mailbox mbox1, mbox2;

// send a command to a mailbox
void update_mbox(volatile mailbox *box, int pin, unsigned delay)
{
    box->pin = pin;
    box->delay = delay;
    box->cmd = 1; // always write this last

    // wait for the COG to notice our change
    while (box->cmd != 0)
        ;
}

// main program
void main()
{
    unsigned int FREQ = _clockfreq();
    
    printf("LED test server...");
    // start up our COGS
    int cog1 = _cognew(&entry, &mbox1);
    int cog2 = _cognew(&entry, &mbox2);
    printf("started cogs %d and %d\n", cog1, cog2);
    _waitx(2*FREQ);  // pause for user to read messages

    // change settings for cog1
    printf("telling cog1 to start blinking pin 56\n");
    update_mbox(&mbox1, 56, FREQ/2);
    _waitx(2*FREQ);

    // change settings for cog2
    printf("starting to blink pin 57\n");
    update_mbox(&mbox2, 57, FREQ/3);
    _waitx(4*FREQ);

    // revise settings for cog1
    printf("changing frequency on pin 56\n");
    update_mbox(&mbox1, 56, FREQ/8);

    _waitx(8*FREQ);
    printf("shutting down blinking on pin 57\n");
    update_mbox(&mbox2, 57, 0);
    for(;;) ;
}
