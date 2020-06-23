''
'' recursive version of the hello world program
'' note: counts down instead of up!
''

loopit(4, [n:print "hello", n:])

sub loopit(n as integer, f as sub(x))
  if n <= 0 return
  f(n)
  loopit(n-1, f)
end sub
