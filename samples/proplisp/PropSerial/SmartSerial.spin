'
' SmartSerial.spin2
' simple smart pin serial object for P2 eval board
' implements a subset of FullDuplexSerial functionality
'
CON
  _txmode       = %0000_0000_000_0000000000000_01_11110_0 'async tx mode, output enabled for smart output
  _rxmode       = %0000_0000_000_0000000000000_00_11111_0 'async rx mode, input  enabled for smart input

VAR
  long rx_pin, tx_pin

PUB start(rxpin, txpin, mode, baudrate) | bitperiod, bit_mode
  ' calculate delay between bits
  bitperiod := (CLKFREQ / baudrate)

  ' save parameters in the object
  rx_pin := rxpin
  tx_pin := txpin

  ' calculate smartpin mode for 8 bits per character
  bit_mode := 7 + (bitperiod << 16)

  ' set up the transmit pin
  pinf(txpin)
  wrpin(txpin, _txmode)
  wxpin(txpin, bit_mode)
  pinl(txpin)	' turn smartpin on by making the pin an output

  ' set up the receive pin
  pinf(rxpin)
  wrpin(rxpin, _rxmode)
  wxpin(rxpin, bit_mode)
  pinl(rxpin)  ' turn smartpin on

' send one byte
PUB tx(val)
  wypin(tx_pin, val)
  txflush

' wait for character sent
PUB txflush() | z
  repeat
    z := pinr(tx_pin)
  while z == 0
  
' check if byte received (never waits)
' returns -1 if no byte, otherwise byte

PUB rxcheck() : rxbyte | rxpin, z
  rxbyte := -1
  rxpin := rx_pin
  z := pinr(rxpin)
  if z
    rxbyte := rdpin(rxpin)>>24

' receive a byte (waits until one ready)
PUB rx() : v
  repeat
    v := rxcheck
  while v == -1

' transmit a string
PUB str(s) | c
  REPEAT WHILE ((c := byte[s++]) <> 0)
    tx(c)

PUB dec(value) | i, x

'' Print a decimal number
  result := 0
  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative
    tx("-")                                                                     'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i                                                               
      tx(value / i + "0" + x*(i == 1))                                          'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      tx("0")                                                                   'If zero digit (or only digit) output it
    i /= 10                                                                     'Update divisor

PUB hex(val, digits) | shft, x
  shft := (digits - 1) << 2
  repeat digits
    x := (val >> shft) & $F
    shft -= 4
    if (x => 10)
      x := (x - 10) + "A"
    else
      x := x + "0"
    tx(x)
