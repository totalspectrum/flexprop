dim ch as integer
print "Echo test: type characters and see the ASCII read
do
  ch = _rxraw() ' read a byte from keyboard without interpretation
  print "read character ", ch
loop
