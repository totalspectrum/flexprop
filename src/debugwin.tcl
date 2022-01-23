#
# DEBUG graphics commands for FlexProp
# Written by Eric R. Smith
# Copyright 2022 Total Spectrum Software Inc.
# MIT Licensed
#

# utility function to get the font family from
# a font name or specifier

proc getFontFamily { spec } {
    if { "-family" eq [lindex $spec 0] } {
	return [lindex $spec 1]
    }
    set spec [font actual $spec]
    if { "-family" eq [lindex $spec 0] } {
	return [lindex $spec 1]
    }
    
    if { [catch [font configure $spec -family]] } {
	# perhaps the string has an explicit -family
	return $spec
    }
    return [font configure $spec -family]
}

proc getDebugFontFamily {} {
    global config
    return [getFontFamily $config(term_font)]
}

source $ROOTDIR/src/debug_term.tcl
source $ROOTDIR/src/debug_plot.tcl

namespace eval DebugWin {
    namespace export RunCmd
    namespace export DestroyWindows

    array set debugwin {}
    array set debugcmd {}
    array set delayed_updates {}
    array set cmd_queue {}
    
    proc normalize_cmds {list} {
	set result [list]
	foreach i $list {
	    set c [string index $i 0]
	    switch $c {
		"\'"  {
		    # do nothing, literal string
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

    # retrieve next argument from a list
    proc fetcharg {listName} {
	upvar 1 $listName list
	#puts "fetcharg: list = $list"
	set r [lindex $list 0]
	set list [lrange $list 1 end]
	#puts " ===> r = ($r) list = $list"
	return $r
    }

    # convert string to number
    proc stringToNum { r } {
	# strip out underscores
	set ch [string index $r 0]
	set r [string map {_ ""} $r]

	if { $ch eq "$" } {
	    # hex number
	    set r [scan [string range $r 1 end] %x]
	} elseif { $ch eq "%" } {
	    # binary number
	    set r [scan [string range $r 1 end] %b]
	}

	return $r
    }

    proc getstring { msg } {
	if { [string index $msg 0] eq "'" } {
	    set msg [string range $msg 1 end-1]
	}
	return $msg
    }
    
    # retrieve an optional number from a list
    # if the next thing is not a number, return the default value
    proc fetchnum {listName defaultValue} {
	upvar 1 $listName list
	#puts "fetcharg: list = $list"
	set r [lindex $list 0]
	set ch [string index $r 0]
	if { [string first $ch "-0123456789$%"] < 0 } {
	    # this is not a number
	    return $defaultValue
	}

	# consume the argument
	set list [lrange $list 1 end]

	# convert to a number
	set r [stringToNum $r]
	
	#puts " ===> r = ($r) list = $list"
	return $r
    }
    
    # retrieve a color from a list
    # baseColor is the "base" color name, if known; if it is not known,
    # it is fetched from the list
    # after it could be an optional scaling value 0..15 (if it is a name like "black/white"
    # otherwise it's a 32 bit RGB value
    
    proc fetchcolor {listName baseColor} {
	upvar 1 $listName list

	if { "$baseColor" eq "" } {
	    set baseColor [lindex $list 0]
	    set list [lrange $list 1 end]
	}
	#puts "fetcharg: list = $list"
	switch -- "$baseColor" {
	    "black" {
		return "#000000"
	    }
	    "white" {
		return "#FFFFFF"
	    }
	    "red" {
		set pattern "FF0000"
	    }
	    "green" {
		set pattern "00FF00"
	    }
	    "blue" {
		set pattern "0000FF"
	    }
	    "yellow" {
		set pattern "FFFF00"
	    }
	    "cyan" {
		set pattern "00FFFF"
	    }
	    "magenta" {
		set pattern "FF00FF"
	    }
	    "grey" {
		set pattern "777777"
	    }
	    "orange" {
		set pattern "FF7700"
	    }
	    default {
		# assume a number
		set baseColor [stringToNum $baseColor]
		# convert rgb24 to hex
		set baseColor [format "\#%06x" $baseColor]
		return $baseColor
	    }
	}
	set scale [fetchnum list "4"]
	set halfscale $scale
	if { $halfscale > 9 } {
	    set halfscale [string map {10 A 11 B 12 C 13 D 14 E 15 F} $scale]
	}
	set scale [expr { $scale * 2 }]
	# replace all instances of "7" in pattern with "scale/2"
	#set halfscale [expr $scale / 2]
	set pattern [string map [list 7 $halfscale] $pattern]
	# replace F with "scale" (hex version)
	if { $scale > 9 } {
	    set scale [string map {10 A 11 B 12 C 13 D 14 E 15 F} $scale]
	}
	set pattern [string map [list F $scale] $pattern]
	
	# FIXME: we should be scaling the number by "scale" here
	return "#$pattern"
    }

    array set cur_color {}
    array set text_color {}
    array set cur_x {}
    array set cur_y {}
    array set origin_x {}
    array set origin_y {}
    array set polar_circle {}
    array set polar_offset {}
    
    #
    # set up for polar scaling
    # when converting from "degrees" to radians, we do
    #    rad = deg * pi / 180
    # for generalized degrees use an arbitrary full circle value instead of 360
    # so the equation becomes
    #    rad = (deg + polar_offset) * pi / (polar_circle/2)
    proc setPolarScaling { win fullcircle offset } {
	variable polar_circle
	variable polar_offset
	
	set pi 3.1415926536
	set polar_offset($win) $offset
	set polar_circle($win) [expr $pi * 2.0 / $fullcircle]
    }

    #
    # parse the textsize and textstyle, and get a suitable font for it
    # returns a list of two items: the font, and a word suitable for use
    # with -anchor to describe how it's relative to the starting point
    #  vertical orientation + horizontal orientation both combine
    #  options are things like: center (default), nw (upper left), se (lower right)
    #
    # input textstyle is %YYXXUIWW
    #   YYXX is orientation, U is underline, I is italic, WW is weight
    
    proc getFontStyle { textsize textstyle } {
	global config
	set fontName [::getFontFamily $config(term_font)]
	set style "center"

	if { [expr ($textstyle & 0x3) > 2] } {
	    set weight "bold"
	} else {
	    set weight "normal"
	}
	if { [expr ($textstyle >> 2) & 0x1] } {
	    set slant "italic"
	} else {
	    set slant "roman"
	}

	if { [expr ($textstyle >> 3) & 0x1] } {
	    set underline [list "underline"]
	} else {
	    set underline [list]
	}
	set orient [expr ($textstyle >> 4) & 0xf]

	set font [list $fontName $textsize $weight $slant ]
	set font [concat $font $underline]
	return [list $font $style]
    }
    proc QueueCmds { cmd win args } {
	variable cmd_queue
	set args [lindex $args 0]
	foreach i $args {
	    if { $i eq "update" } {
		eval [$cmd $win "$cmd_queue($win)"]
		set cmd_queue($win) [list]
	    } else {
		lappend cmd_queue($win) $i
	    }
	}
    }
    
    proc RunCmd { c } {
	variable debugwin
	variable debugcmd
	variable cmd_queue
	variable delayed_updates
	
#	puts "RunCmd: $c"
	set args [normalize_cmds [csv_split $c]]
	set cmd [lindex $args 0]
	if { [info exists debugwin($cmd)] } {
	    # the first N items will be window names, collect them
	    set windowlist [list]
	    while { [info exists debugwin($cmd)] } {
		lappend windowlist $cmd
		set args [lrange $args 1 end]
		set cmd [lindex $args 0]
	    }
	    # now for each window name, queue the commands up to
	    # be executed
	    foreach cmd $windowlist {
		set w $debugwin($cmd)
		#puts "send to $cmd - $w"
		if { $delayed_updates($w) } {
		    QueueCmds $debugcmd($cmd) $w $args
		} else {
		    eval [$debugcmd($cmd) $w $args]
		}
	    }
	} else {
	    set len [llength $args]
	    set name [lindex $args 1]
	    set args [lrange $args 2 end]
	    
	    set len [llength $args]
	    
	    switch $cmd {
		"term" {
		    set tmp [CreateTermWindow $name $args]
		    if { $tmp ne "" } {
			set debugwin($name) $tmp
			set debugcmd($name) "::DebugWin::TermCmd"
			set cmd_queue($name) [list]
		    }
		}
		"plot" {
		    set tmp [CreatePlotWindow $name $args]
		    if { $tmp ne "" } {
			set debugwin($name) $tmp
			set debugcmd($name) "::DebugWin::PlotCmd"
			set cmd_queue($name) [list]
		    }
		}
		"scope" {
		    set tmp [CreatePlotWindow $name $args]
		    if { $tmp ne "" } {
			set debugwin($name) $tmp
			set debugcmd($name) "::DebugWin::ScopeCmd"
			set cmd_queue($name) [list]
		    }
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
		set w $debugwin($i)
		if { [winfo exists $w] } {
		    destroy $w
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
		   #error "extra characters after close-quote"
		   return $result 
                }
                set quote false
             } elseif {$char eq {}} {
                # End-of-line inside quotes indicates embedded newline.
                # error "embedded newlines not supported"
                return $result 
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
          set beg [expr { $beg + [string length $word] + 1 } ]
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
