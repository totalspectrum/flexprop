'
' Demo for writing to a file
' Defaults to the SD card, but you can change the commented lines to make it work
' on the host PC's file system instead
'

' mount the SD card on a directory called "/dir"
' (so files will be named like "/dir/foo.txt", "/dir/bar/baz.txt", and so on)

mount "/dir", _vfs_open_sdcard()

' for Host
'mount "/dir", _vfs_open_host()

' open the file for writing
open "/dir/hello.txt" for output as #3
print #3, "Hello world!"
close #3

' now open it to read back what was written
dim a$ as string
open "/dir/hello.txt" for input as #4
input #4, a$
print "read back:"
print a$
close #4
