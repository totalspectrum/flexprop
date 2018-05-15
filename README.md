Spin2gui
--------

Spin2gui is a very simple GUI for running applications on the Parallax Propeller 2 (Prop2), using the Spin language. It consists of a very basic front end (designed for working on one file at a time), the fastspin compiler, and Dave Hein's loadp2 program loader.

To use it, unpack the .zip file in a directory somewhere and run spin2gui.exe. The program will save its configuration in a file called .spin2gui.config in your home directory.

Spin2gui is distributed under the MIT license; see the file License.txt for details.

## Features

The main advantage of spin2gui over PNut (the "official" development tool for the Prop2) is that PNut doesn't yet support a high level language, whereas spin2gui does. You can basically write ordinary Spin code, with Prop2 assembly code in the DAT section (instead of Prop1 assembly code). This makes prototyping your applications much easier.

The Spin code is compiled to P2 assembler by fastspin. This is somewhat different from the way Spin works on the Prop1, where Spin code is typically compiled to bytecode and interpreted. (Note that fastspin does work for Prop1, though!)

### Preprocessor

Like openspin, bstc, and homespun, fastspin supports a basic preprocessor with such commands as `#define`, `#ifdef`, `#else`, and `#endif`. Note that while compiling for the Prop2 the define `__P2__` is automatically defined. See the file `samples/SimpleSerial` for an example of how to write code that will work on both Prop1 and Prop2 using these defines.

### Inline assembly

fastspin allows simple inline assembly between the keywords `asm` and `endasm`. The `asm` and `endasm` must be indented properly according to the Spin language semantics, but the inline assembly between them does not have to be.

### Multiple assignment

fastspin also supports assignment of multiple values, and functions which return multiple values. This is a feature which has been proposed for Spin2. For now only simple assignment (`:=`) of multiple values is permitted, and the variables to be assigned must be enclosed in parentheses. For example:
```
   (a,b) := (b,a)
```
exchanges the variables `a` and `b`.

Functions which return mutiple values are declared similarly to regular Spin functions, but have more than one return variable defined. For example:
```
PUB quotrem(a, b): q, r
   q := a/b
   r := a//b
```
defines a function which returns two values (the quotient and remainder of `a` divided by `b`). It may be used like:
```
  (val, digit) := quotrem(val, 10)
```
