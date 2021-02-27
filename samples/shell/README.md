# Simple shell for copying files

## Description

This is a simple C program to allow copying of files between host and SD card.

The commands available may be shown by typing "help" at the prompt. They are:
```
cd            :  show current directory path
cd <d>        :  change to directory <d>
copy <a> <b>  :  copy file <a> to <b>
del <f>       :  delete ordinary file <f>
dir           :  display contents of current directory
dir <d>       :  display contents of directory <d>
exec <f>      :  execute file <f> (never returns)
help          :  show this help
mkdir <d>     :  create new directory <d>
rmdir <d>     :  remove directory <d>
type  <f>     :  show file <f> on the terminal
```

The SD card (if found) is mounted as "/sd", and the host file system mounted as "/host".

Communication with the host PC is done using the 9P file system protocol, running over the serial line. This is set to the default baud rate of 230400, which is rather slow.

### Example: copying a file from host to SD

```
copy /host/myfile.txt /sd/myfile.txt
dir /sd
```

After the "dir /sd" command you should see MYFILE.TXT on the SD card (the FAT file system is case insensitive and defaults to 8.3 file names).

### Example: copying a file from SD to host

In this example "log.txt" is copied from the SD card directory "logs" to the host, and renamed as "log-current.txt"
```
copy /sd/logs/log.txt /host/log-current.txt
```

### Limitations

No wildcards are supported (so "copy *.txt /sd" will not work).

Only one file at a time may be copied.

There's no way to see the contents of the fake "root" directory /.

## Parts Used

P2 Eval board. (Probably any P2 board would work, actually!)

## Source Code

See attached.

## Programming Language

FlexC (needs FlexProp version 5.1.1-beta or later)

## Tools and Operating System

FlexProp (for Windows, Mac OS, or Linux)

