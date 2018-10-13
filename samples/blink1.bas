''
'' simple program to blink an LED in BASIC
''
const ledpin = 16

'' set the pin to output
direction(ledpin) = output

do
  output(ledpin) = 1
  pausems 500
  output(ledpin) = 0
  pausems 500
loop
