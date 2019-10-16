''
'' simple real time clock running in another cog
''
'' should work on either P1 or P2

' hours, minutes, seconds: 00-23, 00-59, 00-59
dim as ubyte hours, mins, secs

' month, day in month: 1-12, 1-31
dim as ubyte MM, DD

' year: 4 digits
dim as integer YYYY

dim stack(10)

''
'' helper subroutine; return number of days in month
''
function daysInMonth() as uinteger
  ' february special case
  if MM = 2 then
    if (YYYY mod 4 = 0) then
      if (YYYY mod 100 <> 0) or (YYYY mod 1000 = 0) then
        return 29
      endif
    endif
    return 28
  endif
  if (MM = 4) or (MM=6) or (MM=9) or (MM=11) return 30
  return 31
end function
    
''
'' routine to keep the clock up to date
''
sub updateClock
  dim nextSecond
  dim FREQUENCY

  FREQUENCY = clkfreq()
  nextSecond = getcnt() + FREQUENCY
  do
    waitcnt(nextSecond)
    nextSecond = nextSecond + FREQUENCY
    secs = secs + 1
    if (secs >= 60) then
      secs = 0
      mins = mins + 1
      if (mins >= 60) then
        mins = 0
	hours = hours + 1
	if (hours >= 24) then
	  hours = 0
	  DD = DD + 1
	endif
      endif
    endif
    if (DD > daysInMonth()) then
      DD = 1
      MM = MM + 1
      if (MM > 12) then
        MM = 1
	YYYY = YYYY + 1
      endif
    endif
  loop
end sub

''
'' main program
''

'' initialize the time
print "Enter year month day as YYYY-MM-DD ";
var s$ = input$(10)
print
'print "read ["; s$; "]"

YYYY = val(left$(s$, 4))
MM = val(mid$(s$, 6, 2))
DD = val(right$(s$, 2))

print "Enter time as hh:mm:ss ";
s$ = input$(8)
print

hours = val(left$(s$, 2))
mins = val(mid$(s$, 4, 2))
secs = val(right$(s$, 2))

' start the RTC update thread on another COG
var x = cpu(updateClock, @stack(1))

' now loop printing the time
do
  print using "####_-%%_-%%    "; YYYY; MM; DD;
  print using "##:%%:%%"; hours, mins, secs
  pausems(999)
loop
