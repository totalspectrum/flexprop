# Simple GUI for Spin
# Copyright 2018-2019 Total Spectrum Software
# Distributed under the terms of the MIT license;
# see License.txt for details.
#
#
# The guts of the IDE GUI
#
set aboutMsg "
GUI tool for fastspin
Version $spin2gui_version
Copyright 2018-2019 Total Spectrum Software Inc.
------
There is no warranty and no guarantee that
output will be correct.   
"
#
# global variables
# filenames($w) gives the file name in window $w, for all of the various tabs
# filetimes($w) gives the last modified time for that file
#

set ROOTDIR [file dirname $::argv0]
set CONFIG_FILE "$ROOTDIR/.flexgui.config"


if { $tcl_platform(platform) == "windows" } {
    set WINPREFIX "cmd.exe /c start \"Propeller Output\""
} else {
    set WINPREFIX "xterm -fs 14 -e"
}
# provide some default settings
proc setShadowP1Defaults {} {
    global shadow
    global WINPREFIX
    
    set shadow(compilecmd) "\"%D/bin/fastspin\" -l %O -L \"%L\" \"%S\""
    set shadow(runcmd) "$WINPREFIX \"%D/bin/proploader\" -Dbaudrate=115200 %P \"%B\" -r -t -k"
}
proc setShadowP2aDefaults {} {
    global shadow
    global WINPREFIX
    
    set shadow(compilecmd) "\"%D/bin/fastspin\" -2a -l %O -L \"%L\" \"%S\""
    set shadow(runcmd) "$WINPREFIX \"%D/bin/loadp2\" %P -l230400 -b230400 \"%B\" -t -k"
}
proc setShadowP2bDefaults {} {
    global shadow
    global WINPREFIX
    
    set shadow(compilecmd) "\"%D/bin/fastspin\" -2b -l %O -L \"%L\" \"%S\""
    set shadow(runcmd) "$WINPREFIX \"%D/bin/loadp2\" %P -l230400 -b230400 \"%B\" -t -k"
}
proc copyShadowToConfig {} {
    global config
    global shadow
    set config(compilecmd) $shadow(compilecmd)
    set config(runcmd) $shadow(runcmd)
    checkPropVersion
}

set config(library) "./include"
set config(spinext) ".spin"
set config(lastdir) "."
set config(font) "TkFixedFont"
set config(sash) ""
set config(tabwidth) 8
set COMPORT " "
set OPT "-O1"
set COMPRESS "-z0"
set PROP_VERSION ""
set config(showlinenumbers) 1

proc checkPropVersion {} {
    global config
    global PROP_VERSION
    if {[string first " -2b " $config(compilecmd)] != -1} {
	set PROP_VERSION "P2b"
	set otherProp "P1"
    } elseif {[string first " -2" $config(compilecmd)] != -1} {
	set PROP_VERSION "P2a"
	set otherProp "P1"
    } else {
	set PROP_VERSION "P1"
	set otherProp "P2"
    }
    if { [winfo exists .toolbar] } {
	.toolbar.compile configure -text "Compile for $PROP_VERSION"
	.toolbar.compileRun configure -text "Compile & Run on $PROP_VERSION"
	.toolbar.configmsg configure -text "    Use Commands>Configure Commands... to switch to $otherProp"
    }
}

setShadowP2aDefaults
copyShadowToConfig

#
# see if there's already a tab which contains a file
# if so, return the name of the tab
# otherwise return ""
#
proc getTabFor { fname } {
    global filenames
    set tablist [.p.nb tabs]
    foreach w $tablist {
	if { "$filenames($w)" == "$fname" } {
	    return $w
	}
    }
    return ""
}

#
# set font and tab stops for a window
#
proc setfont { w fnt } {
    global config

    if { $fnt eq "" } {
	return
    }
    set t1 [font measure $fnt " "]
    set t2 [expr $config(tabwidth) * $t1]
    set stops $t2
    $w configure -font $fnt -tabs $stops
}

#
# set font and tab stops for all notebook tabs
#
proc setnbfonts { fnt } {
    global config
    set nbtablist [.p.nb tabs]
    foreach w $nbtablist {
	setfont $w.txt $fnt
    }
}

