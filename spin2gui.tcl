#!/usr/bin/wish

package require Tk
package require autoscroll
#package require ctext

source ctext/ctext.tcl

# global variables
set CONFIG_FILE "~/.spin2gui.config"

set COMPILE "./bin/fastspin"
set makeBinary 1
set codemem hub
set datamem hub
set ROOTDIR [file dirname [file normalize [info script]]]

# provide some default settings
proc setShadowP1Defaults {} {
    global shadow

    set shadow(compilecmd) "%D/bin/fastspin -L %L %S"
    set shadow(runcmd) "xterm -fs 14 -e %D/bin/propeller-load %B -r -t"
}
proc setShadowP2Defaults {} {
    global shadow

    set shadow(compilecmd) "%D/bin/fastspin -2 -L %L %S"
    set shadow(runcmd) "xterm -fs 14 -e %D/bin/loadp2 %B -t"
}
proc copyShadowToConfig {} {
    global config
    global shadow
    set config(compilecmd) $shadow(compilecmd)
    set config(runcmd) $shadow(runcmd)
}

set config(library) "./lib"
set config(spinext) ".spin"
set config(lastdir) "."
    
setShadowP2Defaults
copyShadowToConfig
    
# configuration settings
proc config_open {} {
    global config
    global CONFIG_FILE
    
    if {[file exists $CONFIG_FILE]} {
	set fp [open $CONFIG_FILE r]
    } else {
	return 0
    }
    # read config values
    while {![eof $fp]} {
	set data [gets $fp]
	switch [lindex $data 0] {
	    \# {
		# ignore the comment
	    }
	    geometry {
		# restore last position on screen
		wm geometry [winfo toplevel .] [lindex $data 1]
	    }
	    font {
		# restore font
		.orig.txt configure -font [lindex $data 1]
	    }
	    default {
		set config([lindex $data 0]) [lindex $data 1]
	    }
	}
    }
    close $fp
    return 1
}

proc config_save {} {
    global config
    global CONFIG_FILE
    set fp [open $CONFIG_FILE w]
    puts $fp "# spin2gui config info"
    puts $fp "geometry\t[winfo geometry [winfo toplevel .]]"
    puts $fp "font\t\{[.orig.txt cget -font]\}"
    foreach i [array names config] {
	if {$i != ""} {
	    puts $fp "$i\t\{$config($i)\}"
	}
    }
    close $fp
}

#
# read a file and return its text
# does UCS-16 to UTF-8 conversion
#
proc uread {name} {
    set encoding ""
    set len [file size $name]
    set f [open $name r]
    gets $f line
    if {[regexp \xFE\xFF $line] || [regexp \xFF\xFE $line]} {
	fconfigure $f -encoding unicode
	set encoding unicode
    }
    seek $f 0 start ;# rewind
    set text [read $f $len]
#    puts "read $len bytes"
    close $f
    if {$encoding=="unicode"} {
	regsub -all "\uFEFF|\uFFFE" $text "" text
    }
#    set len [string len $text]
#    puts "len is $len"
    return $text
}

#
# reset anything associated with the output file and configuration
#
proc resetOutputVars { } {
    global SPINFILE
    global BINFILE
    
    set BINFILE ""
}

# exit the program
proc exitProgram { } {
    checkChanges
    config_save
    exit
}

# load a file into a text (or ctext) window
proc loadFileToWindow { fname win } {
    set file_data [uread $fname]
    $win delete 1.0 end
    $win insert end $file_data
    $win edit modified false
}

# save contents of a window to a file
proc saveFileFromWindow { fname win } {
    set fp [open $fname w]
    set file_data [$win get 1.0 end]

    # HACK: the text widget inserts an extra \n at end of file
    set file_data [string trimright $file_data]
    
    set len [string len $file_data]
    #puts " writing $len bytes"

    # we trimmed away all the \n above, so put one back here
    # by leaving off the -nonewline to puts
    puts $fp $file_data
    close $fp
    $win edit modified false
}

#
# tag text containing "error:" in a text widget w
#
proc tagerrors { w } {
    $w tag remove errtxt 0.0 end
    # set current position at beginning of file
    set cur 1.0
    # search through looking for error:
    while 1 {
	set cur [$w search -count length "error:" $cur end]
	if {$cur eq ""} {break}
	$w tag add errtxt $cur "$cur lineend"
	set cur [$w index "$cur + $length char"]
    }
    $w tag configure errtxt -foreground red
}

set SpinTypes {
    {{Spin2 files}   {.spin2 .spin} }
    {{Spin files}   {.spin} }
    {{All files}    *}
}

set BinTypes {
    {{Binary files}   {.binary .bin} }
    {{All files}    *}
}

