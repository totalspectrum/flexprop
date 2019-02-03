'
' blink in Spin
'
con
  pin = 56
  freq = 160_000_000
  mode = $010007f8
  delay = freq / 10

pub demo
  clkset(mode, freq)
  dirb[pin-32] := 1
  repeat
    !outb[pin-32]
    waitcnt(cnt + delay)