# configuration settings
proc config_open {} {
    global config
    global CONFIG_FILE
    global OPT
    global COMPRESS
    global COMPORT
    
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
	    opt {
		# set optimize level
		set OPT [lindex $data 1]
	    }
	    compress {
		# set compression level
		set COMPRESS [lindex $data 1]
	    }
	    comport {
		# set optimize level
		set COMPORT [lindex $data 1]
	    }
	    default {
		set config([lindex $data 0]) [lindex $data 1]
	    }
	}
    }
    close $fp
    checkPropVersion

    # some sanity checks
    if { "$config(font)" eq "" } {
	set config(font) "TkFixedFont"
    }
    return 1
}

proc config_save {} {
    global config
    global CONFIG_FILE
    global OPT
    global COMPRESS
    global COMPORT
    set config(sash) [.p sash coord 0]
    set fp [open $CONFIG_FILE w]
    puts $fp "# flexgui config info"
    puts $fp "geometry\t[winfo geometry [winfo toplevel .]]"
    puts $fp "opt\t\{$OPT\}"
    puts $fp "compress\t\{$COMPRESS\}"
    puts $fp "comport\t\{$COMPORT\}"
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
    } else {
	fconfigure $f -encoding utf-8
    }
    seek $f 0 start ;# rewind
    set text [read $f $len]
    close $f
    if {$encoding=="unicode"} {
	regsub -all "\uFEFF|\uFFFE" $text "" text
    }
    return $text
}

# exit the program
proc exitProgram { } {
    checkAllChanges
    config_save
    exit
}

# close tab
proc closeTab { } {
    global filenames
    set w [.p.nb select]
    if { $w ne "" } {
	checkChanges $w
	set filenames($w) ""
	.p.nb forget $w
	destroy $w
    }
}

# load a file into a text (or ctext) window
proc loadFileToWindow { fname win } {
    global filetimes
    set file_data [uread $fname]
    $win delete 1.0 end
    $win insert end $file_data
    $win edit modified false
    set filetimes($fname) [file mtime $fname]
}

# save contents of a window to a file
proc saveFileFromWindow { fname win } {
    global filetimes

    # check for other programs changing the file
    if { [file exists $fname] } {
        set disktime [file mtime $fname]
        if { $disktime > $filetimes($fname) } {
	    set answer [tk_messageBox -icon question -type yesno -message "File $fname has changed on disk; overwrite it?" -default no]
	    if { $answer eq no } {
	        return
	    }
	}
    }
    set fp [open $fname w]
    set file_data [$win get 1.0 end]

    # encode as UTF-8
    fconfigure $fp -encoding utf-8
    
    # HACK: the text widget inserts an extra \n at end of file
    set file_data [string trimright $file_data]
    
    set len [string len $file_data]
    #puts " writing $len bytes"

    # we trimmed away all the \n above, so put one back here
    # by leaving off the -nonewline to puts
    puts $fp $file_data
    close $fp
    set filetimes($fname) [file mtime $fname]
    $win edit modified false
}


#
# tag text containing "error:" in a text widget w
#
proc tagerrors { w } {
    $w tag remove errtxt 0.0 end
    $w tag remove warntxt 0.0 end
    $w tag remove errlink 0.0 end
    
    $w tag configure errtxt -foreground red
    $w tag configure warntxt -foreground orange
    $w tag configure errlink -foreground blue -underline true

    # set current position at beginning of file
    set cur 1.0
    # search through looking for error:
    while 1 {
	set cur [$w search -count length "error:" $cur end]
	if {$cur eq ""} {break}
	$w tag add errtxt $cur "$cur lineend"
	$w tag add errlink "$cur linestart" "$cur - 2 chars"
	set cur [$w index "$cur + $length char"]
    }

    # set current position at beginning of file
    set cur 1.0
    # search through looking for warning:
    while 1 {
	set cur [$w search -count length "warning:" $cur end]
	if {$cur eq ""} {break}
	$w tag add warntxt $cur "$cur lineend"
	$w tag add errlink "$cur linestart" "$cur - 2 chars"
	set cur [$w index "$cur + $length char"]
    }
    
}

set SpinTypes {
    {{FastSpin files}   {.bas .bi .c .h .spin2 .spin .spinh} }
    {{Spin2 files}   {.spin2 .spin .spinh} }
    {{BASIC files}   {.bas .bi} }
    {{C files}   {.c .h} }
    {{All files}    *}
}

set BinTypes {
    {{Binary files}   {.binary .bin} }
    {{All files}    *}
}