proc checkChanges {} {
    global SPINFILE
    if {[.orig.txt edit modified]==1} {
	set answer [tk_messageBox -icon question -type yesno -message "Save file $SPINFILE?" -default yes]
	if { $answer eq yes } {
	    saveSpinFile
	}
    }
}

proc getLibrary {} {
    global config
    set config(library) [tk_chooseDirectory -title "Choose Spin library directory" -initialdir $config(library) ]
}

proc newSpinFile {} {
    global SPINFILE
    set SPINFILE ""
    set BINFILE ""
    checkChanges
    wm title . "New File"
    .orig.txt delete 1.0 end
    .bot.txt delete 1.0 end
}

proc loadSpinFile {} {
    global SPINFILE
    global BINFILE
    global SpinTypes
    global config
    
    checkChanges
    set filename [tk_getOpenFile -filetypes $SpinTypes -defaultextension $config(spinext) -initialdir $config(lastdir) ]
    if { [string length $filename] == 0 } {
	return
    }
    set config(lastdir) [file dirname $filename]
    set config(spinext) [file extension $filename]
    loadFileToWindow $filename .orig.txt
    .orig.txt highlight 1.0 end
    ctext::comments .orig.txt
    ctext::linemapUpdate .orig.txt
    
    set SPINFILE $filename
    set BINFILE ""
    wm title . $SPINFILE
}

proc saveSpinFile {} {
    global SPINFILE
    global BINFILE
    global SpinTypes
    global config
    
    if { [string length $SPINFILE] == 0 } {
	set filename [tk_getSaveFile -initialfile $SPINFILE -filetypes $SpinTypes -defaultextension $config(spinext) ]
	if { [string length $filename] == 0 } {
	    return
	}
	set config(lastdir) [file dirname $filename]
	set config(spinext) [file extension $filename]
	set SPINFILE $filename
	set BINFILE ""
    }
    
    saveFileFromWindow $SPINFILE .orig.txt
    wm title . $SPINFILE
}

proc saveSpinAs {} {
    global SPINFILE
    global BINFILE
    global SpinTypes
    global config
    set filename [tk_getSaveFile -filetypes $SpinTypes -defaultextension $config(spinext) -initialdir $config(lastdir) ]
    if { [string length $filename] == 0 } {
	return
    }
    set config(lastdir) [file dirname $filename]
    set config(spinext) [file extension $filename]
    set SPINFILE $filename
    set BINFILE ""
    wm title . $SPINFILE
    saveSpinFile
}

set aboutMsg {
GUI tool for .spin2
Version 1.0    
Copyright 2018 Total Spectrum Software Inc.
------
There is no warranty and no guarantee that
output will be correct.    
}

proc doAbout {} {
    global aboutMsg
    tk_messageBox -icon info -type ok -message "Spin 2 GUI" -detail $aboutMsg
}

proc doHelp {} {
    if {[winfo exists .help]} {
	raise .help
	return
    }
    toplevel .help
    frame .help.f
    text .help.f.txt -wrap none -yscroll { .help.f.v set } -xscroll { .help.f.h set }
    scrollbar .help.f.v -orient vertical -command { .help.f.txt yview }
    scrollbar .help.f.h -orient horizontal -command { .help.f.txt xview }

    grid columnconfigure .help {0 1} -weight 1
    grid rowconfigure .help 0 -weight 1
    grid .help.f -sticky nsew
    
    grid .help.f.txt .help.f.v -sticky nsew
    grid .help.f.h -sticky nsew
    grid rowconfigure .help.f .help.f.txt -weight 1
    grid columnconfigure .help.f .help.f.txt -weight 1

    loadFileToWindow README.txt .help.f.txt
    wm title .help "Spin Converter help"
}

