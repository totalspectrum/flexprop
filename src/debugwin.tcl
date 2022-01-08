#
# DEBUG graphics commands for FlexProp
# Written by Eric R. Smith
# Copyright 2022 Total Spectrum Software Inc.
# MIT Licensed
#
namespace eval DebugWin {
    namespace export RunCmd
    namespace export DestroyWindows

    array set debugwin {}
    array set debugcmd {}
    
    proc normalize_cmds {list} {
	set result [list]
	foreach i $list {
	    set c [string index $i 0]
	    switch $c {
		"\'"  {
		    # do nothing, literal string
		}
		"$" {
		    set i [scan [string range $i 1 end] %x]
		}
		"%" {
		    set i [scan [string range $i 1 end] %b]
		}
		default {
		    set i [string tolower $i]
		}
	    }
	    lappend result $i
	}
	set len [llength $result]
#	puts "normalize_commands: len=$len result=$result"
	return $result
    }

    proc fetcharg {listName} {
	upvar 1 $listName list
	#puts "fetcharg: list = $list"
	set r [lindex $list 0]
	set list [lrange $list 1 end]
	#puts " ===> r = ($r) list = $list"
	return $r
    }
    
    proc TermCmd { name args } {
	set args [lindex $args 0]
	set w $name.txt
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
		    default {
			set txt $cmd
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
	set w .toplev$name

	set args [lindex $args 0]
	#set len [llength $args]
	#puts "CreateTermWindow: len=$len args=$args"

	set title "$name - TERM"
	set pos_x 0
	set pos_y 0
	set size_w 40
	set size_h 10
	set textsize 8
	set fgcolor white
	set bgcolor black

	while { [llength $args] > 0 } {
	    set cmd [fetcharg args]
#	    puts "   CreateTermWindow: cmd=($cmd) args=$args"
	    switch $cmd {
		"size" {
		    set size_w [fetcharg args]
		    set size_h [fetcharg args]
		}
		"textsize" {
		    set textsize [fetcharg args]
		}
		"title" {
		    set title [getstring [fetcharg args]]
		}
		"" {
		}
		default {
		    puts "Unknown TERM option $cmd"
		}
	    }
	}
	set wfont [font create -family Courier -size $textsize]
	puts "text $w.txt -bg $bgcolor -fg $fgcolor -font $wfont -height $size_h -width $size_w"
	toplevel $w
	text $w.txt -bg $bgcolor -fg $fgcolor -font $wfont -height $size_h -width $size_w -wrap none
	grid columnconfigure $w 0 -weight 1
	grid rowconfigure $w 0 -weight 1
	grid $w.txt -sticky nsew

	wm title $w $title
	
	return $w
    }
    
    proc RunCmd { c } {
	variable debugwin
	variable debugcmd
#	puts "RunCmd: $c"
	set args [normalize_cmds [csv_split $c]]
	set cmd [lindex $args 0]
	if { [info exists debugwin($cmd)] } {
	    set args [lrange $args 1 end]
	    eval [$debugcmd($cmd) $debugwin($cmd) "$args"]
	} else {
	    set len [llength $args]
	    set name [lindex $args 1]
	    set args [lrange $args 2 end]
	    
	    set len [llength $args]
	    
	    switch $cmd {
		"term" {
		    set tmp [CreateTermWindow $name "$args"]
		    set debugwin($name) $tmp
		    set debugcmd($name) "::DebugWin::TermCmd"
		    puts "set debugwin($name) to $debugwin($name)"
		}
		default {
		    puts "ERROR: unknown command $cmd"
		}
	    }
	}
    }

    proc DestroyWindows { } {
	variable debugwin
	variable debugcmd
	foreach i [array names debugwin] {
	    if {$i != ""} {
		if { [winfo exists $debugwin($i)] } {
		    event generate $debugwin($i) <<Delete>>
		}
	    }
	}
	array unset debugwin *
	array unset debugcmd *
    }

    # csv_split function from https://wiki.tcl-lang.org/page/csv
    # modified by ERS to split on spaces and use single quotes
proc csv_split {line} {
    # Process each input character.
    set result [list]
    set beg 0
    while {$beg < [string length $line]} {
       # consume multiple spaces
       while {[string index $line $beg] eq " "} {
          incr beg
       }
       if {[string index $line $beg] eq "\'"} {
          incr beg
          set quote false
	  set word "\'"
          foreach char [concat [split [string range $line $beg end] {}] {{}}] {
             # Search forward for the closing quote, one character at a time.
             incr beg
             if {$quote} {
                if {$char in {\  {}}} {
                   # Quote followed by comma or end-of-line indicates the end of
                   # the word.
                   break
                } elseif {$char eq "\'"} {
                   # Pair of quotes is valid.
                   append word $char
                } else {
                   # No other characters can legally follow quote.  I think.
                   error "extra characters after close-quote"
                }
                set quote false
             } elseif {$char eq {}} {
                # End-of-line inside quotes indicates embedded newline.
                error "embedded newlines not supported"
             } elseif {$char eq "\'"} {
                # Treat the next character specially.
                set quote true
             } else {
                # All other characters pass through directly.
                append word $char
             }
          }
	  append word "\'"
          lappend result $word
       } else {
          # Use all characters up to the space or line ending.
          regexp -start $beg {.*?(?=\ |$)} $line word
          lappend result $word
          set beg [expr {$beg + [string length $word] + 1}]
       }
    }

    # If the line ends in a comma, add a blank word to the result.
    if {[string index $line end] eq " "} {
       lappend result {}
    }

    # Done.  Return the result list.
    return $result
}

}