#
# see if anything has changed in window w
#
proc checkChanges {w} {
    global filenames
    set s $filenames($w)
    if { $s eq "" } {
	return
    }
    if {[$w.txt edit modified]==1} {
	set answer [tk_messageBox -icon question -type yesno -message "Save file $s?" -default yes]
	if { $answer eq yes } {
	    saveFile $w
	}
    }
}

# check all windows for changes
proc checkAllChanges {} {
    set t [.p.nb tabs]
    set i 0
    set w [lindex $t $i]
    while { $w ne "" } {
	checkChanges $w
	set i [expr "$i + 1"]
	set w [lindex $t $i]
    }
}

# clear all search tags
proc clearAllSearchTags {} {
    set t [.p.nb tabs]
    set i 0
    set w [lindex $t $i]
    while { $w ne "" } {
	set t $w.txt
	foreach {from to} [$t tag ranges hilite] {
	    $t tag remove hilite $from $to
	}
	set i [expr "$i + 1"]
	set w [lindex $t $i]
    }
}

# choose the library directory
proc getLibrary {} {
    global config
    
    set lib [tk_chooseDirectory -title "Choose library directory" -initialdir $config(library) ]
    if { $lib ne "" } {
	set config(library) $lib
    }
}

set TABCOUNTER 0
proc newTabName {} {
    global TABCOUNTER
    set s "f$TABCOUNTER"
    set TABCOUNTER [expr "$TABCOUNTER + 1"]
    return ".p.nb.$s"
}

proc createNewTab {} {
    global filenames
    global config
    set w [newTabName]
    
    #.p.bot.txt delete 1.0 end
    set filenames($w) ""
    setupFramedText $w
    #setHighlightingSpin $w.txt
    setfont $w.txt $config(font)
    .p.nb add $w
    .p.nb tab $w -text "New File"
    .p.nb select $w
    return $w
}

#
# set up a framed text window
#
proc setupFramedText {w} {
    global config
    frame $w
    set yscmd "$w.v set"
    set xscmd "$w.h set"
    set yvcmd "$w.txt yview"
    set xvcmd "$w.txt xview"
    set searchcmd "searchrep $w.txt 0"

    ctext $w.txt -wrap none -yscrollcommand $yscmd -xscroll $xscmd -tabstyle wordprocessor -linemap $config(showlinenumbers)
    scrollbar $w.v -orient vertical -command $yvcmd
    scrollbar $w.h -orient horizontal -command $xvcmd

    grid $w.txt $w.v -sticky nsew
    grid $w.h -sticky nsew
    grid rowconfigure $w $w.txt -weight 1
    grid columnconfigure $w $w.txt -weight 1
    bind $w.txt <Control-f> $searchcmd
}

#
# load a file into a toplevel window .list
#
proc loadListingFile {filename} {
    global config
    set viewpos 0
    if {[winfo exists .list]} {
	raise .list
	set viewpos [.list.f.txt yview]
	set viewpos [lindex $viewpos 0]
    } else {
	toplevel .list
	setupFramedText .list.f
	grid columnconfigure .list 0 -weight 1
	grid rowconfigure .list 0 -weight 1
	grid .list.f -sticky nsew
    }
    loadFileToWindow $filename .list.f.txt
    .list.f.txt yview moveto $viewpos
    wm title .list [file tail $filename]
}

#
# load a file into a tab
# the tab name is w
# its title is title
# if title is "" then set the title based on the file name
#
proc loadFileToTab {w filename title} {
    global config
    global filenames
    global filetimes
    if {$title eq ""} {
	set title [file tail $filename]
    }
    if {[winfo exists $w]} {
	.p.nb select $w
    } else {
	setupFramedText $w
	.p.nb add $w -text "$title"
	#setHighlightingSpin $w.txt
    }

    
    setfont $w.txt $config(font)
    loadFileToWindow $filename $w.txt
    $w.txt highlight 1.0 end
    ctext::comments $w.txt
    ctext::linemapUpdate $w.txt
    .p.nb tab $w -text $title
    .p.nb select $w
    set filenames($w) $filename
    set filetimes($filename) [file mtime $filename]
}

proc loadSourceFile { filename } {
    global filenames

    set w [getTabFor $filename]
    if { $w ne "" } {
	.p.nb select $w
    } else {
	set w [.p.nb select]
    
	if { $w eq "" || $filenames($w) ne ""} {
	    set w [createNewTab]
	}
	checkChanges $w
    
	loadFileToTab $w $filename ""
    }
    return $w
}

