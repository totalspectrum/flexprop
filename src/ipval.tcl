#
# code for entering IP addresses
# the new IP is entered into the global savedip variable
#

namespace eval IpEntry {

    set ipname "localhost"
    set ipval 127.0.0.1
    set entry_callback "null"
    
    proc addIpAddress { callback } {
	global config
	variable entry_callback

	set entry_callback $callback
	
	toplevel .ipentry
	wm title .ipentry "Enter IP Address"

	frame .ipentry.f
	
	label .ipentry.f.lname -text "Name: "
	entry .ipentry.f.ename -textvar ::IpEntry::ipname
	label .ipentry.f.lval -text "Address: "
	entry .ipentry.f.eval -textvar ::IpEntry::ipval

	ttk::button .ipentry.f.ok -text " OK " -default normal -command ::IpEntry::done
	ttk::button .ipentry.f.cancel -text " Cancel " -command ::IpEntry::cancel
	grid .ipentry.f -column 2 -row 2 -sticky nsew
	grid .ipentry.f.lname .ipentry.f.ename
	grid .ipentry.f.lval  .ipentry.f.eval
	grid .ipentry.f.ok .ipentry.f.cancel

	#bind .ipentry <Return> ::IpEntry::done
    }

    proc done { } {
	global config
	variable ipname
	variable ipval
	variable entry_callback

	set entry [list $ipname $ipval]

	# update savedips with the new entry
	set idx 0
	set deleteidx -1
	set mylist $config(savedips)
	foreach e $mylist {
	    if { [lindex $e 0] eq "$ipname" } {
		# delete old entry
		set deleteidx $idx
	    }
	    incr idx
	}
	if { $deleteidx != -1 } {
	    set config(savedips) [lreplace $config(savedips) $deleteidx $deleteidx]
	}
	if { "$ipval" ne "" } {
	    lappend config(savedips) $entry
	}
	eval $entry_callback
	destroy .ipentry
    }

    proc cancel { } {
	destroy .ipentry
    }

    proc null { } {
	puts "null callback called"
    }
}
