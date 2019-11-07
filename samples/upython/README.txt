# MicroPython for P2

## What's new

Most of the changes are internal, involving the use of a new compiler
framework. There are also some fixes to the VGA and a few more
built-in modules. The VGA and USB should work now with both the
original P2 eval boards and the new ("v2") silicon.


This version has been compiled with code compression, so it has more room
available for user programs (approx. 200K). It also automatically runs
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
SD card is inserted when micropython is started up, it is
automatically mounted.

The `os` module is implemented, so you can get a listing of the SD
card contents via:
```
import os
os.listdir()
```

To mount an SD card after boot, do:
```
import pyb
import os
sd=pyb.SDCard()
os.mount(sd, '/sd')
os.chdir('/sd')
```

You can run a script from a file via something like:
```
execfile("perftest.py")
```

### Manual detection of SD Cards

Sometimes the SD card isn't automatically detected. In that case you
can force it on by doing:
```
sd=pyb.SDCard()
sd.power(1)
```
This should return `True` if a card is detected and initialized
properly. You can also see if a card is found by checking
`sd.present()`, which will be true or false. Once the card is detected
you can manually mount it as described above.

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
$00000 - $03FFF: RISC-V emulation code
$04000 - $6FFFF: python space
$70000 - $7BFFF: cache space
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

We're getting about 375K on this test.