#
# set up syntax highlighting for a given ctext widget
proc setHighlightingSpin {w} {
    set color(comments) grey
    set color(keywords) DarkBlue
    set color(brackets) purple
    set color(numbers) DeepPink
    set color(operators) green
    set color(strings)  red
    set color(varnames) DarkGreen
    set color(preprocessor) cyan
    set keywordsbase [list Con Obj Dat Var Pub Pri Quit Exit Repeat While Until If Then Else Return Abort Long Word Byte]
    foreach i $keywordsbase {
	lappend keywordsupper [string toupper $i]
    }
    foreach i $keywordsbase {
	lappend keywordslower [string tolower $i]
    }
    set keywords [concat $keywordsbase $keywordsupper $keywordslower]

    ctext::addHighlightClass $w keywords $color(keywords) $keywords

    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) \$ 
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) \%
#    ctext::addHighlightClassForRegexp $w numbers $color(numbers) {[0-9][0-9_]*}

    ctext::addHighlightClassForSpecialChars $w brackets $color(brackets) {[]()}
    ctext::addHighlightClassForSpecialChars $w operators $color(operators) {+-=><!@~\*/&:|}

    ctext::addHighlightClassForRegexp $w strings $color(strings) {"(\\"||^"])*"}
    ctext::addHighlightClassForRegexp $w preprocessor $color(preprocessor) {^\#[a-z]+}

    ctext::addHighlightClassForRegexp $w comments $color(comments) {\'[^\n\r]*}
#    ctext::enableComments $w
    $w tag configure _cComment -foreground $color(comments)
    $w tag raise _cComment
}

menu .mbar
. configure -menu .mbar
menu .mbar.file -tearoff 0
menu .mbar.edit -tearoff 0
menu .mbar.run -tearoff 0
menu .mbar.help -tearoff 0

.mbar add cascade -menu .mbar.file -label File
.mbar.file add command -label "New Spin File" -accelerator "^N" -command { newSpinFile }
.mbar.file add command -label "Open Spin..." -accelerator "^O" -command { loadSpinFile }
.mbar.file add command -label "Save Spin" -accelerator "^S" -command { saveSpinFile }
.mbar.file add command -label "Save Spin As..." -command { saveSpinAs }
.mbar.file add separator
.mbar.file add command -label "Library directory..." -command { getLibrary }
.mbar.file add separator
.mbar.file add command -label Exit -accelerator "^Q" -command { exitProgram }

.mbar add cascade -menu .mbar.edit -label Edit
.mbar.edit add command -label "Cut" -accelerator "^X" -command {event generate [focus] <<Cut>>}
.mbar.edit add command -label "Copy" -accelerator "^C" -command {event generate [focus] <<Copy>>}
.mbar.edit add command -label "Paste" -accelerator "^V" -command {event generate [focus] <<Paste>>}
.mbar.edit add separator
.mbar.edit add command -label "Undo" -accelerator "^Z" -command {event generate [focus] <<Undo>>}
.mbar.edit add command -label "Redo" -accelerator "^Y" -command {event generate [focus] <<Redo>>}
.mbar.edit add separator
.mbar.edit add command -label "Select Font..." -command { tk fontchooser show }
    
.mbar add cascade -menu .mbar.run -label Commands
.mbar.run add command -label "Compile" -command { doCompile }
.mbar.run add command -label "Run binary on device" -command { doLoadRun }
.mbar.run add command -label "Compile and run" -accelerator "^R" -command { doCompileRun }
.mbar.run add separator
.mbar.run add command -label "Configure Commands..." -command { doRunOptions }
.mbar add cascade -menu .mbar.help -label Help
.mbar.help add command -label "Help" -command { doHelp }
.mbar.help add separator
.mbar.help add command -label "About..." -command { doAbout }

wm title . "Spin 2 GUI"

grid columnconfigure . {0 1} -weight 1
grid rowconfigure . 1 -weight 1
frame .orig
frame .bot
frame .toolbar -bd 1 -relief raised

grid .toolbar -column 0 -row 0 -columnspan 2 -sticky nsew
grid .orig -column 0 -row 1 -columnspan 2 -rowspan 1 -sticky nsew
grid .bot -column 0 -row 2 -columnspan 2 -sticky nsew

button .toolbar.compile -text "Compile" -command doCompile
button .toolbar.runBinary -text "Run Binary" -command doLoadRun
button .toolbar.compileRun -text "Compile & Run" -command doCompileRun
grid .toolbar.compile .toolbar.runBinary .toolbar.compileRun -sticky nsew

scrollbar .orig.v -orient vertical -command {.orig.txt yview}
scrollbar .orig.h -orient horizontal -command {.orig.txt xview}
ctext .orig.txt -wrap none -xscroll {.orig.h set} -yscrollcommand {.orig.v set} -undo 1
label .orig.label -background DarkGrey -foreground white -text "Spin"
grid .orig.label       -sticky nsew
grid .orig.txt .orig.v -sticky nsew
grid .orig.h           -sticky nsew
grid rowconfigure .orig .orig.txt -weight 1
grid columnconfigure .orig .orig.txt -weight 1

scrollbar .bot.v -orient vertical -command {.bot.txt yview}
scrollbar .bot.h -orient horizontal -command {.bot.txt xview}
text .bot.txt -wrap none -xscroll {.bot.h set} -yscroll {.bot.v set} -height 4
label .bot.label -background DarkGrey -foreground white -text "Compiler Output"

grid .bot.label      -sticky nsew
grid .bot.txt .bot.v -sticky nsew
grid .bot.h          -sticky nsew
grid rowconfigure .bot .bot.txt -weight 1
grid columnconfigure .bot .bot.txt -weight 1

tk fontchooser configure -parent .
bind .orig.txt <FocusIn> [list fontchooserFocus .orig.txt]

bind . <Control-n> { newSpinFile }
bind . <Control-o> { loadSpinFile }
bind . <Control-s> { saveSpinFile }
bind . <Control-q> { exitProgram }
bind . <Control-r> { doCompileRun }

wm protocol . WM_DELETE_WINDOW {
    exitProgram
}

autoscroll::autoscroll .orig.v
autoscroll::autoscroll .orig.h
autoscroll::autoscroll .bot.v
autoscroll::autoscroll .bot.h

# actually read in our config info
config_open

proc fontchooserFocus {w} {
    tk fontchooser configure -font [$w cget -font] -command [list fontchooserFontSelection $w]
}

proc fontchooserFontSelection {w font args} {
    $w configure -font [font actual $font]
}

### utility: compile the program

proc mapPercent {str} {
    global SPINFILE
    global BINFILE
    global ROOTDIR
    global config
    
    set percentmap [ list "%%" "%" "%D" $ROOTDIR "%L" $config(library) "%S" $SPINFILE "%B" $BINFILE ]
    set result [string map $percentmap $str]
    return $result
}

proc doCompile {} {
    global config
    global BINFILE
    global SPINFILE
    
    set status 0
    saveSpinFile
    set cmdstr [mapPercent $config(compilecmd)]
    set runcmd [list exec -ignorestderr]
    set runcmd [concat $runcmd $cmdstr]
    lappend runcmd 2>@1
    if {[catch $runcmd errout options]} {
	set status 1
    }
    .bot.txt replace 1.0 end "$cmdstr\n"
    .bot.txt insert 2.0 $errout
    tagerrors .bot.txt
    if { $status != 0 } {
	tk_messageBox -icon error -type ok -message "Compilation failed" -detail "see compiler output window for details"
	set BINFILE ""
    } else {
	set BINFILE [file rootname $SPINFILE]
	set BINFILE "$BINFILE.binary"
    }
    return $status
}

proc doJustRun {} {
    global config
    global BINFILE
    
    set cmdstr [mapPercent $config(runcmd)]
    .bot.txt replace 1.0 end "$cmdstr\n"

    set runcmd [list exec -ignorestderr]
    set runcmd [concat $runcmd $cmdstr]
    lappend runcmd "&"

    if {[catch $runcmd errout options]} {
	.bot.txt insert 2.0 $errout
	tagerrors .bot.txt
    }
}

proc doLoadRun {} {
    global config
    global BINFILE
    global BinTypes
    
    set filename [tk_getOpenFile -filetypes $BinTypes -initialdir $config(lastdir)]
    if { [string length $filename] == 0 } {
	return
    }
    set BINFILE $filename
    doJustRun
}

proc doCompileRun {} {
    set status [doCompile]
    if { $status eq 0 } {
	doJustRun
#    } else {
#	.bot.txt replace 1.0 end "status=$status\n"
    }
}

set cmddialoghelptext {
  Strings for various commands
  Some special % escapes:
    %D = Replace with directory of spin2gui executable  
    %S = Replace with current Spin file name
    %B = Replace with current binary file name
    %% = Insert a % character
}
proc copyShadowClose {w} {
    copyShadowToConfig
    wm withdraw $w
}

proc doRunOptions {} {
    global config
    global shadow
    global cmddialoghelptext
    
    set shadow(compilecmd) $config(compilecmd)
    set shadow(runcmd) $config(runcmd)
    
    if {[winfo exists .runopts]} {
	if {![winfo viewable .runopts]} {
	    wm deiconify .runopts
	    set shadow(compilecmd) $config(compilecmd)
	    set shadow(runcmd) $config(runcmd)
	}
	raise .runopts
	return
    }

    toplevel .runopts
    label .runopts.toplabel -text $cmddialoghelptext
    ttk::labelframe .runopts.a -text "Compile command"
    entry .runopts.a.compiletext -width 32 -textvariable shadow(compilecmd)

    ttk::labelframe .runopts.b -text "Run command"
    entry .runopts.b.runtext -width 32 -textvariable shadow(runcmd)

    frame .runopts.change
    frame .runopts.end

    button .runopts.change.p2 -text "P2 defaults" -command setShadowP2Defaults
    button .runopts.change.p1 -text "P1 defaults" -command setShadowP1Defaults
    
    button .runopts.end.ok -text " OK " -command {copyShadowClose .runopts}
    button .runopts.end.cancel -text " Cancel " -command {wm withdraw .runopts}
    
    grid .runopts.toplabel
    grid .runopts.a
    grid .runopts.b
    grid .runopts.change
    grid .runopts.end
    
    grid .runopts.a.compiletext
    grid .runopts.b.runtext

    grid .runopts.change.p2 .runopts.change.p1
    grid .runopts.end.ok .runopts.end.cancel
    
    wm title .runopts "Executable Paths"
}

setHighlightingSpin .orig.txt


if { $::argc > 0 } {
    loadFileToWindow $argv .orig.txt
} else {
    set SPINFILE ""
}
