'
' driver for the charlieplexed LED Matrix from the P2ES accessories
'
' Based on code posted to the forums by dgately and localroger
' I'm not sure what license they intended, but for my part I'm placing
' my contributions in the public domain - Eric Smith
'

CON
    basepin  = 32   ' start of pins that the LED matrix is connected to
    BUF_LEN = 64    ' character buffer, make this a power of 2

var
    long cognum     ' cog driver is running in
    long stack[128] ' stack for cog
    byte bitmap[7]  ' bitmap data for charlieplexing
    long delay      ' delay in cycles before character update
    
    ' buffered data
    ' the buffer is empty when rdidx == wridx
    byte buf[BUF_LEN] ' character data buffer
    long rdidx        ' read index
    long wridx        ' write index

'
' start up the driver in a new cog
' the rundisplay() routine runs there, constantly updating the
' matrix
'
pub start
   delay := clkfreq / 600
   rdidx := wridx := 0
   cognum := cognew(rundisplay, @stack[0])
   return cognum+1

'
' stop the driver
'
pub stop
    if cognum
        cogstop(cognum-1)
	cognum := 0

' utility function; find the next valid index
' in the buffer
pri nextindex(i)
  return (i+1) & (BUF_LEN-1)

' transmit one character, which will scroll across the display
pub tx(c) | i
   i := nextindex(wridx)
   repeat
     ' if the next index == the read index, then
     ' the buffer is full
     ' wait for reading side to fetch some data
   while (rdidx == i)
   buf[i] := c
   wridx := i

' transmit a string to scroll across the display
pub str(s) | c
    repeat
        c := byte[s++]
        if c == 0
           quit
        tx(c)

' here's the actual charlieplexed display driver

pub rundisplay | i, j, s, r, lastc, curc
    curc := (" " - 32)
    repeat
        lastc := curc
        i := rdidx
        if i == wridx
            curc := " " - 32
        else
            curc := buf[i] - 32
            if (curc < 0)
                curc := 0
            rdidx := nextindex(i)
        repeat s from 0 to 5
            repeat j from 0 to 6
                r := charset[7 * lastc + j] << 6 + charset[7 * curc + j]
                r := r -> 4 <- s 
                bitmap[6-j] := r
            repeat 5
                charlieplex

pri charlieplex | row, outmask, dirmask
    'charlieplex the regularized bitmap to the LED matrix
    repeat row from 0 to 7 'charlieplex row, not bitmap row
        'outx byte gets only the positive drive bit on, all others off
        outmask := 1 << row
        'dirx must get the positive drive bit and all others that are set in the bitmap
        'each charlieplex row consists of left and right parts of two bitmap rows
        'at the top and bottom nonexistent bitmap rows are loaded, but then are masked out
        dirmask := outmask + byte[@bitmap + row - 1] >> (8 - row) + (byte[@bitmap + row] & (127 >> row)) << (row + 1)
        if basepin < 32
            outa[basepin..basepin+7] := outmask 
            dira[basepin..basepin+7] := dirmask 
        else
            outb[basepin..basepin+7] := outmask 
            dirb[basepin..basepin+7] := dirmask 
        waitcnt(delay + cnt)
        dira[basepin..basepin+7] := 0
        
       
DAT

charset

' space
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
' !
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %00000
    byte %00100
' "
    byte %01010
    byte %01010
    byte %01010
    byte %00000
    byte %00000
    byte %00000
    byte %00000
' #
    byte %01010
    byte %01010
    byte %11111
    byte %01010
    byte %11111
    byte %01010
    byte %01010
' $
    byte %01010
    byte %01111
    byte %11010
    byte %01110
    byte %01011
    byte %11110
    byte %01010
' byte %
    byte %11001
    byte %11001
    byte %00010
    byte %00100
    byte %01000
    byte %10011
    byte %10011
' &
    byte %01100
    byte %10010
    byte %10100
    byte %01000
    byte %10101
    byte %10010
    byte %01101
' '
    byte %00100
    byte %00100
    byte %01000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
' (
    byte %00010
    byte %00100
    byte %01000
    byte %01000
    byte %01000
    byte %00100
    byte %00010
' )
    byte %01000
    byte %00100
    byte %00010
    byte %00010
    byte %00010
    byte %00100
    byte %01000
' *
    byte %00100
    byte %10101
    byte %01110
    byte %11111
    byte %01110
    byte %10101
    byte %00100
' +
    byte %00000
    byte %00100
    byte %00100
    byte %11111
    byte %00100
    byte %00100
    byte %00000
' ,
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00110
    byte %01100
' -
    byte %00000
    byte %00000
    byte %00000
    byte %11111
    byte %00000
    byte %00000
    byte %00000
' .
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00110
    byte %00110
