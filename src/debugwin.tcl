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
	set result {}
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
	return $result
    }

    proc TextCmd { name args } {
	puts "Text command for $name is ( $args )"
    }

    proc CreateTextWindow {name args} {
	return .toplev.$name
    }
    
    proc RunCmd { c } {
	variable debugwin
	variable debugcmd
	puts "RunCmd: $c"
	set args [normalize_cmds [csv_split $c]]
	set cmd [lindex $args 0]
	if { [info exists debugwin($cmd)] } {
	    set args [lrange $args 1 end]
	    eval [$debugcmd($cmd) $debugwin($cmd) $args]
	} else {
	    set name [lindex $args 1]
	    set args [lrange $args 2 end]
	    switch $cmd {
		"term" {
		    set debugwin($name) [CreateTextWindow $name $args]
		    set debugcmd($name) "::DebugWin::TextCmd"
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
		event generate $debugwin($i) <<Delete>>
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
