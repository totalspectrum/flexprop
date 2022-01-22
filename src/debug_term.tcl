#
# DEBUG TERM implementation
# Copyright 2022 Total Spectrum Software, Inc.
# MIT Licensed
#

namespace eval DebugWin {

    proc TermCmd { topname args } {
	set args [lindex $args 0]
	set w $topname.txt
	if { ![winfo exists $w] } {
	    return
	}
	while { [llength $args] > 0 } {
	    set cmd [fetcharg args]
	    set ch [string index $cmd 0]
	    set txt ""
	    if { "$ch" eq "\'" } {
		set txt [string range $cmd 1 end-1]
	    } else {
		switch $cmd {
		    "clear" {
			$w delete 1.0 end
		    }
		    "update" { }
		    "" { }
		    "1" {
			$w mark set insert 1.0
		    }
		    "close" {
			destroy $topname
		    }
		    default {
			if { $cmd > 31 } {
			    set txt "[format %c $cmd]"
			}
		    }
		}
	    }
	    if { "$txt" ne "" } {
		set len [string length $txt]
		$w delete insert "insert + $len chars"
		$w insert insert "$txt"
	    }
	}
    }

    proc CreateTermWindow {name args} {
	variable delayed_updates
	set top .toplev$name

	if { [winfo exists $top] } {
	    return
	}
	#set len [llength $args]
	#puts "CreateTermWindow: len=$len args=$args"
	set args [lindex $args 0]
	#set len [llength $args]
	#puts "CreateTermWindow: len=$len args=$args"

	set title "$name - TERM"
	set pos_x 0
	set pos_y 0
	set size_w 40
	set size_h 20
	set textsize 8
	set fgcolor "#ffffff"
	set bgcolor "#000000"
	set delayed 0
	
	while { [llength $args] > 0 } {
	    set cmd [fetcharg args]
#	    puts "   CreateTermWindow: cmd=($cmd) args=$args"
	    switch $cmd {
		"size" {
		    set size_w [fetchnum args $size_w]
		    set size_h [fetchnum args $size_h]
		}
		"textsize" {
		    set textsize [fetchnum args $textsize]
		}
		"title" {
		    set title [getstring [fetcharg args]]
		}
		"color" {
		    set fgcolor [fetchcolor args ""]
		}
		"backcolor" {
		    set bgcolor [fetchcolor args ""]
		}
		"update" {
		    set delayed 1
		}
		"" {
		}
		default {
		    puts "Unknown TERM option $cmd"
		}
	    }
	}
	set wfont [font create -family Courier -size $textsize]
	#puts "text $w.txt -bg $bgcolor -fg $fgcolor -font $wfont -height $size_h -width $size_w"
	toplevel $top
	text $top.txt -bg $bgcolor -fg $fgcolor -font $wfont -height $size_h -width $size_w -wrap none
	grid columnconfigure $top 0 -weight 1
	grid rowconfigure $top 0 -weight 1
	grid $top.txt -sticky nsew

	wm title $top $title

	set delayed_updates($top) $delayed
	
	return $top
    }    
}