' /
    byte %00001
    byte %00001
    byte %00010
    byte %00100
    byte %01000
    byte %10000
    byte %10000
' 0
    byte %01110
    byte %10001
    byte %10011
    byte %10101
    byte %11001
    byte %10001
    byte %01110
' 1
    byte %00100
    byte %01100
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %01110
' 2
    byte %01110
    byte %10001
    byte %00001
    byte %00010
    byte %00100
    byte %01000
    byte %11111
' 3
    byte %01110
    byte %10001
    byte %00001
    byte %00110
    byte %00001
    byte %10001
    byte %01110
' 4
    byte %00010
    byte %00110
    byte %01010
    byte %10010
    byte %11111
    byte %00010
    byte %00010
' 5
    byte %11111
    byte %10000
    byte %10000
    byte %11110
    byte %00001
    byte %00001
    byte %11110
' 6
    byte %00111
    byte %01000
    byte %10000
    byte %11110
    byte %10001
    byte %10001
    byte %01110
' 7
    byte %11111
    byte %10001
    byte %00001
    byte %00010
    byte %00100
    byte %00100
    byte %00100
' 8
    byte %01110
    byte %10001
    byte %10001
    byte %01110
    byte %10001
    byte %10001
    byte %01110
' 9
    byte %01110
    byte %10001
    byte %10001
    byte %01111
    byte %00001
    byte %00010
    byte %01100
' :
    byte %00000
    byte %00000
    byte %00110
    byte %00110
    byte %00000
    byte %00110
    byte %00110
' ' 
    byte %00000
    byte %00000
    byte %00110
    byte %00110
    byte %00000
    byte %00110
    byte %01100
' <
    byte %00011
    byte %00100
    byte %01000
    byte %10000
    byte %01000
    byte %00100
    byte %00011
' =
    byte %00000
    byte %00000
    byte %11111
    byte %00000
    byte %11111
    byte %00000
    byte %00000
' >
    byte %11000
    byte %00100
    byte %00010
    byte %00001
    byte %00010
    byte %00100
    byte %11000
' ?
    byte %01110
    byte %10001
    byte %00001
    byte %00010
    byte %00100
    byte %00000
    byte %00100
' @
    byte %01110
    byte %10001
    byte %10001
    byte %10111
    byte %10110
    byte %10000
    byte %01111
' A
    byte %00100
    byte %01010
    byte %10001
    byte %10001
    byte %11111
    byte %10001
    byte %10001
' B
    byte %11110
    byte %10001
    byte %10001
    byte %11110
    byte %10001
    byte %10001
    byte %11110
' C
    byte %01110
    byte %10001
    byte %10000
    byte %10000
    byte %10000
    byte %10001
    byte %01110
' D
    byte %11110
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %11110
' E
    byte %11111
    byte %10000
    byte %10000
    byte %11110
    byte %10000
    byte %10000
    byte %11111
' F
    byte %11111
    byte %10000
    byte %10000
    byte %11110
    byte %10000
    byte %10000
    byte %10000
' G
    byte %01110
    byte %10001
    byte %10000
    byte %10111
    byte %10001
    byte %10001
    byte %01111
' H
    byte %10001
    byte %10001
    byte %10001
    byte %11111
    byte %10001
    byte %10001
    byte %10001
' I
    byte %01110
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %01110
' J
    byte %00001
    byte %00001
    byte %00001
    byte %00001
    byte %10001
    byte %10001
    byte %01110
' K
    byte %10001
    byte %10010
    byte %10100
    byte %11000
    byte %10100
    byte %10010
    byte %10001
' L
    byte %10000
    byte %10000
    byte %10000
    byte %10000
    byte %10000
    byte %10000
    byte %11111
' M
    byte %10001
    byte %11011
    byte %10101
    byte %10001
    byte %10001
    byte %10001
    byte %10001
' N
    byte %10001
    byte %10001
    byte %11001
    byte %10101
    byte %10011
    byte %10001
    byte %10001
' O
    byte %01110
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %01110
' P
    byte %11110
    byte %10001
    byte %10001
    byte %11110
    byte %10000
    byte %10000
    byte %10000
' Q
    byte %01110
    byte %10001
    byte %10001
    byte %10001
    byte %10101
    byte %01110
    byte %00011
' R
    byte %11110
    byte %10001
    byte %10001
    byte %11110
    byte %10010
    byte %10001
    byte %10001
' S
    byte %01110
    byte %10001
    byte %10000
    byte %01110
    byte %00001
    byte %10001
    byte %01110
' T
    byte %11111
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %00100
' U
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %01110
' V
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %01010
    byte %01010
    byte %00100
' W
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %10101
    byte %10101
    byte %11011
' X
    byte %10001
    byte %10001
    byte %01010
    byte %00100
    byte %01010
    byte %10001
    byte %10001
