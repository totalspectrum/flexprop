'
' blink in Spin
'
con
  _clkfreq = 160_000_000
  pin = 56
  delay = _clkfreq / 10

pub demo
  dirb[pin-32] := 1
  repeat
    !outb[pin-32]
    waitcnt(cnt + delay)
