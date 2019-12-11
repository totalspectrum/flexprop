#
# sample python code for running a blink program in another Cpu
#
import array
import pyb
import ubinascii

# the PASM code to run, compiled into hex
# the hex string here is the output of
#    xxd -c 256 -ps blink.binary
code=ubinascii.unhexlify('001104fb011304fb021504fb5f1060fd011404f1021564fc1f1260fdecff9ffd0000000000000000000000000000000000000000000000000000000000000000')

# data for the first pin (pin 57)
# we'll toggle 4 times/second (system clock frequency is 160 MHz)
data=array.array('i', [57, 40000000, 0])

cog=pyb.Cpu()
cog.start(code, data)

# start a second COG
data2=array.array('i', [56, 20000000, 0])
cog2=pyb.Cpu()
cog2.start(code, data2) # start on pin 56
