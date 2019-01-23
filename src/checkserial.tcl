#
# serial::listports returns a list of available serial ports
# sample from https://wiki.tcl-lang.org/page/serial+ports+on+Windows
# modified a bit by me (Eric Smith)
#
package require platform

namespace eval serial {
        variable platform   [lindex [split [platform::generic] -] 0]
}

proc serial::listports {} {
      variable platform

      set result {}
      switch -- $platform {
                win32 {
                        catch {
                                package require registry
                                set serial_base [join {
                                        HKEY_LOCAL_MACHINE
                                        HARDWARE
                                        DEVICEMAP
                                        SERIALCOMM} \\]
                                set values [ registry values $serial_base ]
                                foreach value $values {
                                        lappend result \\\\.\\[registry get $serial_base $value]
                                }
                        }
                }
                linux {
                        set result [glob -nocomplain {/dev/ttyS[0-9]} {/dev/ttyUSB[0-9]} {/dev/ttyACM[0-9]}]
                }
                macosx {
                        set result [glob -nocomplain {/dev/cu.usb*} {/dev/cu.pl*}]
                }
                netbsd {
                        set result [glob -nocomplain {/dev/tty0[0-9]} {/dev/ttyU[0-9]}]
                }
                openbsd {
                        set result [glob -nocomplain {/dev/tty0[0-9]} {/dev/ttyU[0-9]}]
                }
                freebsd {
                        # todo
                }
                default {
                        # shouldn't happen
                }
        }

        return [lsort $result]
}

#set serlist [serial::listports]
#foreach v $serlist {
#    puts $v
#}