' Y
    byte %10001
    byte %10001
    byte %01010
    byte %00100
    byte %00100
    byte %00100
    byte %00100
' Z
    byte %11111
    byte %00001
    byte %00010
    byte %00100
    byte %01000
    byte %10000
    byte %11111
' [
    byte %01110
    byte %01000
    byte %01000
    byte %01000
    byte %01000
    byte %01000
    byte %01110
' \
    byte %10000
    byte %10000
    byte %01000
    byte %00100
    byte %00010
    byte %00001
    byte %00001
' ]
    byte %01110
    byte %00010
    byte %00010
    byte %00010
    byte %00010
    byte %00010
    byte %01110
' ^
    byte %00100
    byte %01010
    byte %10001
    byte %00000
    byte %00000
    byte %00000
    byte %00000
' _
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %11111
' `
    byte %00100
    byte %00010
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
' a
    byte %00000
    byte %00000
    byte %01110
    byte %00001
    byte %01011
    byte %10001
    byte %01111
' b
    byte %10000
    byte %10000
    byte %10000
    byte %11110
    byte %10001
    byte %10001
    byte %11110
' c
    byte %00000
    byte %00000
    byte %01111
    byte %10000
    byte %10000
    byte %10000
    byte %01111
' d
    byte %00001
    byte %00001
    byte %00001
    byte %01111
    byte %10001
    byte %10001
    byte %01111
' e
    byte %00000
    byte %00000
    byte %01110
    byte %10001
    byte %11111
    byte %10000
    byte %01111
' f
    byte %00110
    byte %01001
    byte %01000
    byte %11100
    byte %01000
    byte %01000
    byte %01000
' g
    byte %01111
    byte %10001
    byte %10001
    byte %01111
    byte %00001
    byte %10001
    byte %01110
' h
    byte %10000
    byte %10000
    byte %10000
    byte %10110
    byte %11001
    byte %10001
    byte %10001
' i
    byte %00000
    byte %00100
    byte %00000
    byte %00100
    byte %00100
    byte %00100
    byte %00100
' j
    byte %00010
    byte %00000
    byte %00010
    byte %00010
    byte %10010
    byte %10010
    byte %01100
' k
    byte %10000
    byte %10000
    byte %10001
    byte %10010
    byte %11100
    byte %10010
    byte %10001
' l
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %00100
    byte %00100
' m
    byte %00000
    byte %00000
    byte %11010
    byte %10101
    byte %10101
    byte %10101
    byte %10001
' n
    byte %00000
    byte %00000
    byte %10110
    byte %11001
    byte %10001
    byte %10001
    byte %10001
' o
    byte %00000
    byte %00000
    byte %01110
    byte %10001
    byte %10001
    byte %10001
    byte %01110
' p
    byte %00000
    byte %10110
    byte %11001
    byte %10001
    byte %10001
    byte %11110
    byte %10000
' q
    byte %00000
    byte %01101
    byte %10011
    byte %10001
    byte %10001
    byte %01111
    byte %00001
' r
    byte %00000
    byte %00000
    byte %10110
    byte %11001
    byte %10000
    byte %10000
    byte %10000
' s
    byte %00000
    byte %00000
    byte %01111
    byte %10000
    byte %01110
    byte %00001
    byte %11110
' t
    byte %00100
    byte %00100
    byte %01111
    byte %00100
    byte %00100
    byte %00101
    byte %00010
' u
    byte %00000
    byte %00000
    byte %10001
    byte %10001
    byte %10001
    byte %10001
    byte %01110
' v
    byte %00000
    byte %00000
    byte %10001
    byte %10001
    byte %01010
    byte %01010
    byte %00100
' w
    byte %00000
    byte %00000
    byte %10001
    byte %10001
    byte %10101
    byte %10101
    byte %01010
' x
    byte %00000
    byte %00000
    byte %10001
    byte %01010
    byte %00100
    byte %01010
    byte %10001
' y
    byte %00000
    byte %10001
    byte %10001
    byte %01111
    byte %00001
    byte %10001
    byte %01110
' z
    byte %00000
    byte %00000
    byte %11111
    byte %00010
    byte %00100
    byte %01000
    byte %11111
' {
    byte %00010
    byte %00100
    byte %00100
    byte %01000
    byte %00100
    byte %00100
    byte %00010
' |
    byte %00100
    byte %00100
    byte %00100
    byte %00000
    byte %00100
    byte %00100
    byte %00100
' }
    byte %01000
    byte %00100
    byte %00100
    byte %00010
    byte %00100
    byte %00100
    byte %01000
' ~
    byte %01010
    byte %10100
    byte %00000
    byte %00000
    byte %00000
    byte %00000
    byte %00000
' blot
    byte %11111
    byte %11111
    byte %11111
    byte %11111
    byte %11111
    byte %11111
    byte %11111
'
