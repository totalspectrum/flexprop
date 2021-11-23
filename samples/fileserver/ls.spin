''
'' simple program to display a directory listing from
'' the host file system
''
#ifndef _BAUD
#ifdef __P2__
#define _BAUD 230_400
#else
#define _BAUD 115_200
#endif
#endif

CON
  _clkfreq = 180_000_000
  BUFSIZ = 128
  
OBJ
#ifdef __P2__
  ser: "spin/SmartSerial"
#else
  ser: "spin/FullDuplexSerial"
#endif
  fs: "fs9p.cc"

VAR
  long myfd[4]
  byte buf[BUFSIZ]
  
PUB demo | r
  ser.start(63, 62, 0, _BAUD)
  ser.printf(@"file system demo in Spin\n")
  r := fs.fs_init(@sendrecv)
  if r < 0
    ser.printf(@"fs_init returned error %d\n", r)
    die
  ''ser.printf("fs_init succeeded\n")
  r := fs.fs_open(@myfd, string("."), 0)
  if (r < 0)
    ser.printf(@"fs_open returned error %d\n", r)
    die
  repeat
    r := fs.fs_read(@myfd, @buf, BUFSIZ)
    'ser.printf(@"fs_read returned %d\n", r)
    if (r > 0)
      printdir(@buf, r)
  until r =< 0
  fs.fs_close(@myfd)
  ser.printf(@"\ndone\n")
  die

PUB die
  ser.tx($FF)
  ser.tx($0)
  ser.tx($0)
  repeat

PUB getword(buf) : r
  r := byte[buf] + (byte[buf+1]<<8)

PUB getlong(buf) : r
  r := getword(buf) + (getword(buf+2)<<16)

PUB printdir(buf, buflen) | siz, typ, flen, s, nextbuf
  repeat while buflen > 0
    siz := getword(buf)
    if siz == 0
      return
    siz += 2
    nextbuf := buf + siz
    buf += 2
    buf += 6 ' skip over type and dev
    typ := byte[buf]
    buf += 17 ' skip over qid and mode
    buf += 8  ' skip over times
    flen := getlong(buf) ' get file length
    buf += 8         ' skip over file length
    s := getword(buf)   ' get length of name
    buf += 2
    repeat while s > 0
      ser.tx(byte[buf++])
      --s
    ser.tx(":") ' print a tab
    ser.tx(" ")
    ser.dec(flen)
    ser.str(string(" bytes"))
    ser.tx(13)
    ser.tx(10)
    buf := nextbuf
    buflen -= siz
    
'' routine for transmitting and receiving 9P protocol buffers

PUB sendrecv(startbuf, endbuf, maxlen) | len, buf, i, left
  len := endbuf - startbuf
  buf := startbuf
  long[startbuf] := len

  'dumphex(string("->"), startbuf, len)
  '' transmit magic sequence for loadp2
  ser.tx($FF)
  ser.tx($01)
  repeat while len > 0
    ser.tx(byte[buf++])
    len--

  ' now get response
  buf := startbuf
  byte[buf++] := ser.rx
  byte[buf++] := ser.rx
  byte[buf++] := ser.rx
  byte[buf++] := ser.rx
  len := long[startbuf]
  left := len - 4
  repeat while left > 0
    byte[buf++] := ser.rx
    --left
  'dumphex(string("<-"), startbuf, len)
  return len

PUB dumphex(msg, buf, len) | i
  ser.printf("%s:\n", msg)
  repeat i from 0 to len-1
    ser.hex(byte[buf], 2)
    ser.tx(" ")
    buf++
  ser.tx(13)
  ser.tx(10)
