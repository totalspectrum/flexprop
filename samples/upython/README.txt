# MicroPython for P2

## What's new

Most of the changes are internal, involving the use of a new compiler
framework. There are also some fixes to the VGA and a few more
built-in modules. The VGA and USB should work now with both the
original P2 eval boards and the new ("v2") silicon.


This version has been compiled with code compression, so it has more room
available for user programs (approx. 230K). It also automatically runs
the file `main.py` from an inserted SD card at boot time, if one is
found.

I've included a simple python editor pye (original source is at
https://github.com/robert-hh/Micropython-Editor). To use it do:
```
   from pye import pye
   pye('test.py')
```
Full documents are at the github page.

## Overview

This is a basic port of MicroPython to the Parallax P2 Eval board.

To run it, load the upython.binary file into the P2 board. It will
talk on the standard serial line at 230400 baud. It will also try to
talk to a VGA board based at pin 48 and a USB keyboard based at pin 16
(using the standard P2 eval A/V and serial host expansion boards). The
USB driver used is garryj's excellent single COG keyboard/mouse driver
(although I haven't implemented mouse support yet).

## Pins

There is a P2 PIN class supported in the standard pyb module. You can
toggle pin 56 on the P2 board, for example, with:
```
>>> import pyb
>>> p = pyb.Pin(56)
>>> p.off()
>>> p.toggle()
```
(The LEDs on the P2 board are active low, weirdly enough, so p.off()
actually turns the LED on by pulling the pin low.)

The simple methods are:
```
  p.on()   # drives pin high
  p.off()  # drives pin low
  p.toggle() # toggles pin
  p.read() # reads input value of pin, returns 0 or 1
```

For dealing with smartpins there are several more methods:
```
p.makeinput()   # makes the pin an input, do this before setting up smartpin
p.mode(0x4c)    # set to NCO frequency mode
p.xval(16000)   # set bit period
p.yval(858993)  # set increment
p.makeoutput()  # enables smartpin
p.readzval()    # reads the Z value (input) of the smartpin
```
Note that p.makeinput() is implied by p.read(), and p.makeoutput() is
implied by p.on(), p.off(), and p.toggle(), so the makeinput() and
makeoutput() methods are only really needed for smart pin manipulation

Also note that this version supports long integers, so effectively the
smart pin registers are 32 bit unsigned values. Only the lower 32 bits
of any value passed to them are used. For example:
```
import pyb
p=pyb.Pin(1)
p.mode(2)
p.makeoutput()
p.xval(-1)
hex(p.readzval())
'0xffffffff'
```
## CSRs

There are a number of special registers ("control and status
registers") which may be hooked in to by assembly code or
debuggers to provide special features. These are labelled by a
12 bit number. Only a few are presently implemented.
They may be accessed by the `Csr` type within the `pyb` module.
Supported CSRs include:
```
0xbc0: UART register; read gets character, write sends character
0xbc1: waitcycle register: read gets current processor cycle, write
       waits until that cycle comes around again
0xbc2: reserved for debugging
0xbc3: millisecond register: read gets elapsed milliseconds
0xbc4-0xbc7: available for hooks
0xc00: 64 bit cycle counter (low 64 bits)
0xc80: 64 bit cycles counter (high 64 bits)
```

The methods available for CSRs are `read()`, `write(val)`, and `id()`.

### Example:

A delay of 16000000 cycles may be implemented with:
```
c = pyb.Csr(0xbc1)
c.write(c.read() + 16000000)
```

### CSR Hooks

CSRs `0xbc0` through `0xbc7` are vectored through a jump table
starting at HUB address `$808`. Each jump table entry contains two
entries, first for reads and then for writes. They should jump to
the subroutine that implements the CSR, which should return via a
regular P2 `ret` instruction.

For reads, the value to be returned should be placed in the `pb`
register.

For writes, the value to be written is passed in the `pb` register.

In all cases registers `pb` and `ptrb` may be modified by the
subroutine. All other COG registers should be left alone.

## Timing

pyb also has millis() and micros() methods to return current
milliseconds and microseconds since boot. These use a 64 bit cycle
timer, so they do not roll over nearly as quickly as they used to.

## SD Card

There is a standard SDCard type implemented in the `pyb` module. If an
SD card is inserted when micropython is started up, it is normally
mounted automatically.

The `os` module is implemented, so you can get a listing of the SD
card contents via:
```
import os
os.listdir()
```

You can run a script from a file via something like:
```
execfile("perftest.py")
```

Sometimes an SD card is not automatically detected (different cards
seem to have different characteristics and micropython doesn't detect
them all). In this case you should follow the steps for inserting an
SD card after boot.

### Inserting an SD card after boot

To mount an SD card after boot, do:
```
import pyb
sd=pyb.SDCard()
sd.present()
```

`sd.present()` should return `True`. If it does not, then you'll have
to power the card on manually:
```
sd.power(1)
```

Now you can mount the drive. This is a two step process; first we use
`os.mount()` to establish a name for the SD card, then we use
`os.chdir()` to switch to it.

```
import os
os.mount(sd, '/sd')
os.chdir('/sd')
```

This code should be entered manually, and only has to be done
once. Once the card is mounted, it stays mounted.

NOTE: it is important to mount the SD only once. Do not add this code
to any scripts that run more than once. Do not try to do mount from a
python program which is intended to run from the SD card. There's no
need (if the program is able to run, the SD is clearly mounted
already) and it will confuse micropython.

## CPUs

It is possible to run code in other CPUs ("cogs") using the Cpu
object. This has methods `start` and `stop`, used as follows:
```
import pyb
x=pyb.Cpu()

# code is a byte array containing the program to execute
# this can come from a file on disk, or by constructing a binary
# object using a PNut or fastspin listing file

# data is an optional mutable bytearray which the cpu object can
# read from and can change

x.start(code, data)
x.stop()
```

For example, consider a small PASM program to flash a pin. Here is the
PASM source code:
```
'
' simple blinking demo
' enter with ptra pointing at a mailbox
' ptra[0] is the pin to blink
' ptra[1] is the time to wait between blinks
' ptra[2] is a count which we will update
'
dat
	org	0
	rdlong	pinnum, ptra[0]
	rdlong	delay, ptra[1]
	rdlong	count, ptra[2]
loop
	drvnot	pinnum		' toggle pin
	add	count, #1
	wrlong	count, ptra[2]	' update count
	waitx	delay		' wait
	jmp	#loop

pinnum	long	0
delay	long	0
count	long	0
```

To get this into python, we have to compile it first with a PASM
assembler such as fastspin or PNut. For example, with fastspin save
the above code as blink.spin2 and compile it with:
```
fastspin -l -2 blink.spin2
```

This produces both a binary file, `blink.binary`, and a listing file
`blink.lst`. Now we have to get that into a Python bytearray in
micropython. There are two approaches. The easiest is if we have
access to an SD card. Then we can just put `blink.binary` onto the
card and read it from there with micropython:
```
f=open("blink.binary","rb")
code=f.read()
f.close()
```
Now `code` is a bytearray containing the bytes we need.

If for some reason using an SD card isn't practical, we can put the
necessary bytes directly into a bytearray. The blink.lst file shows us
the hex bytes, or we can use a tool like xxd to dump them from the
binary. Then assign them to a variable. Micropython as a ubinascii
module which allows conversion from hex to bytes, so we can do:
```
import ubinascii
code=ubinascii.unhexlify('001104fb011304fb021504fb5f1060fd011404f1021564fc1f1260fdecff9ffd0000000000000000000000000000000000000000000000000000000000000000')
```

We also need to prepare one or more data mailboxes for the COG
code. The easiest way to do this is with Python's array of integers:
```
import array
data=array.array('i', [57, 40000000, 0])
```
This creates an array of 3 integers, which will be the parameters to
the COG program (passed in `ptra`). The first is the pin to toggle,
the second is the time in cycles to wait between toggles, and the
third is the initial count of toggles. This will be updated by the COG.

Now we can run our program:
```
import pyb

cog=pyb.Cpu()   # create an object for the CPU
cog.start(code, data)
```
Note that `data[2]` will keep updating as the COG blinks.

We could also start a second COG up on pin 56. We can re-use the same
code object, but should create a new data mailbox:
```
data2=array.array('i', [56, 20000000, 0])
cog2=pyb.Cpu()
cog2.start(code, data2) # start on pin 56
```

We can stop either of the CPUs via their `stop` method:
```
cog2.stop()
```

### Restrictions on Cpu code

Note that the code cannot, in general, know its own HUB address,
because micropython assigns that at run time with dynamic memory
allocation. So the code loaded into the Cpu *must* be position
independent. If it needs to access some HUB addresses (e.g. to load
LUT code or to run some hubexec code) then it must save the initial
value of `ptrb` passed to it when it starts. The P2 `coginit`
instruction places the HUB address of the loaded code into
`ptrb`. This may then be used to calculate the actual HUB address
needed.


## Other Notes

### Debug Hooks

As noted in the CSR section above, UART I/O and some other functions
are performed by vectoring through a jump table at `$808`. The entries
in this should be P2 jump instructions. CSR writes expect values in
`pb`; CSR reads return values in `pb`. Registers `pb` and `ptrb` are
available for use in the subroutines; all other COG memory should be
preserved.

There are also two hooks called at startup. The initial startup code
jumps to `$800`, which is a jump instruction to the main startup code.

After the RISC-V emulator has been set up, a call instruction is made
to `804`. The default setup just has a `jmp` to the boot message
printer, but if this is changed to an absolute `jmp` to a subroutine
ending with a `ret`, arbitrary P2 code may be executed at
initialization time.

### Memory map

```
$00000 - $0FFFF: RISC-V emulation code
$10000 - $7BFFF: python space
$7C000 - $7FFFF: debug space
```

### Performance

```
import pyb
def perfTest():
  millis = pyb.millis
  endTime = millis() + 10000
  count = 0
  while millis() < endTime:
    count += 1
  print("Count: ", count)
```

We're getting about 395K on this test.

