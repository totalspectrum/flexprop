# Introduction

FlexGUI is a simple GUI for creating applications on the Parallax Propeller 2 (or 1), using assembler, Spin, BASIC or C. It consists of a very plain front end IDE, the fastspin compiler, and Dave Hein's loadp2 program loader. The default configuration is for the Prop2, but I've also included David Betz's proploader.exe, which allows flexgui to work on Propeller 1 systems as well.

FlexGUI is distributed under the MIT license; see the file License.txt for details.

## Features

* Both Prop1 and Prop2 are supported
* Supports PASM, Spin, BASIC, and C
* View output PASM code
* Built in terminal emulator
* GUI checks files for external changes, so you may use any editor and compile in FlexGUI
* Options for interacting directly with P2 ROM monitor and ROM TAQOZ
* Micropython for P2 sample included

### PASM enhancements

* P1 and P2 assembly languages supported
* Preprocessor supporting `#define`, `#ifdef`, and `#include`
* Absolute address operator `@@@` (only needed for P1)
* Warnings for common mistakes like forgetting `#` in a jump
* Can compile assembly-only files (no Spin methods required)

### Spin enhancements

The original Spin language is supported, with some enhancements from Spin2:

* Generates optimized PASM instead of bytecode
* `case_fast` to force `case` to produce a jump table
* Conditional expressions like `(x < y) ? x : y`
* Multiple return values and assignments, e.g. `x,y := y,x`
* Unsigned operators `+/`, `+//`, `+<`, `+=<`, `+>`, `+=>`
* Spin2 operators `\`, `<=>`
* Pointers to objects
* Inline assembly inside PUB and PRI functions
* `pub file` and `pri file` to include functions from other languages (C, BASIC)
* Default parameter values for functions
* Optional type specifiers for function parameters and return values
* Automatic passing of strings as pointers in some cases

See `doc/spin.md` for more details.

### BASIC Language

fastspin supports a fairly complete version of BASIC, based on traditional Microsoft BASICs. Please see `doc/basic.md` for details. Notable features are:

* Structured programming features
* Line numbers are optional
* Garbage collected memory allocation
* Support for classes, and importing Spin objects as classes
* Function closures and immediate functions
* `try` / `catch`
* Inline assembly
* Generic functions and templates

### C Language

fastspin supports a C dialect called FlexC, which is intended to be C99 compatible with some C++ extensions. It is not yet complete. Notable enhancements are:

* Inline assembly (similar to MSVC)
* Simple classes, including using Spin and BASIC objects as C classes
* Reference parameters using `&`
* GCC style statement expressions
* Header files may specify linking information for libraries
* Several useful builtin functions

# Usage

## Installation on Windows

### Installing for ALL users

To install FlexGUI for all users, download and run FlexGUISetup-X.X.X.exe from the releases page (where X.X.X is the latest version number). The latest installer is always located at:

   https://github.com/jacgoudsmit/flexgui/releases/latest

You will need administrator credentials to perform the installation. Installing sample code and documentation is optional. The installer will install the sample code in the common documents folder; usually the sample code will end up in C:\Users\Public\Documents\FlexGUI but this may change depending on your Windows installation.

### Running FlexGUI without installing

To run FlexGUI without installing it for all users, download the flexgui.zip file from the releases. The latest release is always located at:

   https://github.com/totalspectrum/flexgui/releases/latest
   
Create a directory called "flexgui" (or whatever you'd like) and unpack the .zip file into that directory. Make sure the directory you create is writable, so do not unpack into a system directory like "Program Files". Use your desktop or a folder directly under "C:" instead.

## Running on Windows

If you used the installer, you can start FlexGUI from the Start Menu. Otherwise, you can run flexgui.exe from the folder where you unzipped flexgui.zip.

Use the `File` menu to open a Spin or BASIC file. You may open multiple files. The one that is currently selected will be treated as the top level project if you try to compile and/or run. The commands used for compiling or running are settable from the `Commands > Configure Commands...` menu item. Compiling and running on Prop2 is the main focus, but you can configure for virtually any situation where just one file is compiled. So for example it should be feasible to use this GUI for `p2gcc` with a bit of tweaking.

Also under the `File` menu is an option for viewing the listing file. This will only be useful after a program is compiled.

To change between P1 and P2 development use `Configure Commands...` and select the appropriate default.

Your changes to commands, library directories, and other configuration information is saved in a file called .flexgui.config in your home directory (if you used the installer) or in the directory where flexgui.exe is located (if you used flexgui.zip).

### Library Directories

Under the `File` menu is an option to set library directories. The compiler will automatically look through these directories for OBJ files (Spin) or `#include` files (C).

### Listing files

Under the `File` menu is an option for viewing the listing file, which shows the PASM and binary generated by fastspin from your high level language. This file may only be opened after the first compilation is done; if you try to open before doing any compile you may get an "Error: could not read" dialog box.

## Other platforms

Only a Windows binary is provided. For other platforms, run the `flexgui.tcl` script. You will need Tcl/Tk installed, but it is available for most versions of Unix (including Mac OS X). For linux, you'll also need to get binary versions of `fastspin` and `loadp2` for your platform, and copy them into the `bin` folder. For Windows and Mac OS X these binaries are already provided in the standard binary distribution of flexgui.

## High level languages

The main advantage of flexgui over PNut (the "official" development tool for the Prop2) is that PNut supports only Spin 2, whereas flexgui supports Spin 1, Spin 2, BASIC, and C. You can basically write ordinary Spin code, with Prop2 assembly code in the DAT section (instead of Prop1 assembly code). This makes prototyping your applications much easier.

The code is compiled to P2 assembler by fastspin. This is somewhat different from the way Spin traditionally worked on the Prop1, where Spin code is typically compiled to bytecode and interpreted. (Note that fastspin does work for Prop1, and compiles to P1 assembler in that case.)

Documentation for the various languages supported is in the `doc` folder of the unpacked flexgui. BASIC is the best documented. The Spin documentation assumes familiarity with the original (Propeller1) Spin manual, and outlines the differences in the language fastspin accepts. The C documentation is a placeholder for now and mostly covers the fastspin specific extensions to C.

# Modifying the GUI

The scripts used are in the `src` subdirectory, so you can customize them to your heart's content. The main `flexgui.exe` program is basically just the Tcl/Tk interpreter (from the standard Tk distribution) with a tiny startup script that reads `src/gui.tcl`.

# Supporting FlexGUI development

If you find FlexGUI useful, please contribute to support its development. Contributions of code, documentation, and other suggestions are welcome. Monetary donations are also very welcome. The generous donations of our supporters on Patreon have enabled us to provide a signed Windows binary.

To support FlexGUI on Patreon: https://patreon.com/totalspectrum
To support FlexGUI on Paypal:  https://paypal.me/totalspectrum
