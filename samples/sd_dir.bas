'
' SD Card directory listing sample
'
#include "dir.bi"

dim fname as string

' the next two lines are for testing SD
mount "/sd", _vfs_open_sdcard()
chdir "/sd/sub"

' the next two lines are for testing the P9 host file system
'mount "/host", _vfs_open_host()
'chdir "/host/debug"

print "current directory is: "; curdir$()
print "Listing:"

fname = dir$("*.*", 0)
while fname <> "" and fname <> nil
  print fname
  fname = dir$()
end while
print "done"