proc doOpenFile {} {
    global config
    global SpinTypes
    global BINFILE

    set filename [tk_getOpenFile -filetypes $SpinTypes -defaultextension $config(spinext) -initialdir $config(lastdir) ]
    if { [string length $filename] == 0 } {
	return ""
    }
    set config(lastdir) [file dirname $filename]
    set config(spinext) [file extension $filename]
    set BINFILE ""
    
    return [loadSourceFile $filename]
}

# maybe save the current file; used for compilation
# if no changes, then do not save
proc saveFilesForCompile {} {
    global filenames
    global filetimes
    set t [.p.nb tabs]
    set i 0
    set w [lindex $t $i]
    while { $w ne "" } {
	set s $filenames($w)
	set needWrite "no"
	set needRead "no"
	if { $s eq "" } {
	    # need to ask the user for the file name
	    saveFile $w
	} else {
	    if {[$w.txt edit modified]==1} {
		set needWrite "yes"
	    }
	    if { [file exists $s] } {
		set disktime [file mtime $s]
	        if {$disktime > $filetimes($s)} {
		    set needRead "yes"
		}
	    } else {
		set needWrite "yes"
	    }
	    if { $needWrite eq "yes" } {
		saveFileFromWindow $s $w.txt
	    }
	    if { $needRead eq "yes" } {
		set answer [tk_messageBox -icon question -type yesno -message "File $s has changed on disk. Reload it?" -default yes]
		if { $answer eq yes } {
		    loadFileToWindow $s $w.txt
		    set needRead "no"
		    set needWrite "no"
		} else {
		    set needWrite "no"
		}
	    }
	}
	set i [expr "$i + 1"]
	set w [lindex $t $i]
    }
}
    
# always save the current file
proc saveCurFile {} {
    set w [.p.nb select]
    saveFile $w
}
		  
proc saveFile {w} {
    global filenames
    global filetimes
    global BINFILE
    global SpinTypes
    global config
    
    if { [string length $filenames($w)] == 0 } {
	set filename [tk_getSaveFile -initialfile $filenames($w) -filetypes $SpinTypes -defaultextension $config(spinext) ]
	if { [string length $filename] == 0 } {
	    return
	}
	set config(lastdir) [file dirname $filename]
	set config(spinext) [file extension $filename]
	set filenames($w) $filename
	.p.nb tab $w -text [file root $filename]
	set BINFILE ""
    }
    
    saveFileFromWindow $filenames($w) $w.txt
}

proc saveFileAs {w} {
    global filenames
    global BINFILE
    global SpinTypes
    global config

    if { [string length $filenames($w)] == 0 } {
	set initdir $config(lastdir)
	set initfilename ""
    } else {
	set initdir [file dirname $filenames($w)]
	set initfilename [file tail $filenames($w)]
    }
    set filename [tk_getSaveFile -filetypes $SpinTypes -defaultextension $config(spinext) -initialdir $initdir -initialfile $initfilename ]
    if { [string length $filename] == 0 } {
	return
    }
    set config(lastdir) [file dirname $filename]
    set config(spinext) [file extension $filename]
    set BINFILE ""
    set filenames($w) $filename
    .p.nb tab $w -text [file tail $filename]
    saveFile $w
}

proc doAbout {} {
    global aboutMsg
    tk_messageBox -icon info -type ok -message "FlexGUI" -detail $aboutMsg
}

proc doHelp {} {
    loadFileToTab .p.nb.help "doc/help.txt" "Help"
    makeReadOnly .p.nb.help.txt
}

