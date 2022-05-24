'
' Demo for writing to a file
' Defaults to the SD card, but you can change the commented lines to make it work
' on the host PC's file system instead
'

' mount the SD card on a directory called "/dir"
' (so files will be named like "/dir/foo.txt", "/dir/bar/baz.txt", and so on)

'mount "/dir", _vfs_open_sdcard()

' for Host
mount "/dir", _vfs_open_host()

' open the file for writing; the #3 identifies the file
open "/dir/hello.txt" for output as #3

' print to the file we previously identified as #3
print #3, "Hello, world!"
print #3, "Goodbye!"

' close the file
close #3

' now open it to read back what was written
print "read back:"
print "----------"

' declare a string variable to hold our data
dim a$ as string

' re-open the file for reading
' we could actually re-use the identifier #3, since we closed
' it earlier, but for clarity we will identify the input file
' as #4
open "/dir/hello.txt" for input as #4

' keep reading data until end of file (at which point the input will
' return nil
do
  ' read a whole line at a time
  ' if we used just "input" the line would be parsed into strings and numbers
  line input #4, a$
  ' break when EOF is seen
  if a$ = nil exit loop
  ' print what we read
  print a$
loop

' close the file
close #4

'
print "----------"
print "all done!"
