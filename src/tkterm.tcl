# Name: tkterm - terminal emulator using Expect and Tk text widget, v3.0
# Author: Don Libes, July '94
# Modified by: Eric R. Smith, Jan '22
# Last updated: Feb '22

# Adapted by ERS to be a terminal emulator, so many of the useful
# testing code has been stripped out.

# A paper on the implementation: Libes, D., Automation and Testing of
# Interactive Character Graphic Programs", Software - Practice &
# Experience, John Wiley & Sons, West Sussex, England, Vol. 27(2),
# p. 123-137, February 1997.

###############################
# Quick overview of this emulator
###############################
# Very good attributes:
#   Understands both termcap and terminfo   
#   Understands meta-key (zsh, emacs, etc work)
#   Is fast
#   Understands X selections
#   Looks best with fixed-width font but doesn't require it
#   Supports scrollbars
# Good-enough-for-starters attributes:
#   Understands one kind of standout mode (reverse video)
# Should-be-fixed-soon attributes:
#   Does not support resize
# Probably-wont-be-fixed-soon attributes:
#   Assumes only one terminal exists

###############################################
# To try out this package, just run it.  Using it in
# your scripts is simple.  Here are directions:
###############################################
# 0) make sure Expect is linked into your Tk-based program (or vice versa)
# 1) modify the variables/procedures below these comments appropriately
# 2) source this file
# 3) pack the text widget ($term) if you have so configured it (see
#    "term_alone" below).  As distributed, it packs into . automatically.

