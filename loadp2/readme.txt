                                   LOADP2
                                April 4, 2018
                                  Dave Hein

Loadp2 will load and execute a P2 binary file.  It can be built under Cygwin,
MinGW or Linux by running the correpsonding build_xxxxx script file.  After
loading, loadp2 will go into a terminal emulator mode if the -t option was
specified.  The -T option may be used to run the terminal emulator in the PST
mode.

An example of running loadp2 under Cygwin without the terminal emulator is as
follows.

./loadp2 -p com5 blink.bin

Here is an example of running loadp2 under Linux with the terminal emulator.

./loadp2 -p /dev/ttyUSB0 chess.bin -t

If the -p option isn't specified, loadp2 will search for a P2 on one of the
serial ports.  This is done as follows:

./loadp2 chess.bin -T

If no parameter are specified loadp2 will print out the following usage message.

loadp2 - a loader for the propeller 2 - version 0.005, 2018-04-04
usage: loadp2
         [ -p port ]               serial port
         [ -b baud ]               baud rate (default is 115200)
         [ -t ]                    enter terminal mode after running the program
         [ -T ]                    enter PST-compatible terminal mode
         [ -v ]                    enable verbose mode
         [ -? ]                    display a usage message and exit
         file                      file to load
