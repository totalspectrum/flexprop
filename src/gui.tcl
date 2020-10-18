# Simple GUI for Spin
# Copyright 2018-2020 Total Spectrum Software
# Distributed under the terms of the MIT license;
# see License.txt for details.
#
#
# The guts of the IDE GUI
#
set aboutMsg "
GUI tool for FlexProp
Version $spin2gui_version
Copyright 2018-2020 Total Spectrum Software Inc.
------
There is no warranty and no guarantee that
output will be correct.   
"

# some Tcl/Tk config
# make sure tcl_wordchars is set
catch {tcl_endOfWord}
# change it
set tcl_wordchars {[[:alnum:]_]}
set tcl_nonwordchars {[^[:alnum:]_]}
#
# global variables
# ROOTDIR was set by our caller to be the directory from which all other
# files are relative (usually the location of the program)
#

# config file name
set CONFIG_FILE "$ROOTDIR/.flexprop.config"

# prefix for shortcut keys (Command on Mac, Control elsewhere)
if { [tk windowingsystem] == "aqua" } {
    set CTRL_PREFIX "Command"
} else {
    set CTRL_PREFIX "Control"
}

# executable prefix; on Windows .exe is automatically appended, so we don't
# have to explicitly specify it

set EXE ""
if { $tcl_platform(os) == "Darwin" && [file exists "$ROOTDIR/bin/fastspin.mac"] && [file exists "$ROOTDIR/bin/loadp2.mac"] } {
    set EXE ".mac"
}

# prefix for starting a command in a window
if { $tcl_platform(platform) == "windows" } {
    set WINPREFIX "cmd.exe /c start \"Propeller Output %p\""
} elseif { [tk windowingsystem] == "aqua" } {
    set WINPREFIX $ROOTDIR/bin/mac_terminal.sh
} elseif { [file executable /etc/alternatives/x-terminal-emulator] } {
    set WINPREFIX "/etc/alternatives/x-terminal-emulator -T \"Propeller Output %p\" -e"
} else {
    set WINPREFIX "xterm -fs 14 -T \"Propeller Output %p\" -e"
}

# default configuration variables
# the config() array is written to the config file and read
# back at run time

set config(library) "$ROOTDIR/include"
set config(liblist) [list $config(library)]
set config(spinext) ".spin"
set config(lastdir) [pwd]
set config(font) "TkFixedFont"
set config(botfont) "courier 10"
set config(sash) ""
set config(tabwidth) 4
set config(autoreload) 0
set COMPORT " "
set OPT "-O1"
set COMPRESS "-z0"
set WARNFLAGS "-Wnone"
set DEBUG_OPT "-gnone"
set PROP_VERSION ""
set OPENFILES ""
set config(showlinenumbers) 1
set config(savesession) 1
set config(syntaxhighlight) 1
set config(autoindent) 1

#
# filenames($w) gives the file name in window $w, for all of the various tabs
# filetimes($w) gives the last modified time for that file
#

proc getWindowFile { w } {
    global filenames
    while { "$w" != "" } {
	if { [info exists filenames($w)] } {
	    #puts "return $filenames($w)"
	    return $filenames($w)
	}
	set w [winfo parent $w]
    }
    #puts "getWindowFile: $w: no answer"
    #puts [parray filenames]
    return ""
}

# provide some default settings
proc setShadowP1Defaults {} {
    global shadow
    global WINPREFIX
    global ROOTDIR
    global EXE
    
    set shadow(compilecmd) "\"%D/bin/fastspin$EXE\" -D_BAUD=%r -l %O %I \"%S\""
    set shadow(runcmd) "$WINPREFIX \"%D/bin/proploader$EXE\" -Dbaudrate=%r %P \"%B\" -r -t -k"
    set shadow(flashprogram) "$ROOTDIR/board/P2ES_flashloader.bin"
    set shadow(flashcmd) "$WINPREFIX \"%D/bin/proploader$EXE\" -Dbaudrate=%r %P \"%B\" -e -k"
    set shadow(baud) 115200
}
proc setShadowP2aDefaults {} {
    global shadow
    global WINPREFIX
    global ROOTDIR
    global EXE
    
    set shadow(compilecmd) "\"%D/bin/fastspin$EXE\" -2a -l -D_BAUD=%r %O %I \"%S\""
    set shadow(runcmd) "$WINPREFIX \"%D/bin/loadp2$EXE\" %P -b%r \"%B\" \"-9%b\" -k"
    set shadow(flashprogram) "$ROOTDIR/board/P2ES_flashloader.bin"
    set shadow(flashcmd) "$WINPREFIX \"%D/bin/loadp2$EXE\" %P -b%r \"@0=%F,@8000+%B\" -t -k"
    set shadow(baud) 230400
}
proc setShadowP2bDefaults {} {
    global shadow
    global WINPREFIX
    global ROOTDIR
    global EXE
    
    set shadow(compilecmd) "\"%D/bin/fastspin$EXE\" -2 -l -D_BAUD=%r %O %I \"%S\""
    set shadow(runcmd) "$WINPREFIX \"%D/bin/loadp2$EXE\" %P -b%r \"%B\" \"-9%b\" -k"
    set shadow(flashprogram) "$ROOTDIR/board/P2ES_flashloader.bin"
    set shadow(flashcmd) "$WINPREFIX \"%D/bin/loadp2$EXE\" %P -b%r \"@0=%F,@8000+%B\" -t -k"
    set shadow(baud) 230400
}
proc copyShadowToConfig {} {
    global config
    global shadow
    set config(compilecmd) $shadow(compilecmd)
    set config(runcmd) $shadow(runcmd)
    set config(flashcmd) $shadow(flashcmd)
    set config(flashprogram) $shadow(flashprogram)
    set config(baud) $shadow(baud)
    checkPropVersion
}

