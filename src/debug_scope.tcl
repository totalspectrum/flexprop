#
# DEBUG SCOPE implementation
# Copyright 2022 Total Spectrum Software, Inc.
# MIT Licensed
#

namespace eval DebugWin {

    # Plot command functions
    proc ScopeCmd { topname args } {
	variable cur_x
	variable cur_y
	variable origin_x
	variable origin_y
	variable cur_color
	variable text_color
	
	set args [lindex $args 0]
	set w $topname.p
	if { ![winfo exists $w] } {
	    return
	}
	while { [llength $args] > 0 } {
	    set cmd [fetcharg args]
	    switch $cmd {
		"" {
		    # ignore
		}
		"clear" {
		    $w delete all
		}
		"update" {
		}
		"close" {
		    delete $topname
		}
		default {
		    puts "Unknown SCOPE command $cmd"
		}
	    }
	}
    }

    proc CreateScopeWindow {name args} {
	global config
	variable cur_color
	variable text_color
	variable cur_x
	variable cur_y
	variable origin_x
	variable origin_y
	variable delayed_updates
	variable polar_circle
	global config
	
	set top .toplev$name

	if { [winfo exists $top] } {
	    return
	}
	set args [lindex $args 0]
	set len [llength $args]

	set title "$name - SCOPE"
	set pos_x 0
	set pos_y 0
	set size_w 256
	set size_h 256
	set textsize 8
	set bgcolor black
	set delayed 0
	
	while { [llength $args] > 0 } {
	    set cmd [fetcharg args]
#	    puts "   CreatePlotWindow: cmd=($cmd) args=$args"
	    switch $cmd {
		"size" {
		    set size_w [fetcharg args]
		    set size_h [fetcharg args]
		}
		"color" {
		    set bgcolor [fetcharg args]
		}
		"title" {
		    set title [getstring [fetcharg args]]
		}
		"update" {
		    set delayed 1
		}
		"" {
		}
		default {
		    puts "Unknown PLOT option $cmd"
		}
	    }
	}
	set wfont [font create -family [::getDebugFontFamily] -size $textsize]
	toplevel $top
	set w $top.p
	#puts "canvas $w -bg $bgcolor -fg $fgcolor -height $size_h -width $size_w"
	canvas $w -bg $bgcolor -height $size_h -width $size_w

	grid columnconfigure $top 0 -weight 1
	grid rowconfigure $top 0 -weight 1
	grid $w -sticky nsew

	wm title $top $title

	# set up variables
	set cur_x($w) 0
	set cur_y($w) 0
	set origin_x($w) 0
	set origin_y($w) $size_h
	set cur_color($w) "#ffffff"
	set text_color($w) "#000"
	set polar_circle($w) 0
	set delayed_updates($top) $delayed
	
	return $top
    }
    
}
