FlexGUI
========

FlexGUI is a very simple GUI for running applications on the Parallax Propeller 1 or 2, using the Spin language (and now BASIC and C as well). It consists of a very basic front end IDE, the fastspin compiler, and Dave Hein's loadp2 program loader. The default configuration is for the Prop2, but I've also included David Betz's proploader.exe, which allows flexgui to work on Propeller 1 systems as well.

To use it, create a directory called "flexgui" (or whatever you'd like) and unpack the .zip file into that directory. Then run flexgui.exe. The program will save its configuration in a file called .flexgui.config in that directory.

FlexGUI is distributed under the MIT license; see the file License.txt for details.

## Usage

Not much to say here; I hope the menus will be self explanatory. Use the `File` menu to open a Spin or BASIC file. You can only work on one file at a time; this will be treated as the top level project if you try to compile and/or run. The commands used for compiling or running are settable from the `Commands > Configure Commands...` menu item. Compiling and running on Prop2 is the main focus, but you can configure for virtually any situation where just one file is compiled. So for example it should be feasible to use this GUI for `p2gcc` with a bit of tweaking.

To change between P1 and P2 development use Configure Commands... and select the appropriate default.

### Other platforms

Only the Windows executable is provided. For other platforms, grab the source code and run `flexgui.tcl`. You will need Tcl/Tk installed, but it is available for most versions of Unix (including Mac OS X).

### Modifying the GUI

The scripts used are in the `src` subdirectory, so you can customize them to your heart's content. The main `flexgui.exe` program is basically just the Tcl/Tk interpreter (from the standard Tk distribution) with a tiny startup script that reads `src/gui.tcl`.

## Features

The main advantage of flexgui over PNut (the "official" development tool for the Prop2) is that PNut doesn't yet support a high level language, whereas flexgui supports both Spin and BASIC. You can basically write ordinary Spin code, with Prop2 assembly code in the DAT section (instead of Prop1 assembly code). This makes prototyping your applications much easier.

The Spin code is compiled to P2 assembler by fastspin. This is somewhat different from the way Spin works on the Prop1, where Spin code is typically compiled to bytecode and interpreted. (Note that fastspin does work for Prop1, though!)

### Preprocessor

Like openspin, bstc, and homespun, fastspin supports a basic preprocessor with such commands as `#define`, `#ifdef`, `#else`, and `#endif`. Note that while compiling for the Prop2 the define `__P2__` is automatically defined. See the file `samples/SimpleSerial` for an example of how to write code that will work on both Prop1 and Prop2 using the preprocessor.

### Inline assembly

fastspin allows simple inline assembly between the keywords `asm` and `endasm`. The `asm` and `endasm` must be indented properly according to the Spin language semantics, but the inline assembly between them does not have to be.

### Multiple assignment

fastspin also supports assignment of multiple values, and functions which return multiple values. This is a feature which has been proposed for Spin2. For now only simple assignment (`:=`) of multiple values is permitted. For example:
```
   a,b := b,a
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
  val, digit := quotrem(val, 10)
```
