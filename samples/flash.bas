'
' example of using the built-in FLASH memory on the P2 Eval board
' to save some data
'

#ifndef __P2__
#error "This demo requires a P2"
#endif

' flash configuration
' this is the default config, but change it if you want
dim shared as ulong(9) flashcfg = {
  256,          ' page size for writes
  65536,        ' block size for erases
  2*1024*1024,  ' starting address (must be a multiple of erase block size)
  6*1024*1024,  ' size of file system (must be a multiple of erase block size)
  0, 0, 0, 0    ' reserved
}

dim as integer choice

'mount "/flash", _vfs_open_host() ' for development / testing
mount "/flash", _vfs_open_littlefs_flash(1, flashcfg)

do
  print
  print "(1) see previous message"
  print "(2) save message"
  input "Which one"; choice
  print
  if choice == 1 then
    show_message
  else if choice == 2 then
    save_message
  else
    print "invalid selection "; choice
  end if
loop

sub show_message()
  dim as string msg$
  dim as integer err
  try
    open "/flash/msg.txt" for input as #3
  catch err
    print "Unable to open msg.txt, error is:", err
    return
  end try
  msg$ = input$(1024, 3)
  close #3
  print "Message is:"
  print msg$;
  print "<END>"
end sub

sub save_message()
  dim as string msg$, a$
  dim as integer err
  try
    open "/flash/msg.txt" for output as #3
  catch err
    print "Unable to open msg.txt, error is:", err
    return
  end try
  msg$ = ""
  print "Enter your message (terminate with an empty line):"
  do
    line input a$
    'print "read: ["; a$; "]"
    if a$ <> "" then
      msg$ = msg$ + a$ + chr$(10)
     endif
  loop until a$ = ""
  print "<END>"
  print #3, msg$;
  close #3
end sub

