'
' simple fibonacci demo
'

#ifdef __FASTSPIN__

const cycles_per_microsecond = 80.0

function getcycles() as uinteger
  return getcnt()
end function

sub pause
  waitcnt getcycles() + 80_000_000
end sub

#else
' these need to be implemented on
' your platform

const cycles_per_microsecond = 1.0
function getcycles() as uinteger
  return 0
end function

sub pause
end sub
#endif

function fibo(n as integer) as integer
  if (n < 2) then
    return n
  end if
  return fibo(n-1) + fibo(n-2)
end function

dim as uinteger cycles, i

pause
print "BASIC fibo demo"

for i = 1 to 12
  cycles = getcycles()
  var x = fibo(i)
  cycles = getcycles() - cycles
  print "fibo "; i; " = "; x,
  print "took "; cycles, "cycles ("; cycles / cycles_per_microsecond; " us)"
next i
