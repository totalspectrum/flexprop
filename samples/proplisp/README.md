Introduction
============

This is proplisp, a Lisp based scripting language desinged for very tiny
machines. The initial target is boards using the Parallax Propeller,
which has 32KB of RAM, but the code should easily be portable to other
platforms such as the Arduino.

proplisp is copyright 2016-2019 Total Spectrum Software Inc. and released
under the MIT license. See the LICENSE file for details.

On the propeller, the interpreter code needs about 3K of memory in CMM
mode or 5K in LMM. On the x86-64 the interpreter code is 6K. The size
of the workspace you give to the interpreter is up to you, although in
practice it would be not very useful to use less than 2K of RAM. The
processor stack is used as well, so it will need some space, especially
if you use recursive functions.

The Language
============

proplisp implements a version of Lisp that is like, but not exactly,
Scheme. A lot of useful features are left out. The only data types
are numbers, strings (delimited by double quotes), symbols, builtin functions,
lambda functions, and of course pairs.

Numbers are only 28 bits (the other 4 bits are used for tag values).

The empty list () represents false; any other value is considered true.
A particular value `#t` is the "preferred" form of true.

The interpreter defines the following functions by default:

```
(define x e) -- defines x to have the value e; always works in global environment
(set! x e)   -- changes a previous definition of x to have new value e
(eval e)  -- evaluates e, returns the result
(cons a b) -- returns a pair with a as the head, b as the tail
(head x)   -- returns the head of a pair, or () if x is not a pair
(tail x)   -- returns the tail of a pair, or () if x is not a pair
   NOTE that most lisps call `head` and `tail` `car` and `cdr`
(append x y) -- appends two strings or two lists, returns the result
(quote a) -- returns a, unchanged; may be abbreviated by 'a
(pair? a) -- returns #t if a is a pair, () otherwise
(number? a) -- returns #t if a is a number, () otherwise
(if c a b) -- evaluates to a if c is true, b otherwise
(begin a b c...) -- evaluates a, b, c, etc. in order, returning the last result
(while c e) -- continues to evaluate e as long as c is true
(+ a b) -- return the sum of a and b
(- a b) -- return the difference of a and b
(* a b) -- return the product of a and b
(/ a b) -- return the integer quotient of a and b
(< a b) -- returns #t if the a and b are numbers and a < b
    similarly for >, <=, >=
(gcfree) -- performs garbage collection, returns number of cells remaining

(= a b) -- returns #t if a and b are equal () otherwise
(<> a b) -- returns #t if a and b are not equal, () otherwise
    equality for numbers and strings is the usual notion;
    for symbols it is based on the symbol name
    for other objects must be identical

(lambda a b) -- creates a function, see below
```

In the sample program provided for the Parallax Propeller,
there are the following additional functions:
```
(waitms n) -- wait for n milliseconds
(pinhi p) -- drive pin p high
(pinlo p) -- drive pin p low
(pintoggel p) -- toggle output value of pin p
(pinout p x) -- set pin p to low (if x == 0) or high (if x <> 0)
(pinin p) -- return the value of input pin p (1 or 0)
(getcnt)  -- get the low 28 bits of the current system timer value 
```

Some Notes
----------
A few things to note about this version of Lisp:

`define` will always create a global definition; it should be used inside
functions only for very special purposes

`set!`, will change any existing definition it can find, even
in a higher scope. It will not create a new definition.

The arithmetic operators `+`, `-`, and so on, require exactly two arguments.
Unary `-` can be achieved with `(- 0 x)`.

`car` and `cdr` are called `head` and `tail`. You are free of course to
do `(define car head)` and so on.

Lambda
------
The general form of a function definition is `(lambda args body)`.
Functions defined with `lambda` are "anonymous", so they must be bound to
a name via `define` or `set!`.

If `args` is a symbol, then all parameters are evaluated and `args`
is set to a list containing the results.

If `args` is a quoted symbol, then it will be given a list of all
parameters, unevaluated. This means that the `lambda` is really
defining a macro of sorts.

