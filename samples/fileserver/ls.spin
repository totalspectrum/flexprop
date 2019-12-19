''
'' simple program to display a directory listing from
'' the host file system
''
CON
  mode = $010007f8
  freq = 160_000_000
  BUFSIZ = 128
  
OBJ
  ser: "spin/SmartSerial"
  fs: "fs9p.cc"

VAR
  long myfd[4]
  byte buf[BUFSIZ]
  
PUB demo | r
  clkset(mode, freq)
  ser.start(63, 62, 0, 230_400)
  ser.printf("file system demo in Spin\n")
  r := fs.fs_init(@sendrecv)
  if r < 0
    ser.printf("fs_init returned error %d\n", r)
    die
  ''ser.printf("fs_init succeeded\n")
  r := fs.fs_open(@myfd, ".", 0)
  if (r < 0)
    ser.printf("fs_open returned error %d\n", r)
    die
  repeat
    r := fs.fs_read(@myfd, @buf, BUFSIZ)
    if (r > 0)
      printdir(@buf, r)
  until r =< 0
  fs.fs_close(@myfd)
  ser.printf("done")
  die

PUB die
  ser.tx($FF)
  ser.tx($0)
  ser.tx($0)
  repeat

PUB printdir(buf, buflen) | siz, typ, flen, s, nextbuf
  repeat while buflen > 0
    siz := word[buf]
    if siz == 0
      return
    nextbuf := buf + siz
    buf += 2
    buf += 6 ' skip over type and dev
    typ := byte[buf]
    buf += 17 ' skip over qid and mode
    buf += 8  ' skip over times
    flen := long[buf] ' get file length
    buf += 8         ' skip over file length
    s := word[buf]   ' get length of name
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
  return len