#
# parameter is text coordinates like 2.72
#
proc doClickOnError {coord} {
    set w .p.bot.txt
    set first "$coord linestart"
    set last "$coord lineend"
    set linkptr [$w tag prevrange errlink $coord]
    set link1 [lindex $linkptr 0]
    set link2 [lindex $linkptr 1]
    set linedata [.p.bot.txt get $link1 $link2]
    set colonptr [string last ":" $linedata]

    if { $colonptr eq "" } {
	set fname ""
	set line ""
    } else {
	set fname [string range $linedata 0 [expr $colonptr - 1]]
	set line [string range $linedata [expr $colonptr + 1] end]
    }
    #tk_messageBox -message "data: <$linedata> fname: <$fname> line: <$line>" -type ok
    if { $fname != "" } {
	set w [loadSourceFile $fname ]
	set t $w.txt
	$t tag config hilite -background yellow
	# remove hilight
	foreach {from to} [$t tag ranges hilite] {
	    $t tag remove hilite $from $to
	}
	$t tag config hilite -background yellow
	$t see $line.0
	$t tag add hilite $line.0 $line.end
    }
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
    set color(varnames) black
    set color(preprocessor) cyan
    set keywordsbase [list Con Obj Dat Var Pub Pri Quit Exit Repeat While Until If Then Else Return Abort Long Word Byte Asm Endasm String]
    foreach i $keywordsbase {
	lappend keywordsupper [string toupper $i]
    }
    foreach i $keywordsbase {
	lappend keywordslower [string tolower $i]
    }
    set keywords [concat $keywordsbase $keywordsupper $keywordslower]

    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) \$ 
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) \%
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 0
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 1
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 2
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 3
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 4
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 5
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 6
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 7
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 8
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 9

    ctext::addHighlightClass $w keywords $color(keywords) $keywords

    ctext::addHighlightClassForSpecialChars $w brackets $color(brackets) {[]()}
    ctext::addHighlightClassForSpecialChars $w operators $color(operators) {+-=><!@~\*/&:|}

    ctext::addHighlightClassForRegexp $w strings $color(strings) {"(\\"||^"])*"}
    ctext::addHighlightClassForRegexp $w preprocessor $color(preprocessor) {^\#[a-z]+}

    ctext::addHighlightClassForRegexp $w comments $color(comments) {\'[^\n\r]*}
    ctext::enableComments $w
    $w tag configure _cComment -foreground $color(comments)
    $w tag raise _cComment
}

menu .popup1 -tearoff 0
.popup1 add command -label "Cut" -command {event generate [focus] <<Cut>>}
.popup1 add command -label "Copy" -command {event generate [focus] <<Copy>>}
.popup1 add command -label "Paste" -command {event generate [focus] <<Paste>>}
.popup1 add command -label "Undo" -command {event generate [focus] <<Undo>>}
.popup1 add separator
.popup1 add command -label "Save File" -command { saveCurFile }
.popup1 add command -label "Save File As..." -command { saveFileAs [.p.nb select] }
.popup1 add separator
.popup1 add command -label "Close" -command { closeTab }

menu .mbar
. configure -menu .mbar
menu .mbar.file -tearoff 0
menu .mbar.edit -tearoff 0
menu .mbar.options -tearoff 0
menu .mbar.run -tearoff 0
menu .mbar.comport -tearoff 0
menu .mbar.help -tearoff 0

.mbar add cascade -menu .mbar.file -label File
.mbar.file add command -label "New File" -accelerator "^N" -command { createNewTab }
.mbar.file add command -label "Open File..." -accelerator "^O" -command { doOpenFile }
.mbar.file add command -label "Save File" -accelerator "^S" -command { saveCurFile }
.mbar.file add command -label "Save File As..." -command { saveFileAs [.p.nb select] }
.mbar.file add separator
.mbar.file add command -label "Library directory..." -command { getLibrary }
.mbar.file add separator
.mbar.file add command -label "Close tab" -accelerator "^W" -command { closeTab }
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
.mbar.edit add command -label "Find..." -accelerator "^F" -command {searchrep [focus] 0}
.mbar.edit add separator

#.mbar.edit add command -label "Select Font..." -command { doSelectFont }
.mbar.edit add command -label "Editor Appearance..." -command { doAppearance }

.mbar add cascade -menu .mbar.options -label Options
.mbar.options add radiobutton -label "No Optimization" -variable OPT -value "-O0"
.mbar.options add radiobutton -label "Default Optimization" -variable OPT -value "-O1"
.mbar.options add radiobutton -label "Full Optimization" -variable OPT -value "-O2"
#.mbar.options add separator
#.mbar.options add radiobutton -label "No Compression" -variable COMPRESS -value "-z0"
#.mbar.options add radiobutton -label "Compress Code" -variable COMPRESS -value "-z1"

.mbar add cascade -menu .mbar.run -label Commands
.mbar.run add command -label "Compile" -command { doCompile }
.mbar.run add command -label "Run binary on device" -command { doLoadRun }
.mbar.run add command -label "Compile and run" -accelerator "^R" -command { doCompileRun }
.mbar.run add separator
.mbar.run add command -label "Open listing file" -accelerator "^L" -command { doListing }
.mbar.run add separator
.mbar.run add command -label "Configure Commands..." -command { doRunOptions }

.mbar add cascade -menu .mbar.comport -label Port
.mbar.comport add radiobutton -label "Default (try to find port)" -variable COMPORT -value " "

# search for serial ports using serial::listports (src/checkserial.tcl)
set serlist [serial::listports]
foreach v $serlist {
    set comname [lrange [split $v "\\"] end end]
    set portval [string map {\\ \\\\} "-p $v"]
    .mbar.comport add radiobutton -label $comname -variable COMPORT -value $portval
}

.mbar add cascade -menu .mbar.help -label Help
.mbar.help add command -label "Help" -command { doHelp }
.mbar.help add separator
.mbar.help add command -label "About..." -command { doAbout }

wm title . "FlexGUI"

panedwindow .p -orient vertical

grid columnconfigure . {0 1} -weight 1
grid rowconfigure . 1 -weight 1
ttk::notebook .p.nb
frame .p.bot
frame .toolbar -bd 1 -relief raised

grid .toolbar -column 0 -row 0 -columnspan 2 -sticky nsew
grid .p -column 0 -row 1 -columnspan 2 -rowspan 1 -sticky nsew

button .toolbar.compile -text "Compile" -command doCompile
button .toolbar.runBinary -text "Run Binary" -command doLoadRun
button .toolbar.compileRun -text "Compile & Run" -command doCompileRun
label  .toolbar.configmsg -text "   Use Commands>Configure Commands... to switch to P1" -font TkSmallCaptionFont

grid .toolbar.compile .toolbar.runBinary .toolbar.compileRun .toolbar.configmsg -sticky nsew

scrollbar .p.bot.v -orient vertical -command {.p.bot.txt yview}
scrollbar .p.bot.h -orient horizontal -command {.p.bot.txt xview}
text .p.bot.txt -wrap none -xscroll {.p.bot.h set} -yscroll {.p.bot.v set} -height 10 -font "courier 8"
label .p.bot.label -background DarkGrey -foreground white -text "Compiler Output" -font TkSmallCaptionFont -relief flat -pady 0 -borderwidth 0

grid .p.bot.label      -sticky nsew
grid .p.bot.txt .p.bot.v -sticky nsew
grid .p.bot.h          -sticky nsew
grid rowconfigure .p.bot .p.bot.txt -weight 1
grid columnconfigure .p.bot .p.bot.txt -weight 1

.p add .p.nb
.p add .p.bot
.p paneconfigure .p.nb -stretch always
.p paneconfigure .p.bot -stretch never

#bind .p.nb.main.txt <FocusIn> [list fontchooserFocus .p.nb.main.txt]

bind . <Control-n> { createNewTab }
bind . <Control-o> { doOpenFile }
bind . <Control-s> { saveCurFile }
bind . <Control-b> { browseFile }
bind . <Control-q> { exitProgram }
bind . <Control-r> { doCompileRun }
bind . <Control-l> { doListing }
bind . <Control-f> { searchrep [focus] 0 }
bind . <Control-w> { closeTab }

# bind to right mouse button on Linux and Windows

if {[tk windowingsystem]=="aqua"} {
    bind . <2> "tk_popup .popup1 %X %Y"
    bind . <Control-1> "tk_popup .popup1 %X %Y"
} else {
    bind . <3> "tk_popup .popup1 %X %Y"
}

#bind .p.bot.txt <Double-1> { doClickOnError "[%W index @%x,%y]" }
set pbotcursor [.p.bot.txt cget -cursor]

.p.bot.txt tag bind errlink <Enter> { .p.bot.txt configure -cursor fleur }
.p.bot.txt tag bind errlink <Leave> { .p.bot.txt configure -cursor $pbotcursor }
.p.bot.txt tag bind errlink <ButtonPress> { doClickOnError "[%W index @%x,%y]" }

wm protocol . WM_DELETE_WINDOW {
    exitProgram
}

#autoscroll::autoscroll .p.nb.main.v
#autoscroll::autoscroll .p.nb.main.h
#autoscroll::autoscroll .p.bot.v
#autoscroll::autoscroll .p.bot.h

# actually read in our config info
config_open

# font configuration stuff
proc doSelectFont {} {
    global config
    set curfont $config(font)
    tk fontchooser configure -parent . -font "$curfont" -command resetFont
    tk fontchooser show
}

proc resetFont {w} {
    global config
    set fnt [font actual $w]
    set config(font) $fnt
    setnbfonts $fnt
    .editopts.font.lb configure -font $fnt
}

proc doShowLinenumbers {} {
    global config
    set tablist [.p.nb tabs]
    foreach w $tablist {
	$w.txt configure -linemap $config(showlinenumbers)
	ctext::linemapUpdate $w.txt
    }
}

proc doneAppearance {} {
    global config

    set config(tabwidth) [.editopts.font.tab.stops get]
    setnbfonts $config(font)
    wm withdraw .editopts
}

#
# editor appearance window
#
proc doAppearance {} {
    global config

    if {[winfo exists .editopts]} {
	if {![winfo viewable .editopts]} {
	    wm deiconify .editopts
	}
	raise .editopts
	return
    }
    toplevel .editopts
    frame .editopts.top
    ttk::labelframe .editopts.font -text "Source code"
    ttk::labelframe .editopts.bot -text "Compiler output"
    frame .editopts.end

    label .editopts.top.l -text "\n  Editor Options  \n"

    frame .editopts.font.tab
    label  .editopts.font.tab.lab -text " Tab stops: "
    spinbox .editopts.font.tab.stops -text "hello" -from 1 -to 9 -width 2
    .editopts.font.tab.stops set $config(tabwidth)

    label .editopts.font.lb -text " Text font " -font $config(font)
    button .editopts.font.change -text " Change... " -command doSelectFont
    checkbutton .editopts.font.linenums -text "Show Linenumbers" -variable config(showlinenumbers) -command doShowLinenumbers
    button .editopts.end.ok -text " OK " -command doneAppearance

    grid .editopts.top.l -sticky nsew 
    grid .editopts.font.tab.lab .editopts.font.tab.stops
    grid .editopts.font.tab .editopts.font.lb .editopts.font.change
    grid .editopts.font.linenums
    
    grid .editopts.end.ok -sticky nsew
    grid .editopts.top -sticky nsew
    grid .editopts.font -sticky nsew
    grid .editopts.bot -sticky nsew
    grid .editopts.end -sticky nsew

    wm title .editopts "Editor Appearance"
}

# translate % escapes in our command line strings
proc mapPercent {str} {
    global filenames
    global BINFILE
    global ROOTDIR
    global OPT
    global COMPRESS
    global COMPORT
    global config

#    set fulloptions "$OPT $COMPRESS"
    set fulloptions "$OPT"
    set percentmap [ list "%%" "%" "%D" $ROOTDIR "%L" $config(library) "%S" $filenames([.p.nb select]) "%B" $BINFILE "%O" $fulloptions "%P" $COMPORT ]
    set result [string map $percentmap $str]
    return $result
}

### utility: make a window read only
proc makeReadOnly {hWnd} {
# Disable all key sequences for widget named in variable hWnd, except
# the cursor navigation keys (regardless of the state ctrl/shift/etc.)
# and Ctrl-C (Copy to Clipboard).
    # from ActiveState Code >> Recipes
    
bind $hWnd <KeyPress> {
    switch -- %K {
        "Up" -
        "Left" -
        "Right" -
        "Down" -
        "Next" -
        "Prior" -
        "Home" -
        "End" {
        }

	"f" -
	"F" -
        "c" -
        "C" {
            if {(%s & 0x04) == 0} {
                break
            }
        }

        default {
            break
        }
    }
}

# Addendum: also a good idea disable the cut and paste events.

bind $hWnd <<Paste>> "break"
bind $hWnd <<Cut>> "break"
}

### utility: compile the program

proc doCompile {} {
    global config
    global BINFILE
    global filenames
    
    set status 0
    clearAllSearchTags
    saveFilesForCompile
    set cmdstr [mapPercent $config(compilecmd)]
    set runcmd [list exec -ignorestderr]
    set runcmd [concat $runcmd $cmdstr]
    lappend runcmd 2>@1
    if {[catch $runcmd errout options]} {
	set status 1
    }
    .p.bot.txt replace 1.0 end "$cmdstr\n"
    .p.bot.txt insert 2.0 $errout
    .p.bot.txt insert end "\nFinished at "
    set now [clock seconds]
    .p.bot.txt insert end [clock format $now -format %c]
##    .p.bot.txt insert end " on [info hostname]"
    tagerrors .p.bot.txt
    if { $status != 0 } {
	tk_messageBox -icon error -type ok -message "Compilation failed" -detail "see compiler output window for details"
	set BINFILE ""
    } else {
	set BINFILE [file rootname $filenames([.p.nb select])]
	set BINFILE "$BINFILE.binary"
	# load the listing if a listing window is open
	if {[winfo exists .list]} {
	    doListing
	}
    }
    return $status
}

proc doListing {} {
    global filenames
    set w [.p.nb select]
    if { $w ne "" } {
	set LSTFILE [file rootname $filenames($w)]
	set LSTFILE "$LSTFILE.lst"
	loadListingFile $LSTFILE
	makeReadOnly .list.f.txt
    }
}

proc doJustRun {} {
    global config
    global BINFILE
    
    set cmdstr [mapPercent $config(runcmd)]
    .p.bot.txt insert end "$cmdstr\n"

    set runcmd [list exec -ignorestderr]
    set runcmd [concat $runcmd $cmdstr]
    lappend runcmd "&"

    if {[catch $runcmd errout options]} {
	.p.bot.txt insert 2.0 $errout
	tagerrors .p.bot.txt
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
    .p.bot.txt delete 1.0 end
    doJustRun
}

proc doCompileRun {} {
    set status [doCompile]
    if { $status eq 0 } {
	.p.bot.txt insert end "\n"
	doJustRun
    }
}

set cmddialoghelptext {
  Strings for various commands
  Some special % escapes:
    %B = Replace with current binary file name
    %D = Replace with directory of flexgui executable
    %L = Replace with library directory
    %O = Replace with optimization level
    %P = Replace with port to use
    %S = Replace with current source file name
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

    button .runopts.change.p2a -text "P2a defaults" -command setShadowP2aDefaults
    button .runopts.change.p2b -text "P2b defaults" -command setShadowP2bDefaults
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

    grid .runopts.change.p2a .runopts.change.p1
    grid .runopts.change.p2b
    grid .runopts.end.ok .runopts.end.cancel
    
    wm title .runopts "Executable Paths"
}

#
# simple search and replace widget by Richard Suchenwirth, from wiki.tcl.tk
#
proc searchrep {t {replace 1}} {
   set w .sr
   if ![winfo exists $w] {
       toplevel $w
       wm title $w "Search"
       grid [label $w.1 -text Find:] [entry $w.f -textvar Find] \
               [button $w.bn -text Next \
               -command [list searchrep'next $t]] -sticky ew
       bind $w.f <Return> [list $w.bn invoke]
       if $replace {
           grid [label $w.2 -text Replace:] [entry $w.r -textvar Replace] \
                   [button $w.br -text Replace \
                   -command [list searchrep'rep1 $t]] -sticky ew
           bind $w.r <Return> [list $w.br invoke]
           grid x x [button $w.ba -text "Replace all" \
                   -command [list searchrep'all $t]] -sticky ew
       }
       grid x [checkbutton $w.i -text "Ignore case" -variable IgnoreCase] \
               [button $w.c -text Cancel -command "destroy $w"] -sticky ew
       grid $w.i -sticky w
       grid columnconfigure $w 1 -weight 1
       $t tag config hilite -background yellow
       focus $w.f
   } else {
       raise $w.f
       focus $w
   }
}

# Find the next instance
proc searchrep'next w {
    foreach {from to} [$w tag ranges hilite] {
        $w tag remove hilite $from $to
    }
    set cmd [list $w search -count n -- $::Find insert+2c]
    if $::IgnoreCase {set cmd [linsert $cmd 2 -nocase]}
    set pos [eval $cmd]
    if {$pos eq ""} {
	tk_messageBox -icon info -type ok -message "Not found"
    } else {
        $w mark set insert $pos
        $w see insert
        $w tag add hilite $pos $pos+${n}c
    }
}

# Replace the current instance, and find the next
proc searchrep'rep1 w {
    if {[$w tag ranges hilite] ne ""} {
        $w delete insert insert+[string length $::Find]c
        $w insert insert $::Replace
        searchrep'next $w
        return 1
    } else {return 0}
}

# Replace all
proc searchrep'all w {
    set go 1
    while {$go} {set go [searchrep'rep1 $w]}
}

# set the sash position on .p
proc setSash {} {
    global config
    if { $config(sash) != "" } {
	set xval [lindex $config(sash) 0]
	set yval [lindex $config(sash) 1]
	.p sash place 0 $xval $yval
        set config(sash) ""
    }
}

set oldExpose [bind .p <Expose>]

bind .p.bot.txt <Expose> +setSash

# main code

if { $::argc > 0 } {
    loadFileToTab $argv .p.nb.main
} else {
    createNewTab
}