If `args` is a list of symbols or quoted symbols, then each symbol is
set to the corresponding (evaluated) parameter, and each quoted symbol
is set to the corresponding unevaluated parameter. It is an error if the
number of parameters differs from the number of symbols in the `args`
list.

Examples (here ">" is the input prompt):
```
> (define a 1)
1
> (define b 2)
2
> (define f (lambda x x))
#<lambda>
> (f a b)
(1 2)
> (define f (lambda 'x x))
#<lambda>
> (f a b)
(a b)
> (define f (lambda (x 'y) '(y x)))
#<lambda>
> (f a b)
(b 1)
```

Scoping
-------
Symbols are lexically scoped, so they refer to the symbols in effect
at the time they were defined. Note that the values of those symbols may
be changed by `set!`, but new definitions will be ignored:
```
> (define a 1)
1
> (define f (lambda () a))
#<lambda>
> (f)
1
> (set! a 2)
2
> (f)
2
> (define a 99)
99
> (f)
2
```

Interface to C
==============

Environment Requirements
------------------------

The interpreter is quite self-contained; the only external functions it
uses are `outchar` (called to print a single character), and `memset`.

Application Usage
-----------------

As mentioned above, the function `outchar` must be defined by the application
to allow for printing. The following definition will work for standard C:
```
#include <stdio.h>
void outchar(int c) { putchar(c); }
```
Embedded systems may want to provide a definition that uses the serial port
or an attached display.

Link the application with `lisplib.c`, and have the application itself
include `lisplib.h`.

The application must initialize the interpreter with `Lisp_Init` before
making any other calls. `Lisp_Init` takes two parameters: the base
of a memory region the interpreter can use, and the size of that region.
It returns NULL on failure, a non-NULL value on success. It is recommended
to provide at least 4K of space to the interpreter.

If `Lisp_Init` succeeds, the application may then define new builtin
functions with `Lisp_DefineCFunc(b)`. `b` is a pointer to a `LispCFunction`
structure, which has 3 fields: `name` is the name of the new symbol,
`args` is a C string describing its prototype, and `func` is the C
function itself.

The `args` string starts with one character describing the function's
return value. This may be either `n` for an integer, or `c` for a Lisp
Cell. After this come parameters (if any): `n` for integer, `c` for
Lisp Cell, `C` for unevaluated Lisp Cell (so e.g. a symbol will be
passed simply as itself, and not as its value), `e` for the current
environment, `v` for a list of all remaining arguments, and `V` for a
list of all remaining arguments, unevaluated.

For example, the `args` string for a function taking 2 integer arguments
and returning an integer is "nnn".

To run a script, use `Lisp_Run(script, print)`. Here
`script` is a C string to be parsed and evaluated, and `print` is 1
the results should be printed. Each Lisp expression in the script
is evaluated, one after the other, and if `print` is true the result
is printed.

The Sample Program
==================

The sample `lisp.c` illustrates some of the features of the interpreter
and how to hook it up to your C application. It also happens to be an
interactive Lisp interpreter for the Propeller.

There is also a very simple editor provided. Commands are:

^L: refresh
^C: abort
^H: backspace; if you backspace past the beginning of line the previous
    lines will be shown

During execution, pressing ^B or ^C will break out of eval and return to
the REPL. (^C is usual, but propeller-load catches this so if you're using
that try ^B instead)

## Some demos to try

### Print Hello
```
(print "hello" nl)
```

### Toggle a pin forever
```
(while #t (begin (pintoggle 1)(waitms 500)))
```
This toggles pin 1 every 500 milliseconds. To break, press control-B or
control-C on the terminal.

### Define a loop forever macro
```
(define forever
 (lambda 'f
  (while #t (eval (cons 'begin f))))

(forever (print "hello" nl))
```
This will print "hello" over and over, until you interrupt it with control-C.

It works by using the special features of proplisp. The argument to lambda
(`'f`) is quoted, and so is not immediately evaluated; instead it is passed
as a complete list to the body of the function. Inside the function we
append this list to `begin` and then evaluate it repeatedly. So for example:
```
(forever (print "a") (print "b"))
```
expands to
```
(while #t (eval (begin (print "a")(print "b"))))
```
which prints `a` and `b` repeatedly forever.

