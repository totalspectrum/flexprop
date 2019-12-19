const mode=0x010007f8
const freq=160_000_000
const baud=230_400

dim f as class using "fs9p.cc"
dim ser as class using "spin/SmartSerial"
dim r as integer
dim handle as any
dim crlf as ubyte(2)

clkset(mode, freq)
ser.start(63, 62, 0, baud)

r = f.fs_init(@sendrecv)
if r < 0 then
  ser.printf("fs_init failed with code %d\n", r)
  die
end if

' we don't have a type that matches the C fs_file type, so use
' a small integer array and an handle of type ANY
dim L as integer(4)
handle = @L

r = f.fs_create(handle, "hello.txt")
if r < 0 then
  ser.printf("fs_create failed with code %d\n", r)
  die
end if

pausems(100) ' for debugging
r = f.fs_write(handle, "Hello from the P2!", 18)
crlf(0) = 13
crlf(1) = 10
r = f.fs_write(handle, crlf, 2)
pausems(100) ' for debugging
f.fs_close(handle)

ser.printf("done creating file\r\n")
die

sub die
  do
  loop
end sub

function sendrecv(startbuf as ubyte ptr, endbuf as ubyte ptr, maxlen as integer) as integer
  var len = endbuf - startbuf
  var buf = startbuf
  dim lenptr as integer ptr
  dim origlen as integer
  
  startbuf(0) = len and $ff
  startbuf(1) = (len>>8) and $ff
  startbuf(2) = (len>>16) and $ff
  startbuf(3) = (len>>24) and $ff
  ser.tx($ff)
  ser.tx($01)
  while len > 0
    ser.tx(buf(0))
    buf = buf+1
    len = len-1
  end while
  startbuf(0) = ser.rx()
  startbuf(1) = ser.rx()
  startbuf(2) = ser.rx()
  startbuf(3) = ser.rx()
  lenptr = cast(integer ptr, startbuf)
  len = lenptr(0)
  origlen = len
  buf = @startbuf(4)
  len = len - 4
  while len > 0
    buf(0) = ser.rx()
    buf = buf+1
    len = len-1
  end while
  return origlen
end function
