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

	#puts " ===> r = ($r) list = $list"
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
	
	# strip out underscores
	set r [string map {_ ""} $r]

	if { $ch eq "$" } {
	    # hex number
	    set r [scan [string range $r 1 end] %x]
	} elseif { $ch eq "%" } {
	    # binary number
	    set r [scan [string range $r 1 end] %b]
	}

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
		set pattern "F00"
	    }
	    "green" {
		set pattern "0F0"
	    }
	    "blue" {
		set pattern "00F"
	    }
	    "yellow" {
		set pattern "FF0"
	    }
	    "cyan" {
		set pattern "0FF"
	    }
	    "magenta" {
		set pattern "F0F"
	    }
	    "grey" {
		set pattern "FFF"
	    }
	    "orange" {
		set pattern "F70"
	    }
	    default {
		# assume a number
		set baseColor [stringToNum $baseColor]
		# convert rgb24 to hex
		set baseColor [format "\#%06x" $baseColor]
		return $baseColor
	    }
	}
	set scale [fetchnum list "8"]

	# FIXME: we should be scaling the number by "scale" here
	return "#$pattern"
    }

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
	set args [lindex $args 0]
	set len [llength $args]
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
	set fontName "Courier"
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
	    set underline "true"
	} else {
	    set underline "false"
	}
	set orient [expr ($textstyle >> 4) & 0xf]

	set font [font create -family $fontName -size $textsize -weight $weight -slant $slant -underline $underline]
	return [list $font $style]
    }
    # convert x,y to screen space
    # returns a list of elements
    proc calcCoords { win x y } {
	variable polar_circle
	variable polar_offset
	variable origin_x
	variable origin_y

	set fullcircle $polar_circle($win)
	if { $fullcircle } {
	    # (x, y) is (length,angle)
	    set angle [expr $fullcircle * ( $y + $polar_offset($win) ) ]
	    set newx [expr $x * cos($angle)]
	    set newy [expr $x * sin($angle)]
	    #puts "calcCoords len=$x angle=$y ($angle) result: ($newx, $newy)"
	} else {
	    set newx $x
	    set newy $y
	}
	set newx [expr $origin_x($win) + $newx ]
	set newy [expr $origin_y($win) - $newy ]
	return [list $newx $newy]
    }
    
    # Plot command functions
    proc PlotCmd { topname args } {
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
		"black" -
		"white" -
		"red" -
		"green" -
		"blue" -
		"cyan" -
		"magneta" -
		"yellow" -
		"orange" -
		"grey" {
		    set cur_color($w) [fetchcolor args $cmd]
		    if { [lindex $args 0] eq "text" } {
			set text_color($w) $cur_color($w)
		    }
		}
		"set" {
		    set x [fetcharg args]
		    set y [fetcharg args]
		    set cur_x($w) $x
		    set cur_y($w) $y
		}
		"origin" {
		    set newx [fetchnum args cur_x($w)]
		    set newy [fetchnum args cur_y($w)]
		    set origin_x($w) $newx
		    set origin_y($w) [expr [$w cget -height] - $newy]
		}
		"polar" {
		    set twopi [fetchnum args 0x10000000]
		    set offset [fetchnum args 0]
		    setPolarScaling $w $twopi $offset
		}
		"text" {
		    set size [fetchnum args 10]
		    set style [fetchnum args 1]
		    set angle [fetchnum args 0]
		    set msg [getstring [fetcharg args]]
		    set coords [calcCoords $w $cur_x($w) $cur_y($w)]
		    set finfo [getFontStyle $size $style]
		    $w create text [lindex $coords 0] [lindex $coords 1] -font [lindex $finfo 0] -anchor [lindex $finfo 1] -text $msg -fill $text_color($w)
		    font delete [lindex $finfo 0]
		}
		"circle" {
		    set diameter [fetchnum args 2]
		    set linesize [fetchnum args 0]
		    set opacity [fetchnum args 255]
		    set coords [calcCoords $w $cur_x($w) $cur_y($w)]
		    set upperx [expr [lindex $coords 0] - ($diameter / 2)]
		    set uppery [expr [lindex $coords 1] - ($diameter / 2)]
		    set lowerx [expr $upperx + $diameter]
		    set lowery [expr $uppery + $diameter]
		    if { $linesize == 0 } {
			$w create oval $upperx $uppery $lowerx $lowery -fill $cur_color($w)
		    } else {
			$w create oval $upperx $uppery $lowerx $lowery -outline $cur_color($w) -width $linesize
		    }
		}
		"line" {
		    set newx [fetchnum args $cur_x($w)]
		    set newy [fetchnum args $cur_y($w)]
		    set linesize [fetchnum args 1]
		    set opacity [fetchnum args 255]
		    set coords [calcCoords $w $cur_x($w) $cur_y($w)]
		    set newcoords [calcCoords $w $newx $newy]
		    $w create line [concat $coords $newcoords] -fill $cur_color($w) -width $linesize
		}
		"oval" {
		    set width [fetchnum args 2]
		    set height [fetchnum args 2]
		    set linesize [fetchnum args 0]
		    set opacity [fetchnum args 255]
		    set coords [calcCoords $w $cur_x($w) $cur_y($w)]
		    set upperx [expr [lindex $coords 0] - ($width / 2)]
		    set uppery [expr [lindex $coords 1] - ($height / 2)]
		    set lowerx [expr $upperx + $width]
		    set lowery [expr $uppery + $height]
		    if { $linesize == 0 } {
			$w create oval $upperx $uppery $lowerx $lowery -fill $cur_color($w)
		    } else {
			$w create oval $upperx $uppery $lowerx $lowery -outline $cur_color($w) -width $linesize
		    }
		}
		default {
		    puts "Unknown PLOT command $cmd"
		}
	    }
	}
    }

    proc CreatePlotWindow {name args} {
	variable cur_color
	variable text_color
	variable cur_x
	variable cur_y
	variable origin_x
	variable origin_y
	variable delayed_updates
	
	set top .toplev$name

	if { [winfo exists $top] } {
	    return
	}
	set args [lindex $args 0]
	set len [llength $args]
	#puts "CreatePlotWindow: len=$len args=$args"

	set title "$name - PLOT"
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
		"backcolor" {
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
	set wfont [font create -family Courier -size $textsize]
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
	set origin_y($w) 0
	set cur_color($w) "#ffffff"
	set text_color($w) "#000"
	set delayed_updates($top) $delayed
	
	return $top
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
		    QueueCmds $debugcmd($cmd) $w "$args"
		} else {
		    eval [$debugcmd($cmd) $w "$args"]
		}
	    }
	} else {
	    set len [llength $args]
	    set name [lindex $args 1]
	    set args [lrange $args 2 end]
	    
	    set len [llength $args]
	    
	    switch $cmd {
		"term" {
		    set tmp [CreateTermWindow $name "$args"]
		    if { $tmp ne "" } {
			set debugwin($name) $tmp
			set debugcmd($name) "::DebugWin::TermCmd"
			set cmd_queue($name) [list]
		    }
		}
		"plot" {
		    set tmp [CreatePlotWindow $name "$args"]
		    if { $tmp ne "" } {
			set debugwin($name) $tmp
			set debugcmd($name) "::DebugWin::PlotCmd"
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
