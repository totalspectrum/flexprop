''
'' interactive pin demo
''
'' commands supported:
'' hi n -- drives pin high
'' lo n -- drives pin low
''

'' declare variables
'' variables ending with $ will default to string
'' other variables default to integer
'' we could also explicitly put "as string" or "as integer"
dim line$, cmd$, arg$
dim first

'' main loop
do
    input "enter command"; line$
    first = instr(1, line$, " ")  ' find first space
    if first <> 0 then
      ' if there is a space, split into command and argument
      cmd$ = left$(line$, first-1)
      arg$ = mid$(line$, first+1, 9999)
    else
      ' no space, just a command (like "help")
      cmd$ = line$
      arg$ = ""
    endif
    ' now actually do the command (see subroutine below)
    docommand(cmd$, arg$)
loop

''
'' subroutine: print help
''
sub showhelp()
  print "hi n  : set pin n high"
  print "lo n  : set pin n low"
  print "help  : show this help"
end sub

''
'' subroutine do commands
'' parameters:
''   cmd$: string giving the command
''   num$: string giving the argument to the command
''
sub docommand(cmd$, num$)
  dim n as integer  ' the numeric value of what's in num$
  if cmd$ = "help" or cmd$ = "?" then
    showhelp()
  else if cmd$ = "hi" then
    n = validate_pin(num$)  ' num$ should be a pin
    if n >= 0 then          ' if a valid pin, set it high
      pinhi(n)
    endif
  else if cmd$ = "lo" then
    n = validate_pin(num$)
    if n >= 0 then          ' again, if valid pin, set it high
      pinlo(n)
    endif
  else
    print "Unknown command '"; cmd$; "'"
    showhelp()
  endif
end sub

''
'' check to make sure num$ is a string representing a valid pin
'' returns -1 if it is not, otherwise returns the pin number
''
function validate_pin(num$ as string) as integer
  dim n as integer
  ' make sure the string has a number in it
  if num$ >= "0" and num$ <= "99" then
    n = val(num$)
  else
    n = -1  ' no number in string, so it's invalid
  endif
  if n < 0 or n >= 64 then
    print "bad pin number: "; num$
    n = -1  ' invalid pin
  endif
  return n
end function
