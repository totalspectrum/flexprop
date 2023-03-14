'
' example of using the built-in FLASH memory on the P2 Eval board
' to save some data
'
' Written by Eric R. Smith and placed in the public domain

#ifndef __P2__
#error "This demo requires a P2"
#endif

const AUTO_FORMAT_NO =  0   ' no automatic format of flash
const AUTO_FORMAT_YES = 1   ' format flash if necessary

' flash configuration
' this is the default config used by C (6MB starting at offset 2MB),
' change it if you want

dim shared as ulong(9) flashcfg = {
  256,          ' page size for writes
  65536,        ' block size for erases
  2*1024*1024,  ' starting address (must be a multiple of erase block size)
  6*1024*1024,  ' size of file system (must be a multiple of erase block size)
  0, 0, 0, 0    ' reserved
}

dim as integer choice  ' which choice the user selected

'
' first, we have to mount the flash file system
'
mount "/flash", _vfs_open_littlefs_flash(AUTO_FORMAT_YES, flashcfg)

' for testing, we could use the host file system instead
' mount "/flash", _vfs_open_host() ' for development / testing


' now loop asking the user whether to show old message or
' write new message

do
  print
  print "(1) see previous message"
  print "(2) save new message"
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

'
' routine to show an old message
'
sub show_message()
  dim as string msg$
  dim as integer err

  ' try to open the message file
  ' if we cannot, fail and return
  try
    open "/flash/msg.txt" for input as #3
  catch err
    print "Unable to open msg.txt, error is:", err
    return
  end try

  print "Message is:"
  ' read the whole file
  do
      ' get up to 1024 characters from the file
      msg$ = input$(1024, 3)
      print msg$;
  loop while msg$ <> ""
  
  close #3
  print "<END>"
end sub

'
' routine to write a new message into the file
'
sub save_message()
  dim as string a$
  dim as integer err

  ' try to open or create the file
  try
    open "/flash/msg.txt" for output as #3
  catch err
    print "Unable to open msg.txt, error is:", err
    return
  end try

  ' read lines from the user
  ' an empty line will read as "", so terminates the loop
  print "Enter your message (terminate with an empty line):"
  do
    line input a$
    if a$ <> "" then
       print #3, a$  
    endif
  loop until a$ = ""
  
  print "<END>"
  close #3
end sub

