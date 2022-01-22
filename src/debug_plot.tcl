#
# DEBUG PLOT implementation
# Copyright 2022 Total Spectrum Software, Inc.
# MIT Licensed
#

namespace eval DebugWin {

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
	    set angle [expr { $fullcircle * ( $y + $polar_offset($win) ) } ]
	    set newx [expr { $x * cos($angle) } ]
	    set newy [expr { $x * sin($angle) } ]
	    #puts "calcCoords len=$x angle=$y ($angle) result: ($newx, $newy)"
	} else {
	    set newx $x
	    set newy $y
	}
	set newx [expr { $origin_x($win) + $newx } ]
	set newy [expr { $origin_y($win) - $newy } ]
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
		    set origin_y($w) [expr { [$w cget -height] - $newy } ]
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
		}
		"circle" {
		    set diameter [fetchnum args 2]
		    set linesize [fetchnum args 0]
		    set opacity [fetchnum args 255]
		    set coords [calcCoords $w $cur_x($w) $cur_y($w)]
		    set upperx [expr { [lindex $coords 0] - ($diameter / 2) } ]
		    set uppery [expr { [lindex $coords 1] - ($diameter / 2) } ]
		    set lowerx [expr { $upperx + $diameter } ]
		    set lowery [expr { $uppery + $diameter } ]
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
		    set upperx [expr { [lindex $coords 0] - ($width / 2) } ]
		    set uppery [expr { [lindex $coords 1] - ($height / 2) } ]
		    set lowerx [expr { $upperx + $width } ]
		    set lowery [expr { $uppery + $height } ]
		    if { $linesize == 0 } {
			$w create oval $upperx $uppery $lowerx $lowery -fill $cur_color($w)
		    } else {
			$w create oval $upperx $uppery $lowerx $lowery -outline $cur_color($w) -width $linesize
		    }
		}
		"obox" -
		"box" {
		    set width [fetchnum args 2]
		    set height [fetchnum args 2]
		    set linesize [fetchnum args 0]
		    set opacity [fetchnum args 255]
		    set coords [calcCoords $w $cur_x($w) $cur_y($w)]
		    set upperx [expr { [lindex $coords 0] - ($width / 2) } ]
		    set uppery [expr { [lindex $coords 1] - ($height / 2) } ]
		    set lowerx [expr { $upperx + $width } ]
		    set lowery [expr { $uppery + $height } ]
		    if { $linesize == 0 } {
			$w create rectangle $upperx $uppery $lowerx $lowery -fill $cur_color($w)
		    } else {
			$w create rectangle $upperx $uppery $lowerx $lowery -outline $cur_color($w) -width $linesize
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
	variable polar_circle
	
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
	set origin_y($w) $size_h
	set cur_color($w) "#ffffff"
	set text_color($w) "#000"
	set polar_circle($w) 0
	set delayed_updates($top) $delayed
	
	return $top
    }
    
}
