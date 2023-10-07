# Simple shell for copying files

## Description

This is a simple C program to allow copying of files between host and SD card or flash.

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
ren <f> <new> :  rename file <f> to <new>
rmdir <d>     :  remove directory <d>
type  <f>     :  show file <f> on the terminal
mount <d>     :  mount flash, SD card, or ramdisk
unmount <d>   :  unmount flash, SD, or ramdisk
mkfs /flash   :  format flash with little fs
mkfs /ram     :  format RAM disk with little fs
mkfs /pfs     :  format flash with Parallax flash file system
```

Known mount points:
```
/host         : host file system over serial
/sd           : Fat32 file system on SD card (not compatible with flash)
/flash        : littlefs file system on flash
/ram          : littlefs file system on ramdisk
/pfs          : Parallax file system on flash (experimental)
```

The host file system is automatically mounted as `/host`. The user may then choose to mount either the FAT formatted SD card (as `/sd`) or the littlefs formatted flash drive (as `/flash`). Only 6 MB of the flash, starting at the 2 MB mark, is used for the file system, the rest is free for other uses (such as storing boot code). If the flash is not properly formatted it will automatically be formatted on mount.

The ramdisk configuration may be changed by editing shell.c and changing the defines and structs at the top. This only matters if the ramdisk is actually used (via `mount /ram`).

Communication with the host PC is done using the 9P file system protocol, running over the serial line. This is set to the default baud rate of 230400, which is rather slow.

### Example: copying a file from host to SD

```
mount /sd
copy /host/myfile.txt /sd/myfile.txt
dir /sd
```

After the "dir /sd" command you should see MYFILE.TXT on the SD card (the FAT file system is case insensitive and defaults to 8.3 file names).

### Example: copying a file from SD to host

In this example "log.txt" is copied from the SD card directory "logs" to the host, and renamed as "log-current.txt"
```
mount /sd
copy /sd/logs/log.txt /host/log-current.txt
```

### Limitations

No wildcards are supported (so "copy *.txt /sd" will not work).

Only one file at a time may be copied.

Flash and SD may not be mounted at the same time.

## Parts Used

P2 Eval board. (Probably any P2 board would work, actually!)

## Source Code

See attached.

## Programming Language

FlexC (needs FlexProp version 5.1.1-beta or later)

## Tools and Operating System

FlexProp (for Windows, Mac OS, or Linux)

