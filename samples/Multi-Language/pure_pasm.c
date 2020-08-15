//
// this is a simple example of a PASM program
// it blinks pin 57
//

// PREPROCESSOR
// at compile time, do a sanity check to make sure we are
// building for the P2

#ifndef __P2__
#error this demo is for the P2 only
#endif

// PREPROCESSOR
// define the symbol DEBUGPIN to a pin which will be driven low when we start
// this allows us to easily enable/disable debug functionality by
// commenting out the #define to disable
// the debug pin may be made a variable, or an immediate; the string
// that we use in the define will be substituted wherever DEBUGPIN appears

//#define DEBUGPIN #56

// useful constants
// C has no notion of a CON block, so do these via
// defines

// pin to blink
#define led_pin 57

// toggle delay in cycles
#define delay 10000000

__pasm {
	org 0
#ifdef DEBUGPIN
	drvl	DEBUGPIN
#endif
loop
	drvnot	#led_pin	' toggle the led
	waitx	##delay		' delay
	jmp	#loop		' and repeat
'	jmp	loop		' what happens if we forget the #?
'	jmp	indirect	' but this will not give a warning

' the stuff below is just for testing purposes
indirect
	long	loop		' label for indirect jump
}