proc checkPropVersion {} {
    global config
    global PROP_VERSION
    if {[string first " -2a " $config(compilecmd)] != -1} {
	set PROP_VERSION "P2a"
	set otherProp "P1"
    } elseif {[string first " -2" $config(compilecmd)] != -1} {
	set PROP_VERSION "P2"
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

setShadowP2bDefaults
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
    if {[winfo exists .list]} {
	setfont .list.f.txt $fnt
    }
}

# configuration settings
proc config_open {} {
    global config
    global CONFIG_FILE
    global OPT
    global COMPRESS
    global WARNFLAGS
    global DEBUG_OPT
    global COMPORT
    global OPENFILES
    
    if {[file exists $CONFIG_FILE]} {
	set fp [open $CONFIG_FILE r]
    } else {
	checkPropVersion
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
	    warnflags {
		# set warning flags
		set WARNFLAGS [lindex $data 1]
	    }
	    debugopt {
		# set warning flags
		set DEBUG_OPT [lindex $data 1]
	    }
	    comport {
		# set optimize level
		set COMPORT [lindex $data 1]
		# convert old COMPORT entries
		if { $COMPORT ne " " && [string index "$COMPORT" 0] ne "-" } {
		    set COMPORT "-p $COMPORT"
		}
	    }
	    openfiles {
		# record open files
		set OPENFILES [lindex $data 1]
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
    global WARNFLAGS
    global DEBUG_OPT
    global COMPORT
    global OPENFILES
    
    updateLibraryList
    updateOpenFiles
    set config(sash) [.p sash coord 0]
    set fp [open $CONFIG_FILE w]
    puts $fp "# flexprop config info"
    puts $fp "geometry\t[winfo geometry [winfo toplevel .]]"
    puts $fp "opt\t\{$OPT\}"
    puts $fp "compress\t\{$COMPRESS\}"
    puts $fp "comport\t\{$COMPORT\}"
    puts $fp "openfiles\t\{$OPENFILES\}"
    puts $fp "warnflags\t\{$WARNFLAGS\}"
    puts $fp "debugopt\t\{$DEBUG_OPT\}"
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

# set list of open files
proc updateOpenFiles { } {
    global OPENFILES
    global filenames
    set t [.p.nb tabs]
    set i 0
    set w [lindex $t $i]
    set OPENFILES [list]
    while { $w ne "" } {
	set s $filenames($w)
	lappend OPENFILES $s
	set i [expr "$i + 1"]
	set w [lindex $t $i]
    }
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
    $win mark set insert 1.0
    set filetimes($fname) [file mtime $fname]
    setHighlightingForFile $win $fname
    focus $win
}

# save contents of a window to a file
proc saveFileFromWindow { fname win } {
    global filetimes
    global config
    
    # check for other programs changing the file
    if { [file exists $fname] } {
        set disktime [file mtime $fname]
        if { $disktime > $filetimes($fname) } {
	    set answer $config(autoreload)
	    if { ! $answer } {
		set answer [tk_messageBox -icon question -type yesno -message "File $fname has changed on disk; overwrite it?" -default no]
	    }
	    if { ! $answer } {
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
    $w tag remove hyperlink 0.0 end
    
    $w tag configure errtxt -foreground red
    $w tag configure warntxt -foreground orange
    $w tag configure hyperlink -foreground blue -underline true

    # set current position at beginning of file
    set cur 1.0
    # search through looking for error:
    while 1 {
	set cur [$w search -count length "error:" $cur end]
	if {$cur eq ""} {break}
	$w tag add errtxt $cur "$cur lineend"
	$w tag add hyperlink "$cur linestart" "$cur - 2 chars"
	set cur [$w index "$cur + $length char"]
    }

    # set current position at beginning of file
    set cur 1.0
    # search through looking for warning:
    while 1 {
	set cur [$w search -count length "warning:" $cur end]
	if {$cur eq ""} {break}
	$w tag add warntxt $cur "$cur lineend"
	$w tag add hyperlink "$cur linestart" "$cur - 2 chars"
	set cur [$w index "$cur + $length char"]
    }
    
}

set SpinTypes {
    {{FastSpin files}   {.bas .bi .c .cc .cpp .h .spin2 .spin .spinh} }
    {{Interpreter files}   {.py .lsp .fth} }
    {{C/C++ files}   {.c .cpp .cxx .cc .h .hh .hpp} }
    {{All files}    *}
}

set BinTypes {
    {{Binary files}   {.binary .bin .bin2} }
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
	if { $answer eq "yes" } {
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

    if { [winfo exists .pb] } {
	raise .pb
    } else {
	do_pb_create
	wm title .pb "Library Paths"
    }
}

# proc retrieve the library list
proc updateLibraryList {} {
    global config
    if { [winfo exists .pb] } {
	set config(liblist) [.pb.pathbox get 0 end]
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
    setHighlightingForFile $w.txt ""
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
    global CTRL_PREFIX
    frame $w
    set yscmd "$w.v set"
    set xscmd "$w.h set"
    set yvcmd "$w.txt yview"
    set xvcmd "$w.txt xview"
    set searchcmd "searchrep $w.txt 0"
    set replacecmd "searchrep $w.txt 1"

    ctext $w.txt -wrap none -yscrollcommand $yscmd -xscroll $xscmd -tabstyle wordprocessor -linemap $config(showlinenumbers) -undo 1
    scrollbar $w.v -orient vertical -command $yvcmd
    scrollbar $w.h -orient horizontal -command $xvcmd

    grid $w.txt $w.v -sticky nsew
    grid $w.h -sticky nsew
    grid rowconfigure $w $w.txt -weight 1
    grid columnconfigure $w $w.txt -weight 1
    bind $w.txt <$CTRL_PREFIX-f> $searchcmd
    bind $w.txt <$CTRL_PREFIX-k> $replacecmd
    bind $w.txt <Return> {do_indent %W; break}
    
    # for some reason on my linux system the selection doesn't show
    # up correctly
    if { [tk windowingsystem] == "x11" } {
	$w.txt configure -selectbackground blue -selectforeground white
    }
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
    setfont .list.f.txt $config(font)
    loadFileToWindow $filename .list.f.txt
    .list.f.txt yview moveto $viewpos
    wm title .list [file tail $filename]
}

#
# load a file into a toplevel window .help
#
proc loadHelpFile {filename title} {
    global config
    set viewpos 0
    if {[winfo exists .help]} {
	raise .help
	set viewpos [.help.f.txt yview]
	set viewpos [lindex $viewpos 0]
	.help.f.txt configure -state enabled
    } else {
	toplevel .help
	setupFramedText .help.f
	grid columnconfigure .help 0 -weight 1
	grid rowconfigure .help 0 -weight 1
	grid .help.f -sticky nsew
    }
    setfont .help.f.txt $config(font)
    loadFileToWindow $filename .help.f.txt
    .help.f.txt yview moveto $viewpos
    wm title .help [file tail $filename]
    .help.f.txt configure -state disabled
    .help.f.txt configure -linemap 0
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
	setHighlightingForFile $w.txt $filename
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

proc findFileOnPath { filename startdir } {
    global config
    # normalize file name
    if { [file pathtype $filename] != "absolute" } {
	# first check startdir
	set s [file join $startdir $filename]
	if { [file exists $s] } {
	    return [file normalize $s]
	}
	# look for the file name down the include path
	foreach d $config(liblist) {
	    set s [file join $d $filename]
	    if { [file exists $s] } {
		set filename [file normalize $s]
		break
	    }
	}
    }
    return $filename
}

proc loadSourceFile { filename } {
    global filenames

    # sanity check
    if { ![file exists $filename] } {
	tk_messageBox -icon error -type ok -message "$filename\nis not found"
	return
    }
    
    # fetch
    set w [getTabFor $filename]
    if { $w ne "" } {
	.p.nb select $w
    } else {
	set w [.p.nb select]

	if { $w eq "" } {
	    set w [createNewTab]
	} elseif { $filenames($w) ne "" } {
	    set w [createNewTab]
	} else {
	    # check for any data in the window
	    if { [$w.txt edit modified]==1 } {
		set w [createNewTab]
	    }
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

    set filename [tk_getOpenFile -filetypes $SpinTypes -defaultextension $config(spinext) -initialdir $config(lastdir) -title "Open File" ]
    if { [string length $filename] == 0 } {
	return ""
    }
    set config(lastdir) [file dirname $filename]
    set config(spinext) [file extension $filename]
    set BINFILE ""
    
    return [loadSourceFile $filename]
}

proc openLastFiles {} {
    global OPENFILES
    set i 0
    set t $OPENFILES
    set w [lindex $t $i]
    while { $w ne "" } {
	loadSourceFile [file normalize $w]
	set i [expr "$i + 1"]
	set w [lindex $t $i]
    }
}

proc pickFlashProgram {} {
    global config
    global BinTypes
    global ROOTDIR
    
    set filename [tk_getOpenFile -filetypes $BinTypes -initialdir $ROOTDIR/board -title "Select Flash Program"]
    if { [string length $filename] == 0 } {
	return
    }
    set config(flashprogram) $filename
}

# maybe save the current file; used for compilation
# if no changes, then do not save
proc saveFilesForCompile {} {
    global filenames
    global filetimes
    global config
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
		set answer $config(autoreload)
		if { ! $answer  } {
		    set answer [tk_messageBox -icon question -type yesno -message "File $s has changed on disk. Reload it?" -default yes]
		}
		if { $answer } {
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

# save the current file
# returns the file name
proc saveCurFile {} {
    set w [.p.nb select]
    return [saveFile $w]
}

# save the file belonging to window w
# returns the file name or "" if aborted
proc saveFile {w} {
    global filenames
    global filetimes
    global BINFILE
    global SpinTypes
    global config
    
    if { [string length $filenames($w)] == 0 } {
	set filename [tk_getSaveFile -initialfile $filenames($w) -filetypes $SpinTypes -defaultextension $config(spinext) -title "Save File" ]
	if { [string length $filename] == 0 } {
	    return ""
	}
	set config(lastdir) [file dirname $filename]
	set config(spinext) [file extension $filename]
	set filenames($w) $filename
	.p.nb tab $w -text [file root $filename]
	set BINFILE ""
    } else {
	set filename $filenames($w)
    }
    
    saveFileFromWindow $filename $w.txt
    return $filename
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
    set filename [tk_getSaveFile -filetypes $SpinTypes -defaultextension $config(spinext) -initialdir $initdir -initialfile $initfilename -title "Save As" ]
    if { [string length $filename] == 0 } {
	return
    }
    set config(lastdir) [file dirname $filename]
    set config(spinext) [file extension $filename]
    set BINFILE ""
    set filenames($w) $filename
    .p.nb tab $w -text [file tail $filename]
    return [saveFile $w]
}

# get a loadp2 script to send a particular file
proc scriptSendCurFile {} {
    set fname [saveCurFile]
#    if { $fname == "" } {
#	return ""
#    }
    return "-epausems(1500)textfile($fname)"
}
	
# show the about message
proc doAbout {} {
    global aboutMsg
    tk_messageBox -icon info -type ok -message "FlexProp" -detail $aboutMsg
}

proc doHelp { file title } {
    global ROOTDIR
    
    loadHelpFile $file $title
}

proc doSpecial {name extraargs} {
    global ROOTDIR
    global BINFILE
    global PROP_VERSION

    if { $PROP_VERSION eq "P1" } {
	tk_messageBox -icon error -type ok -message "Hardware not supported" -detail "Special features only work on P2 boards"
	return 0
    }
    if { [string equal -length 1 "$name" "-"] } {
	set BINFILE $name
    } else {
	set BINFILE "$ROOTDIR/$name"
    }
    .p.bot.txt delete 1.0 end
    doJustRun "$extraargs"
    return 1
}

#
# click on an error message and find the corresponding line
# parameter is text coordinates like 2.72
#
proc doClickOnError { w coord } {
    global filenames
    
    set first "$coord linestart"
    set last "$coord lineend"
    set linkptr [$w tag prevrange hyperlink $coord]
    set link1 [lindex $linkptr 0]
    set link2 [lindex $linkptr 1]
    set linedata [$w get $link1 $link2]
    set colonptr [string last ":" $linedata]

    #puts "doClickOnError $w $coord"
    #puts "first=|$first|"
    #puts "linkptr=|$linkptr|"
    #puts "linedata=|$linedata|"
    #puts "colonptr=|$colonptr|"

    if { $colonptr == -1 } {
	set fname "$linedata"
	set line ""
    } else {
	set fname [string range $linedata 0 [expr $colonptr - 1]]
	set line [string range $linedata [expr $colonptr + 1] end]
    }
    if { $fname != "" } {
	set startdir $filenames([.p.nb select])
	if { $startdir != "" } {
	    set startdir [file dirname $startdir]
	} else {
	    set startdir [file normalize "."]
	}
	set fname [findFileOnPath $fname $startdir]
	set w [loadSourceFile $fname ]
	if { $w == "" } {
	    return
	}
	set t $w.txt
	$t tag config hilite -background yellow
	# remove hilight
	foreach {from to} [$t tag ranges hilite] {
	    $t tag remove hilite $from $to
	}
	$t tag config hilite -background yellow
	if { $line != "" } {
	    $t see $line.0
	    $t tag add hilite $line.0 $line.end
	}
    }
}

# simpler click function for clicking on a hyperlink in text
# this one can just use the file name we already picked out of
# the surrounding text, no need to parse errors or line numbers

proc doClickOnLink { w coord } {
    global filenames
    
    set first "$coord linestart"
    set last "$coord lineend"
    set linkptr [$w tag prevrange hyperlink $coord]
    set link1 [lindex $linkptr 0]
    set link2 [lindex $linkptr 1]
    set linedata [$w get $link1 $link2]
    #puts "doClickOnLink $w $coord"
    #puts "first=|$first|"
    #puts "linkptr=|$linkptr|"
    #puts "linedata=|$linedata|"

    set fname "$linedata"
    set line ""
    if { $fname != "" } {
	set startdir $filenames([.p.nb select])
	if { $startdir != "" } {
	    set startdir [file dirname $startdir]
	} else {
	    set startdir [file normalize "."]
	}
	set fname [findFileOnPath $fname $startdir]
	set w [loadSourceFile $fname ]
	if { $w == "" } {
	    return
	}
	set t $w.txt
	$t tag config hilite -background yellow
	# remove hilight
	foreach {from to} [$t tag ranges hilite] {
	    $t tag remove hilite $from $to
	}
	$t tag config hilite -background yellow
	if { $line != "" } {
	    $t see $line.0
	    $t tag add hilite $line.0 $line.end
	}
    }    
}

#
# set up syntax highlighting for a given ctext widget
#

set color(comments) grey
set color(keywords) SlateBlue
set color(brackets) green
set color(braces) lawngreen
set color(parens) darkgreen
set color(numbers) DarkRed
set color(operators) green
set color(strings)  red
set color(varnames) black
set color(preprocessor) mediumslateblue
set color(types) purple
set color(hyperlink) blue
		
proc setHighlightingForFile {w fname} {
    global config
    set ext [file extension $fname]
    ctext::clearHighlightClasses $w
    foreach t [$w tag names] {
	$w tag delete $t
    }
    ctext::disableComments $w
    if { $config(syntaxhighlight) } {
	set check1 [lsearch -exact {".c" ".cpp" ".cc" ".h" ".hpp" ".C" ".H"} $ext]
	#puts "fname=$fname ext=$ext check1 = $check1"
	if { $check1 >= 0 } {
	    setSyntaxHighlightingC $w
	} else {
	    set check1 [lsearch -exact {".bas" ".bi" ".BAS" ".Bas"} $ext]
	    if { $check1 >= 0 } {
		setSyntaxHighlightingBasic $w
	    } else {
		setSyntaxHighlightingSpin $w
	    }
	}
    }
    setHyperLinkResponse $w doClickOnLink
    setHighlightingIncludes $w
}

#
# version that just highlights includes
#
proc setHighlightingIncludes {w} {
    global color
    set include1RE {(?:#include\ [^<]*<)([^>]+)}
    set include2RE {(?:#include\ [^\"]*\")([^\"]+)}
    set using1RE {(?:__using\([^\"]*\")([^\"]+)}
    set using2RE {(?:class using[^\"]*\")([^\"]+)}
    set implRE {(?:_IMPL\([^\"]*\")([^\"]+)}

    set fullRE "$include1RE|$include2RE|$implRE|$using1RE|$using2RE"
    ctext::addHighlightClassForRegexp $w hyperlink $color(hyperlink) $fullRE
    $w tag configure hyperlink -underline true
}

#
# C language highlighting
#
proc setSyntaxHighlightingC {w} {
    global color

    $w configure -commentstyle c
    
    ctext::addHighlightClassForSpecialChars $w brackets $color(brackets) {[]}
    ctext::addHighlightClassForSpecialChars $w braces $color(keywords) {{}}
    ctext::addHighlightClassForSpecialChars $w parentheses $color(parens) {()}
    ctext::addHighlightClass $w control $color(keywords) [list namespace while for if else do switch case __asm __pasm typedef]
		
    ctext::addHighlightClass $w types $color(types) [list \
						    int char uint8_t int8_t uint16_t int16_t uint32_t int32_t intptr_t long double float unsigned signed void]
	
    ctext::addHighlightClass $w macros $color(preprocessor) [list \
							      #define #undef #if #ifdef #ifndef #endif #elseif #include #import #exclude]
	
    ctext::addHighlightClassForSpecialChars $w math $color(operators) {+=*-/&^%!|<>}
    ctext::addHighlightClassForRegexp $w strings $color(strings) {\".[^\"]*\"}
    ctext::addHighlightClassForRegexp $w numbers $color(numbers) {(?:[^a-zA-Z0-9_]+)([0-9][0-9a-fA-Fxb_]*)}

    ctext::addHighlightClassForRegexp $w eolcomment $color(comments) {//[^\n\r]*}
							     
    ctext::enableComments $w
    $w tag configure _cComment -foreground $color(comments)
    $w tag raise _cComment
}

#
# Spin language version
#
proc setSyntaxHighlightingSpin {w} {
    global color
    set keywordsbase [list Con Obj Dat Var Pub Pri Quit Exit Repeat While Until If Then Else Return Abort Long Word Byte Asm Endasm String]
    foreach i $keywordsbase {
	lappend keywordsupper [string toupper $i]
    }
    foreach i $keywordsbase {
	lappend keywordslower [string tolower $i]
    }
    set keywords [concat $keywordsbase $keywordsupper $keywordslower]

    $w configure -commentstyle spin
    
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) \$ 
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) \%
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 0
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 1
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 2
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 3
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 4
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 5
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 6
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 7
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 8
    #ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) 9

    ctext::addHighlightClass $w keywords $color(keywords) $keywords

    ctext::addHighlightClassForSpecialChars $w brackets $color(brackets) {[]()}
    ctext::addHighlightClassForSpecialChars $w operators $color(operators) {+-=><!@~\*/&:|}

    ctext::addHighlightClassForRegexp $w strings $color(strings) {\".[^\"]*\"}
    ctext::addHighlightClassForRegexp $w preprocessor $color(preprocessor) {^\#[a-z]+}

    ctext::addHighlightClassForRegexp $w numbers $color(numbers) {(?:[^a-zA-Z0-9_]+)([0-9][0-9_]*)}

    ctext::addHighlightClassForRegexp $w eolcomments $color(comments) {\'[^\n]*}
    ctext::enableComments $w
    $w tag configure _cComment -foreground $color(comments)
    $w tag raise _cComment
}

proc setSyntaxHighlightingBasic {w} {
    global color
    set keywordslower [list as asm byref byval case catch class const continue data declare def defint defsng dim do end endif exit for function gosub goto if let next nil rem return select step sub then throw to try type until using var wend while with]
    set opwordslower [list and andalso mod or orelse not shl shr xor]
    set typewordslower [list any byte double integer long pointer ptr short single ubyte ulong ushort uword word]
    
    foreach i $keywordslower {
	lappend keywordsupper [string toupper $i]
    }
    set keywords [concat $keywordsupper $keywordslower]
    
    foreach i $typewordslower {
	lappend typewordsupper [string toupper $i]
    }
    set typewords [concat $typewordsupper $typewordslower]

    foreach i $opwordslower {
	lappend opwordsupper [string toupper $i]
    }
    set opwords [concat $opwordsupper $opwordslower]

    
    $w configure -commentstyle basic
    
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) \$ 
    ctext::addHighlightClassWithOnlyCharStart $w numbers $color(numbers) \%

    ctext::addHighlightClass $w keywords $color(keywords) $keywords
    ctext::addHighlightClass $w operators $color(operators) $opwords
    ctext::addHighlightClass $w types $color(types) $typewords

    ctext::addHighlightClassForSpecialChars $w brackets $color(brackets) {[]()}
    ctext::addHighlightClassForSpecialChars $w operators $color(operators) {+-=><!@~\*/&:|}

    ctext::addHighlightClassForRegexp $w strings $color(strings) {\".[^\"]*\"}
    ctext::addHighlightClassForRegexp $w preprocessor $color(preprocessor) {^\#[a-z]+}

    ctext::addHighlightClassForRegexp $w numbers $color(numbers) {(?:[^a-zA-Z0-9_]+)([0-9][0-9a-fA-Fxb_]*)}

    ctext::addHighlightClassForRegexp $w eolcomments $color(comments) {\'[^\n]*}
    ctext::addHighlightClassForRegexp $w remcomments $color(comments) {(?:rem\ )([^\n]*)}
}

#
# scan for ports
#
proc rescanPorts { } {
    global comport_last
    global PROP_VERSION
    global EXE
    
    # search for serial ports using serial::listports (src/checkserial.tcl)
    .mbar.comport delete $comport_last end
    .mbar.comport add radiobutton -label "Find port automatically" -variable COMPORT -value " "
    set serlist [serial::listports]
    foreach v $serlist {
	set comname [lrange [split $v "\\"] end end]
	set portval [string map {\\ \\\\} "$v"]
	.mbar.comport add radiobutton -label $comname -variable COMPORT -value "-p $portval"
    }

    # look for WIFI devices
    if { $PROP_VERSION eq "P1" } {
	set wifis [exec -ignorestderr bin/proploader$EXE -W]
	set wifis [split $wifis "\n"]
	foreach v $wifis {
	    set comname "$v"
	    set portval ""
	    set ipstart [string first "IP:" "$v"]
	    #puts "for \[$v\] ipstart=$ipstart"
	    if { $ipstart != -1 } {
		set ipstart [expr $ipstart + 4]
		set ipstring [string range $v $ipstart end]
		set ipend [string first "," "$ipstring"]
		set ipend [expr $ipend - 1]
		#puts "  for <$comname> ipend=<$ipend>"
		if { $ipend >= 0 } {
		    set ipstring [string range $ipstring 0 $ipend]
		    set portval "-i $ipstring"
		    #puts "  -> portval=$portval"
		}
	    }
	    if { $portval ne "" } {
		.mbar.comport add radiobutton -label $comname -variable COMPORT -value "$portval"
	    }
	}
    }
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
menu .mbar.special -tearoff 0
menu .mbar.help -tearoff 0

.mbar add cascade -menu .mbar.file -label File
.mbar.file add command -label "New File" -accelerator "$CTRL_PREFIX-N" -command { createNewTab }
.mbar.file add command -label "Open File..." -accelerator "$CTRL_PREFIX-O" -command { doOpenFile }
.mbar.file add command -label "Save File" -accelerator "$CTRL_PREFIX-S" -command { saveCurFile }
.mbar.file add command -label "Save File As..." -command { saveFileAs [.p.nb select] }
.mbar.file add separator
.mbar.file add command -label "Open listing file" -accelerator "$CTRL_PREFIX-L" -command { doListing }
.mbar.file add separator
.mbar.file add command -label "Library directories..." -command { getLibrary }
.mbar.file add separator
.mbar.file add command -label "Close tab" -accelerator "$CTRL_PREFIX-W" -command { closeTab }
.mbar.file add separator
.mbar.file add command -label Exit -accelerator "$CTRL_PREFIX-Q" -command { exitProgram }

.mbar add cascade -menu .mbar.edit -label Edit
.mbar.edit add command -label "Cut" -accelerator "$CTRL_PREFIX-X" -command {event generate [focus] <<Cut>>}
.mbar.edit add command -label "Copy" -accelerator "$CTRL_PREFIX-C" -command {event generate [focus] <<Copy>>}
.mbar.edit add command -label "Paste" -accelerator "$CTRL_PREFIX-V" -command {event generate [focus] <<Paste>>}
.mbar.edit add separator
.mbar.edit add command -label "Undo" -accelerator "$CTRL_PREFIX-Z" -command {event generate [focus] <<Undo>>}
.mbar.edit add command -label "Redo" -accelerator "$CTRL_PREFIX-Y" -command {event generate [focus] <<Redo>>}
.mbar.edit add separator
.mbar.edit add command -label "Find..." -accelerator "$CTRL_PREFIX-F" -command {searchrep [focus] 0}
.mbar.edit add command -label "Replace..." -accelerator "$CTRL_PREFIX-K" -command {searchrep [focus] 1}

.mbar add cascade -menu .mbar.options -label Options
.mbar.options add radiobutton -label "No Optimization" -variable OPT -value "-O0"
.mbar.options add radiobutton -label "Default Optimization" -variable OPT -value "-O1"
.mbar.options add radiobutton -label "Full Optimization" -variable OPT -value "-O2"
.mbar.options add separator
.mbar.options add radiobutton -label "No extra warnings" -variable WARNFLAGS -value "-Wnone"
.mbar.options add radiobutton -label "Enable compatibility warnings" -variable WARNFLAGS -value "-Wall"
.mbar.options add separator
.mbar.options add radiobutton -label "Debug disabled" -variable DEBUG_OPT -value "-gnone"
.mbar.options add radiobutton -label "Debug enabled" -variable DEBUG_OPT -value "-g"
#.mbar.options add separator
#.mbar.options add radiobutton -label "No Compression" -variable COMPRESS -value "-z0"
#.mbar.options add radiobutton -label "Compress Code" -variable COMPRESS -value "-z1"
.mbar.options add separator
.mbar.options add command -label "Editor Options..." -command { doEditorOptions }


.mbar add cascade -menu .mbar.run -label Commands
.mbar.run add command -label "Compile" -command { doCompile }
.mbar.run add command -label "Run binary on device..." -command { doLoadRun }
.mbar.run add command -label "Compile and run" -accelerator "$CTRL_PREFIX-R" -command { doCompileRun }
.mbar.run add separator
.mbar.run add command -label "Compile and flash" -accelerator "$CTRL_PREFIX-E" -command { doCompileFlash }
.mbar.run add command -label "Flash binary file..." -command { doLoadFlash }
.mbar.run add separator
.mbar.run add command -label "Configure Commands..." -command { doRunOptions }
.mbar.run add command -label "Choose P2 flash program..." -command { pickFlashProgram }

.mbar add cascade -menu .mbar.comport -label Ports
.mbar.comport add radiobutton -label "115200 baud" -variable config(baud) -value 115200
.mbar.comport add radiobutton -label "230400 baud" -variable config(baud) -value 230400
.mbar.comport add radiobutton -label "921600 baud" -variable config(baud) -value 921600
.mbar.comport add radiobutton -label "2000000 baud" -variable config(baud) -value 2000000
.mbar.comport add separator
.mbar.comport add command -label "Scan for ports" -command rescanPorts
.mbar.comport add separator
.mbar.comport add radiobutton -label "Find port automatically" -variable COMPORT -value " "
set comport_last [.mbar.comport index end]

.mbar add cascade -menu .mbar.special -label Special
.mbar.special add separator
.mbar.special add command -label "Enter P2 ROM TAQOZ" -command { doSpecial "-xTAQOZ" "" }
.mbar.special add command -label "Load current buffer into TAQOZ" -command { doSpecial "-xTAQOZ" [scriptSendCurFile] }
.mbar.special add separator
.mbar.special add command -label "Run uPython on P2" -command { doSpecial "samples/upython/upython.binary" "" }
.mbar.special add command -label "Load current buffer into uPython on P2" -command { doSpecial "samples/upython/upython.binary" [scriptSendCurFile] }
.mbar.special add separator
.mbar.special add command -label "Run proplisp on P2" -command { doSpecial "samples/proplisp/lisp.binary" "" }
.mbar.special add command -label "Load current buffer into proplisp on P2" -command { doSpecial "samples/proplisp/lisp.binary" [scriptSendCurFile] }
.mbar.special add separator
.mbar.special add command -label "Enter P2 ROM monitor" -command { doSpecial "-xDEBUG" "" }
.mbar.special add command -label "Terminal only" -command { doSpecial "-n" "-t" }

.mbar add cascade -menu .mbar.help -label Help
.mbar.help add command -label "GUI" -command { doHelp "$ROOTDIR/doc/help.txt" "Help" }
.mbar.help add command -label "General compiler documentation" -command { launchBrowser "file://$ROOTDIR/doc/general.html" }
.mbar.help add command -label "BASIC Language" -command { launchBrowser "file://$ROOTDIR/doc/basic.html" }
.mbar.help add command -label "C Language" -command { launchBrowser "file://$ROOTDIR/doc/c.html" }
.mbar.help add command -label "Spin Language" -command { launchBrowser "file://$ROOTDIR/doc/spin.html" }
.mbar.help add separator
.mbar.help add command -label "About..." -command { doAbout }

wm title . "FlexProp"

panedwindow .p -orient vertical

grid columnconfigure . {0 1} -weight 1
grid rowconfigure . 1 -weight 1
ttk::notebook .p.nb
frame .p.bot
frame .toolbar -bd 1 -relief raised

grid .toolbar -column 0 -row 0 -columnspan 2 -sticky nsew
grid .p -column 0 -row 1 -columnspan 2 -rowspan 1 -sticky nsew

ttk::button .toolbar.compile -text "Compile for P2" -command doCompile
ttk::button .toolbar.runBinary -text "Run Binary" -command doLoadRun
ttk::button .toolbar.compileRun -text "Compile & Run on P2" -command doCompileRun
label  .toolbar.configmsg -text "   Use Commands>Configure Commands... to switch to P1" -font TkSmallCaptionFont

grid .toolbar.compile .toolbar.runBinary .toolbar.compileRun .toolbar.configmsg -sticky nsew

scrollbar .p.bot.v -orient vertical -command {.p.bot.txt yview}
scrollbar .p.bot.h -orient horizontal -command {.p.bot.txt xview}
text .p.bot.txt -wrap none -xscroll {.p.bot.h set} -yscroll {.p.bot.v set} -height 10 -font $config(botfont)
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

bind . <$CTRL_PREFIX-n> { createNewTab }
bind . <$CTRL_PREFIX-o> { doOpenFile }
bind . <$CTRL_PREFIX-s> { saveCurFile }
bind . <$CTRL_PREFIX-b> { browseFile }
bind . <$CTRL_PREFIX-q> { exitProgram }
bind . <$CTRL_PREFIX-r> { doCompileRun }
bind . <$CTRL_PREFIX-e> { doCompileFlash }
bind . <$CTRL_PREFIX-l> { doListing }
bind . <$CTRL_PREFIX-f> { searchrep [focus] 0 }
bind . <$CTRL_PREFIX-k> { searchrep [focus] 1 }
bind . <$CTRL_PREFIX-w> { closeTab }

# bind to right mouse button on Linux and Windows

if {[tk windowingsystem]=="aqua"} {
    bind . <2> "tk_popup .popup1 %X %Y"
    bind . <Control-1> "tk_popup .popup1 %X %Y"
} else {
    bind . <3> "tk_popup .popup1 %X %Y"
}

proc setHyperLinkResponse { w func } {
    set textcurs [::ttk::cursor text]
    set linkcurs [::ttk::cursor link]
    set funcargs { %W "[%W index @%x,%y]"}
    
    $w tag bind hyperlink <Enter> "$w configure -cursor $linkcurs"
    $w tag bind hyperlink <Leave> "$w configure -cursor $textcurs"
    $w tag bind hyperlink <ButtonPress> "$func $funcargs"
}

setHyperLinkResponse .p.bot.txt doClickOnError

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
    set version [info tclversion]
    
    if { $version > 8.5 } {
	tk fontchooser configure -parent . -font "$curfont" -command resetFont
	tk fontchooser show
    } else {
	set fnt [choosefont $curfont "Editor font"]
	if { "$fnt" ne "" } {
	    set config(font) $fnt
	    setnbfonts $fnt
	    .editopts.font.lb configure -font $fnt
	}
    }
}

proc doSelectBottomFont {} {
    global config
    set curfont $config(font)
    set version [info tclversion]
    
    if { $version > 8.5 } {
	tk fontchooser configure -parent . -font "$config(botfont)" -command resetBottomFont
	tk fontchooser show
    } else {
	set fnt [choosefont $curfont "Command output font"]
	if { "$fnt" ne "" } {
	    set config(botfont) $fnt
	    .p.bot.txt configure -font $fnt
	    .editopts.bot.lb configure -font $fnt
	}
    }
}

proc resetFont {w} {
    global config
    set fnt [font actual $w]
    set config(font) $fnt
    setnbfonts $fnt
    .editopts.font.lb configure -font $fnt
}

proc resetBottomFont {w} {
    set fnt [font actual $w]
    set config(botfont) $fnt
    .p.bot.txt configure -font $fnt
    .editopts.bot.lb configure -font $fnt
}

proc doShowLinenumbers {} {
    global config
    set tablist [.p.nb tabs]
    foreach w $tablist {
	$w.txt configure -linemap $config(showlinenumbers)
	ctext::linemapUpdate $w.txt
    }
}

proc resetHighlight {} {
    global config
    global filenames
    set tablist [.p.nb tabs]
    foreach w $tablist {
	set fname [getWindowFile $w]
	setHighlightingForFile $w.txt $fname
	$w.txt highlight 1.0 end
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
proc doEditorOptions {} {
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
    ttk::labelframe .editopts.bot -text "\n Compiler output \n"
    frame .editopts.end

    label .editopts.top.l -text "\n  Editor Options  \n"

    frame .editopts.font.tab
    label  .editopts.font.tab.lab -text " Tab stops: "
    spinbox .editopts.font.tab.stops -text "hello" -from 1 -to 9 -width 2
    .editopts.font.tab.stops set $config(tabwidth)

    label .editopts.font.lb -text " Text font " -font $config(font)
    ttk::button .editopts.font.change -text " Change... " -command doSelectFont
    checkbutton .editopts.font.linenums -text "Show Linenumbers" -variable config(showlinenumbers) -command doShowLinenumbers
    checkbutton .editopts.font.syntax -text "Syntax Highlighting" -variable config(syntaxhighlight) -command resetHighlight
    checkbutton .editopts.font.autoindent -text "Automatic indenting" -variable config(autoindent)
    checkbutton .editopts.font.autoreload -text "Auto Reload Files if changed externally" -variable config(autoreload)
    checkbutton .editopts.font.savewindows -text "Save session on exit" -variable config(savesession)
    ttk::button .editopts.end.ok -text " OK " -command doneAppearance

    label .editopts.bot.lb -text "Compiler output font " -font $config(botfont)
    ttk::button .editopts.bot.change -text " Change... " -command doSelectBottomFont

    grid columnconfigure .editopts 0 -weight 1
    grid rowconfigure .editopts 0 -weight 1
    
    grid .editopts.top -sticky nsew
    grid .editopts.font -sticky nsew
    grid .editopts.bot -sticky nsew
    grid .editopts.end -sticky nsew

    grid .editopts.top.l -sticky nsew 
    grid .editopts.font.tab.lab .editopts.font.tab.stops
    grid .editopts.font.tab
    grid .editopts.font.tab .editopts.font.lb .editopts.font.change
    grid .editopts.font.linenums
    grid .editopts.font.syntax
    grid .editopts.font.autoindent
    grid .editopts.font.autoreload
    grid .editopts.font.savewindows
    grid .editopts.bot.lb .editopts.bot.change
    
    grid .editopts.end.ok -sticky nsew

    wm title .editopts "Editor Options"
}

proc get_includepath {} {
    global config

    updateLibraryList
    set path ""
    set llist $config(liblist)
    foreach i $llist {
	append path "-I \"" $i "\" " 
    }
    return $path
}

# translate % escapes in our command line strings
proc mapPercent {str} {
    global filenames
    global BINFILE
    global ROOTDIR
    global OPT
    global WARNFLAGS
    global DEBUG_OPT
    global COMPRESS
    global COMPORT
    global config

    set ourwarn $WARNFLAGS
    set ourdebug $DEBUG_OPT
    if { "$ourwarn" eq "-Wnone" } {
	set ourwarn ""
    }
    if { "$ourdebug" eq "-gnone" } {
	set ourdebug ""
    }
#    set fulloptions "$OPT $ourwarn $COMPRESS"
    set fulloptions "$OPT $ourwarn $ourdebug"
    if { $COMPORT ne " " } {
	set fullcomport "$COMPORT"
    } else {
	set fullcomport ""
    }
    set bindir [file dirname $BINFILE]
    if { [.p.nb select] ne "" } {
	set srcfile $filenames([.p.nb select])
    } else {
	set srcfile "undefined"
    }
    set percentmap [ list "%%" "%" "%D" $ROOTDIR "%I" [get_includepath] "%L" $config(library) "%S" $srcfile "%B" $BINFILE "%b" $bindir "%O" $fulloptions "%P" $fullcomport "%p" $COMPORT "%F" $config(flashprogram) "%r" $config(baud)]
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

### utility: check for file not found errors in a window
proc fileNotFoundErrors {t} {
    set cur [$t search "Can't open include file" 1.0 end]
    if {$cur eq ""} {
	set cur [$t search "Unable to open file" 1.0 end]
    }
    if {$cur ne ""} {
	return 1
    }
    return 0
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
	if { [fileNotFoundErrors .p.bot.txt] } {
	    tk_messageBox -icon error -type ok -message "Compilation failed" -detail "Some files were not found. Check your library directory."
	} else {
	    tk_messageBox -icon error -type ok -message "Compilation failed" -detail "See compiler output window for details."
	}
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
	# makeReadOnly .list.f.txt # too much trouble
    }
}

proc doJustRunCmd {cmdstr extraargs} {
    if { $extraargs ne "" } {
	set cmdstr [concat "$cmdstr" " " "$extraargs"]
    }
    .p.bot.txt insert end "$cmdstr\n"
    
    set runcmd [list exec -ignorestderr]
    set runcmd [concat $runcmd $cmdstr]
    lappend runcmd "&"

    if {[catch $runcmd errout options]} {
	.p.bot.txt insert 2.0 $errout
	tagerrors .p.bot.txt
    }
}

proc doJustRun {extraargs} {
    global config
    global BINFILE
    
    set cmdstr [mapPercent $config(runcmd)]
    doJustRunCmd $cmdstr $extraargs
}
set flashMsg "
Note that many boards require jumpers or switches
to be set before programming flash and/or
before booting from it.

Please ensure your board is configured for flash
programming.
"

proc doJustFlash {} {
    global config
    global BINFILE
    global flashMsg
    
    set answer [tk_messageBox -icon info -type okcancel -message "Flash Binary" -detail $flashMsg]
    if { $answer eq "ok" } {
	set cmdstr [mapPercent $config(flashcmd)]
	doJustRunCmd $cmdstr ""
    }
}

proc doLoadRun {} {
    global config
    global BINFILE
    global BinTypes
    
    set filename [tk_getOpenFile -filetypes $BinTypes -initialdir $config(lastdir) -title "Run Binary" ]
    if { [string length $filename] == 0 } {
	return
    }
    set BINFILE $filename
    .p.bot.txt delete 1.0 end
    doJustRun ""
}

proc doLoadFlash {} {
    global config
    global BINFILE
    global BinTypes
    
    set filename [tk_getOpenFile -filetypes $BinTypes -initialdir $config(lastdir) -title "Select binary to flash"]
    if { [string length $filename] == 0 } {
	return
    }
    set BINFILE $filename
    .p.bot.txt delete 1.0 end
    doJustFlash
}

proc doCompileRun {} {
    set status [doCompile]
    if { $status eq 0 } {
	.p.bot.txt insert end "\n"
	doJustRun ""
    }
}

proc doCompileFlash {} {
    set status [doCompile]
    if { $status eq 0 } {
	.p.bot.txt insert end "\n"
	doJustFlash
    }
}

set cmddialoghelptext {
  Strings for various commands
  Some special % escapes:
    %B = Replace with current binary file name
    %b = Replace with directory containing current binary file
    %D = Replace with directory of flexprop executable
    %F = Replace with currently selected flash program (sd/flash)
    %I = Replace with all library/include directories
    %O = Replace with optimization level
    %p = Replace with port to use
    %P = Replace with port to use prefixed by -p
    %r = Replace with current baud rate
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
    set shadow(flashcmd) $config(flashcmd)

    if {[winfo exists .runopts]} {
	if {![winfo viewable .runopts]} {
	    wm deiconify .runopts
	}
	raise .runopts
	return
    }

    toplevel .runopts
    label .runopts.toplabel -text $cmddialoghelptext
    
    ttk::labelframe .runopts.a -text "Compile command"
    entry .runopts.a.compiletext -width 40 -textvariable shadow(compilecmd)

    ttk::labelframe .runopts.b -text "Run command"
    entry .runopts.b.runtext -width 40 -textvariable shadow(runcmd)

    ttk::labelframe .runopts.c -text "Flash command"
    entry .runopts.c.flashtext -width 40 -textvariable shadow(flashcmd)

    frame .runopts.change
    frame .runopts.end

    ttk::button .runopts.change.p2a -text "P2a defaults" -command setShadowP2aDefaults
    ttk::button .runopts.change.p2b -text "P2b defaults" -command setShadowP2bDefaults
    ttk::button .runopts.change.p1 -text "P1 defaults" -command setShadowP1Defaults
    
    ttk::button .runopts.end.ok -text " OK " -command {copyShadowClose .runopts}
    ttk::button .runopts.end.cancel -text " Cancel " -command {destroy .runopts}

    grid .runopts.toplabel -sticky nsew
    grid .runopts.a -sticky nsew
    grid .runopts.b -sticky nsew
    grid .runopts.c -sticky nsew
    grid .runopts.change -sticky nsew
    grid .runopts.end -sticky nsew

    grid .runopts.a.compiletext -sticky nsew
    grid .runopts.b.runtext -sticky nsew
    grid .runopts.c.flashtext -sticky nsew

    grid .runopts.change.p2b .runopts.change.p2a .runopts.change.p1 -sticky nsew
    grid .runopts.end.ok .runopts.end.cancel -sticky nsew
    
    grid columnconfigure .runopts.a 0 -weight 1
    grid columnconfigure .runopts.b 0 -weight 1
    grid columnconfigure .runopts.c 0 -weight 1
    grid rowconfigure .runopts 0 -weight 1
    grid columnconfigure .runopts 0 -weight 1
    
    wm title .runopts "Executable Paths"
}

proc do_indent {w} {
    global config
    set extra [string repeat " " $config(tabwidth)]
    if { $config(autoindent) } {
	set lineno [expr {int([$w index insert])}]
	set line [$w get $lineno.0 insert]
	regexp {^(\s*)} $line -> prefix
	if {[string index $line end] eq "\{"} {
	    tk::TextInsert $w "\n$prefix$extra"
	} elseif { [string index $line end] eq "\}" } {
	    set exlen [string length $extra]
	    if { $line eq "$prefix\}" && [string length $line] > $exlen } {
		$w delete insert-[expr $exlen+1]c insert-1c
		tk::TextInsert $w "\n[string range $prefix 0 end-$exlen]"
	    } else {
		tk::TextInsert $w "\n$prefix"
	    }
	} else {
	    tk::TextInsert $w "\n$prefix"
	}
    } else {
	tk::TextInsert $w "\n"
    }
}

#
# simple search and replace widget by Richard Suchenwirth, from wiki.tcl.tk
#
proc searchrep {t {replace 1}} {
   global replacesDone
   set w .sr
   set replacesDone 0 
   if ![winfo exists $w] {
       toplevel $w
       wm title $w "Search"
       grid [label $w.1 -text Find:] [entry $w.f -textvar Find] \
               [ttk::button $w.bn -text Next \
               -command [list searchrep'next $t]] -sticky ew
       bind $w.f <Return> [list $w.bn invoke]
       if $replace {
           grid [label $w.2 -text Replace:] [entry $w.r -textvar Replace] \
                   [ttk::button $w.br -text Replace \
                   -command [list searchrep'rep1 $t]] -sticky ew
           bind $w.r <Return> [list $w.br invoke]
           grid x x [ttk::button $w.ba -text "Replace all" \
                   -command [list searchrep'all $t]] -sticky ew
       }
       grid x [checkbutton $w.i -text "Ignore case" -variable IgnoreCase] \
               [ttk::button $w.c -text Cancel -command "destroy $w"] -sticky ew
       grid $w.i -sticky w
       grid columnconfigure $w 1 -weight 1
       $t tag config hilite -background yellow
       focus $w.f
   } else {
       raise $w.f
       focus $w
       $w.f icursor end
   }
}

# Find the next instance
proc searchrep'next w {
    global replacesDone
    foreach {from to} [$w tag ranges hilite] {
        $w tag remove hilite $from $to
    }
    set cmd [list $w search -forwards -count n -- $::Find insert+2c end]
    if $::IgnoreCase {set cmd [linsert $cmd 2 -nocase]}
    set pos [eval $cmd]
    if {$pos eq ""} {
	if {$replacesDone} {
	    tk_messageBox -icon info -type ok -message "Replaced $replacesDone occurences"
	} else {
	    tk_messageBox -icon info -type ok -message "Not found"
	}
    } else {
        $w mark set insert $pos
        $w see insert
        $w tag add hilite $pos $pos+${n}c
    }
}

# Replace the current instance, and find the next
proc searchrep'rep1 w {
    global replacesDone
    if {[$w tag ranges hilite] ne ""} {
	set replacesDone [expr $replacesDone + 1]
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

# needs to be initialized
set BINFILE ""

# mac os x special code
if { [tk windowingsystem] == "aqua" } {
    proc ::tk::mac::Quit {} {
        exitProgram
    }
}

# main code
if { $::argc > 0 } {
    foreach argx $argv {
        loadSourceFile [file normalize $argx]
    }
} elseif { $config(savesession) && [llength $OPENFILES] } {
    openLastFiles
} else {
    createNewTab
}

rescanPorts

