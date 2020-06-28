''
'' hello world for Spin
'' cheats and uses C library
''
OBJ c : "libc.a"

PUB demo
  ' we cannot use \n because the C compiler is what translates that to
  ' newline, and Spin won't do that. So we have to print the character
  ' 10 (newline) explicitly
  c.printf(@"hello, world!%c", 10)