namespace eval TkTerm {
    namespace export RunInWindow
    
#############################################
# Variables that must be initialized before using this:
#############################################
    
set rows 25		;# number of rows in term
set rowsDumb $rows	;# number of rows in term when in dumb mode - this can
			;# increase during runtime
set cols 80		;# number of columns in term
set toplev .term    
set term $toplev.t	;# name of text widget used by term
set sb   $toplev.sb		;# name of scrollbar used by term in dumb mode
set term_alone 1	;# if 1, directly pack term into .
			;# else you must pack
set termcap 1		;# if your applications use termcap
set terminfo 1		;# if your applications use terminfo
			;# (you can use both, but note that
			;# starting terminfo is slow)

#############################################
# Readable variables of interest
#############################################
# cur_row		;# current row where insert marker is; starts at 1
# cur_col		;# current col where insert marker is; starts at 0

#############################################
# Procs you may want to initialize before using this:
#############################################

# term_exit is called if the spawned process exits
proc term_exit {} {
    exit
}

# term_chars_changed is called after every change to the displayed chars
# You can use if you want matches to occur in the background (a la bind)
# If you want to test synchronously, then just do so - you don't need to
# redefine this procedure.
proc term_chars_changed {} {
}

# term_cursor_changed is called after the cursor is moved
proc term_cursor_changed {} {
}

# Example tests you can make
#
# Test if cursor is at some specific location
# if {$cur_row == 1 && $cur_col == 0} ...
#
# Test if "foo" exists anywhere in line 4
# if {[string match *foo* [$term get 4.0 4.end]]}
#
# Test if "foo" exists at line 4 col 7
# if {[string match foo* [$term get 4.7 4.end]]}
#
# Test if a specific character at row 4 col 5 is in standout
# if {-1 != [lsearch [$term tag names 4.5] standout]} ...
#
# Return contents of screen
# $term get 1.0 end
#
# Return indices of first string on lines 4 to 6 that is in standout mode
# $term tag nextrange standout 4.0 6.end
#
# Replace all occurrences of "foo" with "bar" on screen
# for {set i 1} {$i<=$rows} {incr i} {
#	regsub -all "foo" [$term get $i.0 $i.end] "bar" x
#	$term delete $i.0 $i.end
#	$term insert $i.0 $x
# }

#############################################
# End of things of interest
#############################################

set term_standout 0	;# if in standout mode or not
set term_pipe ""        ;# I/O with remote

proc graphicsGet {} {
    variable graphics
    return $graphics(mode)
}
proc graphicsSet {mode} {
    variable graphics
    variable sb
    set graphics(mode) $mode

    if {$mode} {
	# in graphics mode, no scroll bars
	grid forget $sb
    } else {
	grid $sb -column 0 -row 0 -sticky ns
    }
}

# this shouldn't be needed if Ousterhout fixes text bug
proc term_create {} {
    variable toplev
    variable term
    variable cols
    variable rows
    variable sb
    global config

    if { $config(internal_term) eq "ansi" } {
	set kind "ANSI"
    } else {
	set kind "PST"
    }
    toplevel $toplev
    wm title $toplev "FlexProp $kind Terminal"
    
    text $term \
	-yscroll "$sb set" \
	-relief sunken -bd 1 -width $cols -height $rows -wrap none -setgrid 1 \
	-font InternalTermFont

    # define scrollbars
    scrollbar $sb -command "$term yview"

    grid $term -column 1 -row 0 -sticky nsew
    # let text box only expand
    grid rowconfigure $toplev 0 -weight 1
    grid columnconfigure $toplev 1 -weight 1

    $term tag configure standout -background  black -foreground white
}

proc term_clear {} {
    variable term

    $term delete 1.0 end
    term_init
}

# pine is the only program I know that requires clear_to_eol, sigh
proc term_clear_to_eol {} {
    variable cols
    variable cur_col
    variable cur_row
	
    # save current col/row
    set col $cur_col
    set row $cur_row

    set space_rem_on_line [expr {$cols - $cur_col}]
    term_insert [format %[set space_rem_on_line]s ""]

    # restore current col/row
    set cur_col $col
    set cur_row $row
}

# clear to end of screen
proc term_clear_to_eos {} {
    variable cols
    variable rows
    variable cur_col
    variable cur_row
    variable term
    
    # save current col/row
    set col $cur_col
    set row $cur_row

    # clear rest of this line
    set space_rem_on_line [expr {$cols - $cur_col}]
    term_insert [format %[set space_rem_on_line]s ""]

    # now clear remaining rows
    set blankline [format %*s $cols ""]\n
    for {set i [expr {$cur_row + 1}]} {$i <= $cols} {incr i} {
	$term delete $i.0 $i.end
	$term insert $i.0 $blankline
    }
}

proc term_init {} {
    variable rows
    variable cols
    variable cur_row
    variable cur_col
    variable cur_state
    variable term
    variable rowsDumb

    # initialize it with blanks to make insertions later more easily
    set blankline [format %*s $cols ""]\n
    for {set i 1} {$i <= $rows} {incr i} {
	$term insert $i.0 $blankline
    }

    set cur_row 1
    set cur_col 0
    set cur_state "normal"
    
    $term mark set insert $cur_row.$cur_col

    set rowsDumb $rows

    # initialize bindings
    doTermBindings
}

# NOT YET COMPLETE!
proc term_resize {rowsNew colsNew} {
    variable rows
    variable cols
    variable term

    foreach {set r 1} {$r < $rows} {incr r} {
	if {$colsNew > $cols} {
	    # add columns
	    $term insert $i.$column $blanks
	} elseif {$colsNew < $cols} {
	    # remove columns
	    # ?
	}
    }

    if {$rowsNew > $rows} {
	# add rows
    } elseis {$rowsNew < $rows} {
	# remove rows
    }
}

proc term_down {} {
    variable cur_row
    variable rows
    variable cols
    variable term
    variable rowsDumb
    
    if {$cur_row < $rows} {
	incr cur_row
    } else {
	if {[graphicsGet]} {
	    # in graphics mode

	    # already at last line of term, so scroll screen up
	    $term delete 1.0 "1.end + 1 chars"

	    # recreate line at end
	    $term insert end [format %*s $cols ""]\n
	} else {
	    # in dumb mode
	    incr cur_row

	    if {$cur_row > $rowsDumb} {
		set rowsDumb $cur_row
	    }

	    $term insert $cur_row.0 [format %*s $cols ""]\n
	    $term see $cur_row.0
	}
    }
}

proc term_up {} {
    variable cur_row
    variable rows
    variable cols
    variable term
    variable rowsDumb
    set cur_rowOld $cur_row
    incr cur_row -1

    if {($cur_rowOld > $rows) && ($cur_rowOld == $rowsDumb)} {
	if {[regexp "^ *$" [$term get $cur_rowOld.0 $cur_rowOld.end]]} {
	    # delete line
	    $term delete $cur_rowOld.0 end
	}
	incr rowsDumb -1
    }
}

proc term_insert {s} {
    variable cols
    variable cur_col
    variable cur_row
    variable term
    variable term_standout

    set chars_rem_to_write [string length $s]
    set space_rem_on_line [expr {$cols - $cur_col}]

    if {$term_standout} {
	set tag_action "add"
    } else {
	set tag_action "remove"
    }

    ##################
    # write first line
    ##################

    if {$chars_rem_to_write > $space_rem_on_line} {
	set chars_to_write $space_rem_on_line
	set newline 1
    } else {
	set chars_to_write $chars_rem_to_write
	set newline 0
    }

    $term delete $cur_row.$cur_col $cur_row.[expr {$cur_col + $chars_to_write}]
    $term insert $cur_row.$cur_col [
				    string range $s 0 [expr {$space_rem_on_line-1}]
				   ]

    $term tag $tag_action standout $cur_row.$cur_col $cur_row.[expr {$cur_col + $chars_to_write}]

    # discard first line already written
    incr chars_rem_to_write -$chars_to_write
    set s [string range $s $chars_to_write end]
    
    # update cur_col
    incr cur_col $chars_to_write
    # update cur_row
    if {$newline} {
	term_down
    }

    ##################
    # write full lines
    ##################
    while {$chars_rem_to_write >= $cols} {
	$term delete $cur_row.0 $cur_row.end
	$term insert $cur_row.0 [string range $s 0 [expr {$cols-1}]]
	$term tag $tag_action standout $cur_row.0 $cur_row.end

	# discard line from buffer
	set s [string range $s $cols end]
	incr chars_rem_to_write -$cols

	set cur_col 0
	term_down
    }

    #################
    # write last line
    #################

    if {$chars_rem_to_write} {
	$term delete $cur_row.0 $cur_row.$chars_rem_to_write
	$term insert $cur_row.0 $s
	$term tag $tag_action standout $cur_row.0 $cur_row.$chars_rem_to_write
	set cur_col $chars_rem_to_write
    }

    term_chars_changed
}

proc term_update_cursor {} {
    variable cur_row
    variable cur_col
    variable term

    $term mark set insert $cur_row.$cur_col

    term_cursor_changed
}

proc term_gotoxy {} {
    variable cur_row
    variable cur_col
    variable cols
    variable rows
    variable term

    if { $cur_row < 1 } {
	set cur_row 1
    } else {
	if { $cur_row > $rows } {
	    set cur_row $rows
	}
    }
    if { $cur_col < 0 } {
	set cur_col 0
    } else {
	if { $cur_col >= $cols } {
	    set cur_col [expr { $cols - 1 }]
	}
    }
    term_update_cursor
}

set flush 0
proc screen_flush {} {
    variable flush
    incr flush
    if {$flush == 24} {
	update idletasks
	set flush 0
    }
}

proc term_send { c } {
    variable term_pipe
    if { "$term_pipe" ne "" } {
	if { [eof $term_pipe] } {
	    force_close_term
	} else {
	    puts -nonewline $term_pipe $c
	}
    }
}

# process a newline
proc term_newline { } {
    variable cur_col
    variable cur_row
    variable term
    
    # go to start of line
    screen_flush
    set old_col $cur_col
    set cur_col 0
    # check for debug commands
    set line [$term get $cur_row.$cur_col $cur_row.end]
    if { "`" eq [string index $line 0] } {
	if { $old_col != 0 } {
	    ::DebugWin::RunCmd [string range $line 1 end]
	}
    }
    # now newline
    term_down
    term_update_cursor
}

# read a numeric argument out of a string
proc get_one_arg { str default_val } {
    set n $default_val
    if { "$str" ne "" } {
	scan "$str" %d n
    }
    return $n
}

# process an ANSI escape sequence
proc process_ansi_csi { args cmd } {
    variable cur_col
    variable cur_row
    variable cols
    variable rows
    variable term
    variable term_standout
    switch $cmd {
	"A" {
	    set n [get_one_arg $args 1]
	    set cur_row [expr { $cur_row - $n }]
	    term_gotoxy
	}
	"B" {
	    set n [get_one_arg $args 1]
	    incr cur_row $n
	    term_gotoxy
	}
	"C" {
	    set n [get_one_arg $args 1]
	    incr cur_col $n
	    term_gotoxy
	}
	"D" {
	    set n [get_one_arg $args 1]
	    set cur_col [expr { $cur_col - $n }]
	    term_gotoxy
	}
	"G" {
	    set cur_col [get_one_arg $args 1]
	    term_gotoxy
	}
	"H" {
	    if { "$args" eq "" } {
		set cur_col 0
		set cur_row 1
		term_gotoxy
	    } else {
		# arguments are 1-based, but our columns are 0 based
		scan "$args" "%d;%d" cur_row cur_col
		set cur_col [expr {$cur_col - 1}]
		term_gotoxy
	    }
	}
	"J" {
	    # FIXME: technically should parse argument
	    term_clear_to_eos
	}
	"K" {
	    # FIXME: technically should parse argument
	    term_clear_to_eol
	}
	"f" {
	    if { "$args" eq "" } {
		set cur_col 0
		set cur_row 1
		term_gotoxy
	    } else {
		# arguments are 1-based, but our columns are 0 based
		scan "$args" "%d;%d" cur_row cur_col
		set cur_col [expr {$cur_col - 1}]
		term_gotoxy
	    }
	}
	"m" {
	    # set graphic mode
	    # for now, only one tag (standout) understood
	    set n [get_one_arg $args 0]
	    if { $n == 7 } {
		set term_standout 1
	    } else {
		set term_standout 0
	    }
	}
	default {
	    # ignore
	}
    }
}

proc term_recv { str } {
    variable cur_col
    variable cur_row
    variable cur_state
    variable cur_save_str
    variable cur_saw_cr
    variable term
    global config

    set kind $config(internal_term)
    
    #puts "term_recv: ($str)"
    set len [string length $str]
    while { $len > 0 } {
	# grab all the printable characters (if any)
	set c ""
	if { "$cur_state" ne "normal" } {
	    set cur_saw_cr 0
	}
	switch "$cur_state" {
	    "normal" {
		regexp "^\[^\x01-\x1f]+" $str c
		if { $c eq "" } {
		    # no printable characters, just grab the first one
		    set c [string range $str 0 0]
		    set str [string range $str 1 end]
		    set len [string length $str]
		    if { $c ne "\r" } {
			if { $c ne "\n" } {
			    set cur_saw_cr 0
			}
		    }
		} else {
		    set cur_saw_cr 0
		    term_insert $c
		    term_update_cursor
		    set str [string range $str [string length $c] end]
		    set len [string length $str]
		    continue
		}
		# handle control characters here
		switch "$c" {
		    "\x1a" {
			# ctrl-z
			term_insert $c
		    }
		    "\r" {
			set cur_saw_cr 1
			if { "$kind" eq "ansi" } {
			    # (cr,) Go to beginning of line
			    screen_flush
			    set old_col $cur_col
			    set cur_col 0
			    term_update_cursor
			    # check for debug commands
			    set line [$term get $cur_row.$cur_col $cur_row.end]
			    if { "`" eq [string index $line 0] } {
				if { $old_col != 0 } {
				    ::DebugWin::RunCmd [string range $line 1 end]
				}
			    }
			} else {
			    term_newline
			}
		    }
		    "\n" {
			if { "$kind" eq "ansi" } {
			    # (ind,do) Move cursor down one line
			    term_down
			    term_update_cursor
			} else {
			    if { $cur_saw_cr } {
				set cur_saw_cr 0
			    } else {
				term_newline
			    }
			}
		    }
		    "\b" {
			# Backspace nondestructively
			incr cur_col -1
			term_update_cursor
		    }
		    "\a" {
			bell
		    }
		    "\t" {
			# Tab
			set cur_col [expr {( $cur_col + 8 ) & 0xFFF8}]
			term_update_cursor
		    }
		    "\x1b" {
			# ESC
			if { "$kind" eq "ansi" } {
			    set cur_state "ansi_gather_escape"
			    set cur_save_str ""
			}
		    }
		    "\x01" {
			if { "$kind" ne "ansi" } {
			    # PST escape: go to home
			    set cur_col 0
			    set cur_row 1
			    term_gotoxy
			}
		    }
		    "\x02" {
			if { "$kind" ne "ansi" } {
			    # PST escape: cursor XY
			    set cur_state "pst_getxy"
			}
		    }
		    "\x03" {
			if { "$kind" ne "ansi" } {
			    # PST escape: cursor left
			}
		    }
		    "\x04" {
			if { "$kind" ne "ansi" } {
			    # PST escape: cursor right
			    incr cur_col
			    term_update_cursor
			}
		    }
		    "\x05" {
			if { "$kind" ne "ansi" } {
			    # PST escape: cursor up
			    term_up
			    term_update_cursor
			}
		    }
		    "\x06" {
			if { "$kind" ne "ansi" } {
			    # PST escape: cursor down
			    term_down
			    term_update_cursor
			}
		    }
		    "\x0b" {
			if { "$kind" ne "ansi" } {
			    # PST escape: clear to end of line
			    term_clear_to_eol
			    term_update_cursor
			}
		    }
		    "\x0c" {
			if { "$kind" ne "ansi" } {
			    # PST escape: clear to end of screen
			    term_clear_to_eos
			    term_update_cursor
			}
		    }
		    "\x0e" {
			if { "$kind" ne "ansi" } {
			    # PST escape: get X position
			    set cur_state "pst_getx"
			}
		    }
		    "\x0f" {
			if { "$kind" ne "ansi" } {
			    # PST escape: get Y position
			    set cur_state "pst_gety"
			}
		    }
		    "\x00" -
		    "\x10" {
			if { "$kind" ne "ansi" } {
			    # PST escape: clear screen
			    # (clear,cl) Clear screen
			    term_clear
			    term_update_cursor
			}
		    }
		}
	    }
	    "ansi_gather_escape" {
		set c [string range $str 0 0]
		set str [string range $str 1 end]
		set len [string length $str]
		if { "$c" eq "\[" } {
		    # start of ANSI CSI sequence
		    set cur_state "ansi_gather_csi"
		} else {
		    #puts "got character ($c) (length $len) expected csi start"
		    set cur_state "normal"
		}
	    }
	    "ansi_gather_csi" {
		set c [string range $str 0 0]
		set str [string range $str 1 end]
		set len [string length $str]
		if { [string is alpha $c] } {
		    process_ansi_csi $cur_save_str $c
		    set cur_state "normal"
		} else {
		    set cur_save_str "$cur_save_str$c"
		}
	    }
	    "pst_getxy" {
		set c [string range $str 0 0]
		set str [string range $str 1 end]
		set len [string length $str]
		scan "$c" %c cur_col
		set cur_state "pst_gety"
	    }
	    "pst_getx" {
		set c [string range $str 0 0]
		set str [string range $str 1 end]
		set len [string length $str]
		scan "$c" %c cur_col
		term_update_cursor
		set cur_state "normal"
	    }
	    "pst_gety" {
		set c [string range $str 0 0]
		set str [string range $str 1 end]
		set len [string length $str]
		scan "$c" %c cur_row
		# make it one based
		incr cur_row
		term_update_cursor
		set cur_state "normal"
	    }
	    default {
		# just throw away the character and go back to normal mode
		set cur_state "normal"
	    }
	}
    }
}

proc Terminal_Data { } {
    variable term_pipe
    variable term_esc
    set c [read $term_pipe 1024]
    if { "$c" eq "" } {
	if { [eof $term_pipe] } {
	    close_term
	}
    } else {
	term_recv $c
    }
}

proc RunInWindow { cmd } {
    variable toplev
    variable term
    variable term_pipe
    if { "$term_pipe" != "" } {
	close $term_pipe
	set term_pipe ""
    }
    if { ![winfo exists $toplev] } {
	term_create
	term_init
	graphicsSet 0
    }
    if { ![winfo viewable $toplev] } {
	wm deiconify $toplev
    }
    #next line fails for some reason and creates a file called &1
    set cmd [concat $cmd [list "2>@1"]]
    #puts "Running: ($cmd)"
    raise $toplev
    term_clear
    set term_pipe [open |$cmd r+]
    fconfigure $term_pipe -blocking 0 -buffering none -translation binary
    fileevent $term_pipe readable { ::TkTerm::Terminal_Data }
}

proc close_term {} {
    variable term
    variable toplev
    set pipe $::TkTerm::term_pipe
    if { "$pipe" ne "" } {
	fileevent $pipe readable { }
	close $pipe
	set ::TkTerm::term_pipe ""
    }
    # destroy any debug windows associated with this instance
    ::DebugWin::DestroyWindows
    # and destroy the terminal itself
    #destroy $term
}

proc force_close_term {} {
    variable toplev
    variable term_pipe
    if { "$term_pipe" ne "" } {
	flush $term_pipe
	close $term_pipe
	set term_pipe ""
    }
    destroy $toplev
}

proc doTermBindings {} {
    variable term
    variable toplev
    
# New and incomplete!
#bind $term <Configure> {
#    scan [wm geometry .] "%dx%dx" rows cols
#    # stty rows $rows columns $cols < $spawn_out(slave,name)
#    
#    # when this is working, uncomment ...
#    # term_resize $rows $cols
#}

    bind $toplev <Destroy> { ::TkTerm::close_term }

    bind $toplev <Any-Enter> {
	focus %W
    }

    bind $term <Meta-KeyPress> {
	if {"%A" != ""} {
	    ::TkTerm::term_send "\033%A"
	}
    }

    bind $term <KeyPress> {
	#puts "got %K (%k) '%A')"
	::TkTerm::term_send %A
	break
    }

    bind $term <Control-space>	{::TkTerm::term_send "\000"}
    bind $term <Control-at>	{::TkTerm::term_send "\000"}
    bind $term <Control-z> {
	::TkTerm::force_close_term
	break
    }
    bind $term <Control-bracketright> {
	::TkTerm::force_close_term
	break
    }
    bind $toplev <Command-w> {
	::TkTerm::force_close_term
	break
    }

    bind $term <Up> {::TkTerm::term_send "\033\[A"}
    bind $term <Down> {::TkTerm::term_send "\033\[B"}
    bind $term <Right> {::TkTerm::term_send "\033\[C"}
    bind $term <Left> {::TkTerm::term_send "\033\[D"}
    bind $term <Control-Up> {::TkTerm::term_send "\033\[1;5A"}
    bind $term <Control-Down> {::TkTerm::term_send "\033\[1;5B"}
    bind $term <Control-Right> {::TkTerm::term_send "\033\[1;5C"}
    bind $term <Control-Left> {::TkTerm::term_send "\033\[1;5D"}
    bind $term <Home> {::TkTerm::term_send "\033\[H"}
    bind $term <End> {::TkTerm::term_send "\033\[F"}
    bind $term <Return> {::TkTerm::term_send "\x0d"}

    bind $term <Tab> {
	::TkTerm::term_send "\t"
	break
    }
    bind $term <Delete> {
	::TkTerm::term_send "\x7f"
	break
    }
    bind $term <Escape> {
	::TkTerm::term_send "\033"
	break
    }
    bind $term <BackSpace> {
	::TkTerm::term_send "\x08"
	break
    }
    bind $term <Insert> {
	::TkTerm::term_send "\033\[2~"
	break
    }
    bind $term <Prior> {::TkTerm::term_send "\033\[5~"}
    bind $term <Next> {::TkTerm::term_send "\033\[6~"}

    bind $term <F1> {::TkTerm::term_send "\033OP"}
    bind $term <F2> {::TkTerm::term_send "\033OQ"}
    bind $term <F3> {::TkTerm::term_send "\033OR"}
    bind $term <F4> {::TkTerm::term_send "\033OS"}
    bind $term <F5> {::TkTerm::term_send "\033OT"}
    bind $term <F6> {::TkTerm::term_send "\033OU"}
    bind $term <F7> {::TkTerm::term_send "\033OV"}
    bind $term <F8> {::TkTerm::term_send "\033OW"}
    bind $term <F9> {::TkTerm::term_send "\033OX"}
}

}
