# Simple GUI for Flexspin
# Copyright 2018-2024 Total Spectrum Software
# Distributed under the terms of the MIT license;
# see License.txt for details.
#

# base name for config file
# change this if an incompatible change to config info is made
set DOT_CONFIG ".flexprop.config.2"
set CONFIG_VERSION 2

#
# The guts of the IDE GUI
#
set aboutMsg "
GUI tool for FlexSpin
Version $spin2gui_version
Copyright 2018-2024 Total Spectrum Software Inc.
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

# prefix for shortcut keys (Command on Mac, Control elsewhere)
if { [tk windowingsystem] == "aqua" } {
    set CTRL_PREFIX "Command"
} else {
    set CTRL_PREFIX "Control"
}

# executable prefix; on Windows .exe is automatically appended, so we don't
# have to explicitly specify it

set EXE ""
if { $tcl_platform(os) == "Darwin" && [file exists "$ROOTDIR/bin/flexspin.mac"] && [file exists "$ROOTDIR/bin/proploader.mac"] } {
    set EXE ".mac"
}

if { [file exists "$ROOTDIR/$DOT_CONFIG"] } {
    # portable installation
    set CONFIGDIR $ROOTDIR
} elseif { [info exists ::env(HOME) ] && [file isdirectory $::env(HOME)] } {    
    set CONFIGDIR $::env(HOME)
} else {
    set CONFIGDIR $ROOTDIR
}

# prefix for starting a command in a window
if { $tcl_platform(platform) == "windows" } {
    set WINPREFIX "cmd.exe /c start \"Propeller Output\""
} elseif { [tk windowingsystem] == "aqua" } {
    set WINPREFIX $ROOTDIR/bin/mac_terminal.sh
} elseif { [file executable /etc/alternatives/x-terminal-emulator] } {
    set WINPREFIX "/etc/alternatives/x-terminal-emulator -T \"Propeller Output\" -e"
} else {
    set WINPREFIX "xterm -fs 14 -T \"Propeller Output\" -e"
}

#
# Create some useful fonts
#
font create InternalTermFont -family Courier -size 10
font create BottomCmdFont -family Courier -size 10

proc resetTerminalFont {w} {
    global config
    set fnt [font actual $w]
    set config(term_font) $fnt
    set cmd [concat [list font configure InternalTermFont] $fnt]
    eval $cmd
}

proc resetBottomFont {w} {
    global config
    set fnt [font actual $w]
    set config(botfont) $fnt
    set cmd [concat [list font configure BottomCmdFont] $fnt]
    eval $cmd
}

# config file name
set CONFIG_FILE "$CONFIGDIR/$DOT_CONFIG"

# default configuration variables
# the config() array is written to the config file and read
# back at run time

set config(library) "$ROOTDIR/include"
set config(liblist) [list $config(library)]
set config(spinext) ".spin"
set config(lastdir) [pwd]
set config(font) "TkFixedFont"
set config(botfont) "courier 10"
set config(term_font) "TkFixedFont"
set config(term_w) 79
set config(term_h) 24
set config(sash) ""
set config(tabwidth) 8
set config(autoreload) 1
set config(internal_term) "ansi"
set config(reset) "dtr"
set COMPORT " "
set OPT "-O1"
set COMPRESS "-z0"
set WARNFLAGS "-Wnone"
set FIXEDREAL "--floatreal"
set DEBUG_OPT "-gnone"
set CHARSET "utf8"
set PROP_VERSION ""
set OPENFILES ""
set curProj ""
set config(showlinenumbers) 1
set config(savesession) 1
set config(syntaxhighlight) 1
set config(autoindent) 1

# saved IP configuration
#set savedips [ list [list "localhost" "127.0.0.1" ] ]
set config(savedips) [ list ]

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

# return the current file name to use for output and building
proc currentFile { } {
    global filenames
    global curProj

    if { "$curProj" ne "" } {
	return $curProj
    }
    return $filenames([.p.nb select])
}

# provide some default settings
proc setShadowP1Defaults {} {
    global shadow
    global ROOTDIR
    global EXE
    
    set shadow(serialcmd) "\"%D/bin/proploader$EXE\" -k -D baud-rate=%r %P \"%B\" -r %9 -q"
    set shadow(wificmd) "\"%D/bin/proploader$EXE\" -k -D baud-rate=%r %P \"%B\" -r %9 -q"
    set shadow(flashcmd) "\"%D/bin/proploader$EXE\" -k -D baud-rate=%r %P \"%B\" -e"
    set shadow(compilecmd) "\"%D/bin/flexspin$EXE\" --tabs=%t -D_BAUD=%r -l %O %I \"%S\""
    set shadow(baud) 115200
}
# provide some default settings
proc setShadowP1BytecodeDefaults {} {
    global shadow
    global ROOTDIR
    global EXE
    global config

    # set up normal defaults
    setShadowP1Defaults

    # override compile command
    set shadow(compilecmd) "\"%D/bin/flexspin$EXE\" --interp=rom --tabs=%t -D_BAUD=%r -l %O %I \"%S\""
}

#
# old flash commands that we should override if we see them
#
set oldconfig_v1(flashcmd) "\"%D/bin/loadp2$EXE\" -k %P -b%r \"@0=%F,@8000+%B\" -t"

proc setShadowP2Defaults {} {
    global shadow
    global ROOTDIR
    global EXE
    
    set shadow(compilecmd) "\"%D/bin/flexspin$EXE\" -2 -l --tabs=%t -D_BAUD=%r %O %I \"%S\""
    set shadow(serialcmd) "\"%D/bin/loadp2$EXE\" -k %P -b%r \"%B\" %9"
    set shadow(wificmd) "\"%D/bin/proploader$EXE\" -k -2 -D baud-rate=%r %P \"%B\" -r %9 -q"
    set shadow(flashcmd) "\"%D/bin/loadp2$EXE\" -SPI -k %P -b%r \"%B\" -t"
    set shadow(flashprogram) "$ROOTDIR/board/P2ES_flashloader.bin"
    set shadow(baud) 230400
}
proc setShadowP2aDefaults {} {
    global shadow
    global ROOTDIR
    global EXE

    # set up regular defaults
    setShadowP2Defaults

    # and adjust for P2 rev A defaults
    set shadow(compilecmd) "\"%D/bin/flexspin$EXE\" -2a -l --tabs=%t -D_BAUD=%r %O %I \"%S\""
}
proc setShadowP2NuDefaults {} {
    global config
    global shadow
    global ROOTDIR
    global EXE

    # set up regular defaults
    setShadowP2Defaults

    # and adjust for nucode compilation
    set shadow(compilecmd) "\"%D/bin/flexspin$EXE\" -2nu -l --tabs=%t -D_BAUD=%r %O %I \"%S\""
}
proc copyShadowToConfig {} {
    global config
    global shadow
    set config(compilecmd) $shadow(compilecmd)
    set config(serialcmd) $shadow(serialcmd)
    set config(wificmd) $shadow(wificmd)
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
    } elseif {[string first " -2nu" $config(compilecmd)] != -1} {
	set PROP_VERSION "P2 ByteCode"
    } elseif {[string first " -2" $config(compilecmd)] != -1} {
	set PROP_VERSION "P2"
    } elseif {[string first " --interp=rom" $config(compilecmd)] != -1} {
	set PROP_VERSION "P1 ByteCode"
    } else {
	set PROP_VERSION "P1"
    }
    if { [winfo exists .toolbar] } {
	.toolbar.compile configure -text "Compile for $PROP_VERSION"
	.toolbar.compileRun configure -text "Compile & Run on $PROP_VERSION"
	.toolbar.configmsg configure -text "    Use Commands>Configure Commands... to switch targets"
    }
}

setShadowP2Defaults
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
    global FIXEDREAL
    global DEBUG_OPT
    global COMPORT
    global CHARSET
    global OPENFILES
    global oldconfig_v1
    
    if {[file exists $CONFIG_FILE]} {
	set fp [open $CONFIG_FILE r]
    } else {
	checkPropVersion
	return 0
    }

    set config_version 0
    
    # read config values
    while {![eof $fp]} {
	set data [gets $fp]
	set nm [lindex $data 0]
	set val [lindex $data 1]
	switch $nm {
	    \# {
		# ignore the comment
	    }
	    version {
		set config_version $val
	    }
	    geometry {
		# restore last position on screen
		wm geometry [winfo toplevel .] $val
	    }
	    opt {
		# set optimize level
		set OPT $val
	    }
	    compress {
		# set compression level
		set COMPRESS $val
	    }
	    warnflags {
		# set warning flags
		set WARNFLAGS $val
	    }
	    runtime_charset {
		# set warning flags
		set CHARSET $val
		if { [string equal -length 10 $CHARSET "--charset="] } {
		    set CHARSET [string range $CHARSET 10 end]
		}
	    }
	    fixedreal {
		# set warning flags
		set FIXEDREAL $val
	    }
	    debugopt {
		# set warning flags
		set DEBUG_OPT $val
	    }
	    comport {
		# set default port level
		set COMPORT $val
		# convert old COMPORT entries
		if { $COMPORT ne " " && [string index "$COMPORT" 0] ne "-" } {
		    set COMPORT "-p $COMPORT"
		}
	    }
	    openfiles {
		# record open files
		set OPENFILES $val
	    }
	    default {
		if { $config_version < 1 && [info exists oldconfig_v1($nm)] } {
		    if { $oldconfig_v1($nm) ne $val } {
			set config($nm) $val
		    }
		} else {
		    set config($nm) $val
		}
	    }
	}
    }
    close $fp
    checkPropVersion

    # some sanity checks
    if { "$config(font)" eq "" } {
	set config(font) "TkFixedFont"
    }
    if { "$config(botfont)" eq "" } {
	set config(botfont) "TkFixedFont"
    }
    if { "$config(term_font)" eq "" } {
	set config(term_font) "TkFixedFont"
    }
    if { "$config(internal_term)" eq "1" } {
	set config(internal_term) "pst"
    }

    resetTerminalFont $config(term_font)
    resetBottomFont $config(botfont)
    return 1
}

proc config_save {} {
    global config
    global CONFIG_FILE
    global OPT
    global COMPRESS
    global WARNFLAGS
    global FIXEDREAL
    global DEBUG_OPT
    global COMPORT
    global OPENFILES
    global CHARSET
    global CONFIG_VERSION
    
    updateLibraryList
    updateOpenFiles
    set config(sash) [.p sash coord 0]
    set fp [open $CONFIG_FILE w]
    puts $fp "# flexprop config info"
    puts $fp "version\t$CONFIG_VERSION"
    puts $fp "geometry\t[winfo geometry [winfo toplevel .]]"
    puts $fp "opt\t\{$OPT\}"
    puts $fp "compress\t\{$COMPRESS\}"
    puts $fp "comport\t\{$COMPORT\}"
    puts $fp "openfiles\t\{$OPENFILES\}"
    puts $fp "warnflags\t\{$WARNFLAGS\}"
    puts $fp "fixedreal\t\{$FIXEDREAL\}"
    puts $fp "debugopt\t\{$DEBUG_OPT\}"
    puts $fp "runtime_charset\t\{$CHARSET\}"
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
    catch {
	checkAllChanges
	config_save
    } errMsg
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
    global curProj
    
    set w [.p.nb select]
    if { $w ne "" } {
	checkChanges $w
	if { "$filenames($w)" eq "$curProj" } {
	    set curProj ""
	}
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
    $win edit reset
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
	    set filetimes($fname) $disktime
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
    {{FlexSpin files}   {.bas .bi .c .cc .cpp .h .spin2 .spin .spinh .side .fpide} }
    {{Interpreter files}   {.py .lsp .fth} }
    {{C/C++ files}   {.c .cpp .cxx .cc .h .hh .hpp} }
    {{Project files} {.fpide .side} }
    {{All files}    *}
}

set BinTypes {
    {{Binary files}   {.binary .bin .bin2 .elf} }
    {{All files}    *}
}

#
# see if anything has changed in window w
#
proc checkChanges {w} {
    global filenames
    set s $filenames($w)
    # if these lines are left in then new files
    # get closed without checking... not good
    #if { $s eq "" } {
    #	return
    #}
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

# "tabs" here are tabs in the main editor window
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
    global tabEnterScript
    global tabLeaveScript
    set w [newTabName]
    
    #.p.bot.txt delete 1.0 end
    set filenames($w) ""
    setupFramedText $w
    setHighlightingForFile $w.txt ""
    setfont $w.txt $config(font)
    .p.nb add $w
    .p.nb tab $w -text "New File"
    
    .p.nb select $w

    bind $w <Enter> $tabLeaveScript
    bind $w <Leave> $tabEnterScript
    
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
    ttk::scrollbar $w.v -orient vertical -command $yvcmd
    ttk::scrollbar $w.h -orient horizontal -command $xvcmd

    grid $w.txt $w.v -sticky nsew
    grid $w.h -sticky nsew
    grid rowconfigure $w $w.txt -weight 1
    grid columnconfigure $w $w.txt -weight 1

    bind $w.txt <$CTRL_PREFIX-f> $searchcmd
    bind $w.txt <$CTRL_PREFIX-k> $replacecmd
    bind $w.txt <$CTRL_PREFIX-z> {
	event generate [focus] <<Undo>>
	break
    }
    bind $w.txt <$CTRL_PREFIX-y> {
	event generate [focus] <<Redo>>
	break
    }

    
    bind $w.txt <Return> {do_indent %W; break}
    
    # for some reason on my linux system the selection doesn't show
    # up correctly
    if { [tk windowingsystem] == "x11" } {
	$w.txt configure -selectbackground blue -selectforeground white
    }

    # bind popup menu to right mouse button on Linux and Windows

    if {[tk windowingsystem]=="aqua"} {
	bind $w.txt <2> "tk_popup .popup1 %X %Y"
	bind $w.txt <Control-1> "tk_popup .popup1 %X %Y"
    } else {
	bind $w.txt <3> "tk_popup .popup1 %X %Y"
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
    .help.f.txt configure -wrap word
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

proc loadSourceFile { filename doCreate } {
    global filenames
    global curProj
    
    # sanity check
    if { ![file exists $filename] } {
	# if the link was clicked from a .fpide file, we want to create the file
	if { $doCreate } {
	    set ext [file extension $filename]
	    set fp [open $filename w]
	    puts $fp ""
	    close $fp
	} else {
	    tk_messageBox -icon error -type ok -message "$filename\nis not found"
	    return
	}
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
    if { [is_proj_file $filename] } {
	set curProj "$filename"
    }
    return $w
}

proc doOpenFile {} {
    global config
    global SpinTypes
    global BINFILE
    global curProj
    
    set filename [tk_getOpenFile -filetypes $SpinTypes -defaultextension $config(spinext) -initialdir $config(lastdir) -title "Open File" ]
    if { [string length $filename] == 0 } {
	return ""
    }
    set config(lastdir) [file dirname $filename]
    set config(spinext) [file extension $filename]
    set BINFILE ""

    return [loadSourceFile "$filename" 0]
}

proc openLastFiles {} {
    global OPENFILES
    set i 0
    set t $OPENFILES
    set w [lindex $t $i]
    while { $w ne "" } {
	loadSourceFile [file normalize $w] 0
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

# check to see if a file has changed externally; if so, re-load it
proc checkFilesForChanges {} {
    global filenames
    global filetimes
    global config

    set t [.p.nb tabs]
    set i 0
    set w [lindex $t $i]
    while { $w ne "" } {
	set s $filenames($w)
	set needRead "no"
	if { $s ne "" } {
	    if { [file exists $s] } {
		set disktime [file mtime $s]
	        if {$disktime > $filetimes($s)} {
		    set needRead "yes"
		}
	    }
	    if { $needRead eq "yes" } {
		set answer $config(autoreload)
		#puts "disktime-$disktime filetime=$filetimes($s)"
		set filetimes($s) $disktime
		if { ! $answer  } {
		    set answer [tk_messageBox -icon question -type yesno -message "File $s has changed on disk. Reload it?" -default yes]
		}
		if { $answer } {
		    loadFileToWindow $s $w.txt
		}
	    }
	}
	incr i
	set w [lindex $t $i]
    }
}

#
# code for handling focus in/out events
# allows us to re-check for modified files
# Only re-check when the whole application loses/gains focus
#
proc checkFocusOut {w} {
    #puts "FocusOut: $w"
}
proc checkFocusIn {w} {
    global config
    #puts "FocusIn: $w"
    if { $w eq "." } {
	if { $config(autoreload) } {
	    checkFilesForChanges
	}
    }
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

proc doGuiHelp { } {
    global ROOTDIR
    set file "$ROOTDIR/doc/help.txt"
    set title "Help"
    loadHelpFile $file $title
}

proc doHelp { name } {
    global ROOTDIR
    set htmlfile "$ROOTDIR/doc/$name.html"
    set mdfile "$ROOTDIR/doc/$name.md"
    if { [file exists $htmlfile] } {
	launchBrowser "file://$htmlfile"
    } else {
	loadHelpFile $mdfile $name
    }
}

proc doIdentify { } {
    global ROOTDIR
    global EXE
    set ports [exec -ignorestderr $ROOTDIR/bin/proploader$EXE -v -P]

    tk_messageBox -icon info -type ok -message "Serial Ports" -detail "$ports"
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
	set startdir [currentFile]
	if { $startdir != "" } {
	    set startdir [file dirname $startdir]
	} else {
	    set startdir [file normalize "."]
	}
	set fname [findFileOnPath $fname $startdir]
	set w [loadSourceFile "$fname" 0]
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
	set startdir [currentFile]
	if { $startdir != "" } {
	    set startdir [file dirname $startdir]
	} else {
	    set startdir [file normalize "."]
	}
	set fname [findFileOnPath $fname $startdir]
	set w [loadSourceFile "$fname" 1]
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
# help for tabs
#
proc tabHelp {w x y} {
    #set sx $x
    #set sy $y
    set sx [expr [winfo pointerx $w]-[winfo rootx .p.nb]]
    set sy [expr [winfo pointery $w]-[winfo rooty .p.nb]]
    set t [.p.nb identify tab $sx $sy]
    global filenames
    if {$t ne ""} then {
	set alltabs [.p.nb tabs]
	set msg1 [.p.nb tab $t -text]
	set msg2 [getWindowFile [lindex $alltabs $t]]
	#set msg "$msg1: $msg2"
	set msg "$msg2"
	showBalloonHelp $w $msg
    } else {
	destroy .balloonHelp
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
    if { [is_proj_file $fname] } {
	setHighlightingSide $w
    } elseif { $config(syntaxhighlight) } {
	if { [is_c_file $fname] } {
	    setSyntaxHighlightingC $w
	} else {
	    if { [is_basic_file $fname] } {
		setSyntaxHighlightingBasic $w
	    } else {
		setSyntaxHighlightingSpin $w
	    }
	}
	setHighlightingIncludes $w
    }
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
    setHyperLinkResponse $w doClickOnLink
    ctext::addHighlightClassForRegexp $w hyperlink $color(hyperlink) $fullRE
    $w tag configure hyperlink -underline true
}

#
# project file (.side) highlighting
#
proc setHighlightingSide {w} {
    global color

#    set fullRE {^([^\->#]+)}
    set fullRE {^([^\->#].*)}
    setHyperLinkResponse $w doClickOnLink
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
	lappend keywordsupper [string totitle $i]
    }
    set keywords [concat $keywordsupper $keywordslower]
    
    foreach i $typewordslower {
	lappend typewordsupper [string toupper $i]
	lappend typewordsupper [string totitle $i]
    }
    set typewords [concat $typewordsupper $typewordslower]

    foreach i $opwordslower {
	lappend opwordsupper [string toupper $i]
	lappend opwordsupper [string totitle $i]
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
    global config
    global ROOTDIR
    set iplist $config(savedips)
    
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
    #if { $PROP_VERSION eq "P1" } {
	set wifis [exec -ignorestderr $ROOTDIR/bin/proploader$EXE -W]
	set wifis [split $wifis "\n"]
	foreach v $wifis {
	    set comname "$v"
	    set portval ""
	    set ipstart [string first "IP:" "$v"]
	    #puts "for \[$v\] ipstart=$ipstart"
	    if { $ipstart != -1 } {
		set comname [string range $v 0 [expr {$ipstart - 1}]]
		set ipstart [expr $ipstart + 4]
		set ipstring [string range $v $ipstart end]
		set ipend [string first "," "$ipstring"]
		set ipend [expr $ipend - 1]
		#puts "  for <$comname> ipend=<$ipend>"
		if { $ipend >= 0 } {
		    set ipstring [string range $ipstring 0 $ipend]
		    set portval "$ipstring"
		    #puts "  -> portval=$portval"
		}
	    }
	    if { $portval ne "" } {
		lappend iplist [list $comname $portval]
	    }
	}
    #}

    # Now add in any explicitly configured IP addresses
    if { [llength $iplist] != 0 } {
	    .mbar.comport add separator
    }
    foreach v $iplist {
	set name [lindex $v 0]
	set portval [lindex $v 1]
	set comname "$name ($portval)"
	set portval "-i $portval"
	.mbar.comport add radiobutton -label $comname -variable COMPORT -value "$portval"
    }
}

# actually read in our config info
config_open

# now set up the menus and widgets
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
.mbar.file add command -label "New Project..." -command { createNewProject 0 }
.mbar.file add command -label "Create Project From Files..." -command { createNewProject 1 }
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
menu .mbar.options.opt
.mbar.options add cascade -menu .mbar.options.opt -label "Optimization"
.mbar.options.opt add radiobutton -label "No Optimization" -variable OPT -value "-O0"
.mbar.options.opt add radiobutton -label "Default Optimization" -variable OPT -value "-O1"
.mbar.options.opt add radiobutton -label "Size Optimization" -variable OPT -value "-Os"
.mbar.options.opt add radiobutton -label "Full Optimization" -variable OPT -value "-O2"

menu .mbar.options.warn
.mbar.options add cascade -menu .mbar.options.warn -label "Warnings"
.mbar.options.warn add radiobutton -label "No extra warnings" -variable WARNFLAGS -value "-Wnone"
.mbar.options.warn add radiobutton -label "Enable compatibility warnings" -variable WARNFLAGS -value "-Wall"

menu .mbar.options.float
.mbar.options add cascade -menu .mbar.options.float -label "Floating Point"
.mbar.options.float add radiobutton -label "Use IEEE floating point" -variable FIXEDREAL -value "--floatreal"
.mbar.options.float add radiobutton -label "Use 16.16 fixed point in place of floats" -variable FIXEDREAL -value "--fixedreal"

menu .mbar.options.charset
.mbar.options add cascade -menu .mbar.options.charset -label "Runtime character set"
.mbar.options.charset add radiobutton -label "UTF-8 (Unicode)" -variable CHARSET -value "utf8"
.mbar.options.charset add radiobutton -label "Latin-1" -variable CHARSET -value "latin1"
.mbar.options.charset add radiobutton -label "Parallax OEM" -variable CHARSET -value "parallax"
.mbar.options.charset add radiobutton -label "Shift-JIS" -variable CHARSET -value "shiftjis"

.mbar.options add separator
.mbar.options add command -label "Editor Options..." -command { doEditorOptions }
.mbar.options add separator

.mbar.options add radiobutton -label "Debug disabled" -variable DEBUG_OPT -value "-gnone"
.mbar.options add radiobutton -label "Print debug" -variable DEBUG_OPT -value "-g"
.mbar.options add radiobutton -label "BRK debug (P2 only)" -variable DEBUG_OPT -value "-gbrk"
#.mbar.options add separator
#.mbar.options add radiobutton -label "No Compression" -variable COMPRESS -value "-z0"
#.mbar.options add radiobutton -label "Compress Code" -variable COMPRESS -value "-z1"
.mbar.options add separator
.mbar.options add radiobutton -label "Use internal PST terminal" -variable config(internal_term) -value "pst"
.mbar.options add radiobutton -label "Use internal ANSI terminal" -variable config(internal_term) -value "ansi"
.mbar.options add radiobutton -label "Use external terminal" -variable config(internal_term) -value "0"
.mbar.options add radiobutton -label "No terminal" -variable config(internal_term) -value "none"


.mbar add cascade -menu .mbar.run -label Commands
.mbar.run add command -label "Compile" -command { doCompile }
.mbar.run add command -label "Run binary on device..." -command { doLoadRun }
.mbar.run add command -label "Compile and run" -accelerator "$CTRL_PREFIX-R" -command { doCompileRun }
.mbar.run add separator
.mbar.run add command -label "Compile and flash" -accelerator "$CTRL_PREFIX-E" -command { doCompileFlash }
.mbar.run add command -label "Flash binary file..." -command { doLoadFlash }
.mbar.run add separator
.mbar.run add command -label "Create zip archive" -command { doCreateZip }
.mbar.run add separator
.mbar.run add command -label "Configure Commands..." -command { doRunOptions }
.mbar.run add command -label "Choose P2 flash program..." -command { pickFlashProgram }

.mbar add cascade -menu .mbar.comport -label Ports
menu .mbar.comport.baud
.mbar.comport add cascade -menu .mbar.comport.baud -label "Baud"
.mbar.comport.baud add radiobutton -label "115200 baud" -variable config(baud) -value 115200
.mbar.comport.baud add radiobutton -label "230400 baud" -variable config(baud) -value 230400
.mbar.comport.baud add radiobutton -label "921600 baud" -variable config(baud) -value 921600
.mbar.comport.baud add radiobutton -label "2000000 baud" -variable config(baud) -value 2000000
#.mbar.comport add separator
#.mbar.comport add radiobutton -label "Use DTR for reset" -variable config(reset) -value "dtr"
#.mbar.comport add radiobutton -label "Use RTS for reset" -variable config(reset) -value "rts"
#.mbar.comport add separator
.mbar.comport add command -label "Scan for ports" -command rescanPorts
.mbar.comport add command -label "Add IP address..." -command { ::IpEntry::addIpAddress rescanPorts }
.mbar.comport add separator
.mbar.comport add radiobutton -label "Find port automatically" -variable COMPORT -value " "
set comport_last [.mbar.comport index end]

.mbar add cascade -menu .mbar.special -label Special
.mbar.special add separator
.mbar.special add command -label "Enter P2 ROM TAQOZ" -command { doSpecial "-xTAQOZ" "" }
.mbar.special add command -label "Load current buffer into TAQOZ" -command { doSpecial "-xTAQOZ" [scriptSendCurFile] }
.mbar.special add separator
#.mbar.special add command -label "Command shell for P2" -command { doSpecial "samples/shell/shell.binary" "" }
#.mbar.special add command -label "Load current buffer into uPython on P2" -command { doSpecial "samples/upython/upython.binary" [scriptSendCurFile] }
.mbar.special add separator
.mbar.special add command -label "Run proplisp on P2" -command { doSpecial "samples/proplisp/lisp.binary" "" }
.mbar.special add command -label "Load current buffer into proplisp on P2" -command { doSpecial "samples/proplisp/lisp.binary" [scriptSendCurFile] }
.mbar.special add separator
.mbar.special add command -label "Enter P2 ROM monitor" -command { doSpecial "-xDEBUG" "" }
.mbar.special add command -label "Terminal only" -command { doSpecial "-xTERM" "-t" }
.mbar.special add separator
.mbar.special add command -label "Identify Serial Ports" -command doIdentify

.mbar add cascade -menu .mbar.help -label Help
.mbar.help add command -label "GUI" -command { doGuiHelp }
.mbar.help add command -label "General compiler documentation" -command { doHelp "general" }
.mbar.help add command -label "BASIC Language" -command { doHelp "basic" }
.mbar.help add command -label "C Language" -command { doHelp "c" }
.mbar.help add command -label "Spin Language" -command { doHelp "spin" }
.mbar.help add separator
.mbar.help add command -label "Parallax P1 documentation" -command { launchBrowser "https://www.parallax.com/download/propeller-1-documentation/" }
.mbar.help add command -label "Parallax P2 documentation" -command { launchBrowser "https://www.parallax.com/propeller-2/documentation" }
.mbar.help add command -label "IRQsoft P2 documentation" -command { launchBrowser "https://p2docs.github.io" }
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
label  .toolbar.configmsg -text "   Use Commands>Configure Commands... to switch targets" -font TkSmallCaptionFont
checkPropVersion

grid .toolbar.compile .toolbar.runBinary .toolbar.compileRun .toolbar.configmsg -sticky nsew

ttk::scrollbar .p.bot.v -orient vertical -command {.p.bot.txt yview}
ttk::scrollbar .p.bot.h -orient horizontal -command {.p.bot.txt xview}
text .p.bot.txt -wrap none -xscroll {.p.bot.h set} -yscroll {.p.bot.v set} -height 10 -font BottomCmdFont
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
#bind . <$CTRL_PREFIX-f> { searchrep [focus] 0 } # done in setupFramedText
#bind . <$CTRL_PREFIX-k> { searchrep [focus] 1 }
bind . <$CTRL_PREFIX-w> { closeTab }

set toolTipScript [list tabHelp %W %x %y]
set tabEnterScript [list after 1000 $toolTipScript]
set tabLeaveScript [list after cancel $toolTipScript]
append tabLeaveScript \n [list after 200 [list destroy .balloonHelp]]

bind .p.nb <Enter> $tabEnterScript
bind .p.nb <Leave> $tabLeaveScript

proc NotebookChanged {} {
    set idx [.p.nb index current]
    set win [lindex [.p.nb tabs] $idx]
    raise $win
}

if { [tk windowingsystem] == "aqua" } {
    bind .p.nb <<NotebookTabChanged>> NotebookChanged
}

bind . <FocusIn> { checkFocusIn %W }
bind . <FocusOut> { checkFocusOut %W }

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
    set curfont $config(botfont)
    set version [info tclversion]
    
    if { $version > 8.5 } {
	tk fontchooser configure -parent . -font "$config(botfont)" -command resetBottomFont
	tk fontchooser show
    } else {
	set fnt [choosefont $curfont "Command output font"]
	if { "$fnt" ne "" } {
	    resetBottomFont $fnt
	}
    }
}

proc doSelectTerminalFont {} {
    global config
    set curfont $config(term_font)
    set version [info tclversion]
    
    if { $version > 8.5 } {
	tk fontchooser configure -parent . -font "$config(term_font)" -command resetTerminalFont
	tk fontchooser show
    } else {
	set fnt [choosefont $curfont "Command output font"]
	if { "$fnt" ne "" } {
	    set config(term_font) $fnt
#	    .editopts.term.lb configure -font $fnt
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
    ttk::labelframe .editopts.bot -text "\n Compiler output"
    ttk::labelframe .editopts.term -text "\n Terminal Options"
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

    label .editopts.bot.lb -text "Compiler output font " -font BottomCmdFont
    ttk::button .editopts.bot.change -text " Change... " -command doSelectBottomFont

    label .editopts.term.lb -text "Terminal font " -font InternalTermFont
    ttk::button .editopts.term.change -text " Change... " -command doSelectTerminalFont

    grid columnconfigure .editopts 0 -weight 1
    grid rowconfigure .editopts 0 -weight 1
    
    grid .editopts.top -sticky nsew
    grid .editopts.font -sticky nsew
    grid .editopts.bot -sticky nsew
    grid .editopts.term -sticky nsew
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
    grid .editopts.term.lb .editopts.term.change
    
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
proc mapPercentEx {str extraOpts} {
    global filenames
    global BINFILE
    global ROOTDIR
    global OPT
    global WARNFLAGS
    global CHARSET
    global FIXEDREAL
    global DEBUG_OPT
    global COMPRESS
    global COMPORT
    global WINPREFIX
    global config
    global curProj
    
    set ourwarn $WARNFLAGS
    set ourdebug $DEBUG_OPT
    set ourfixed $FIXEDREAL

    if { "$CHARSET" ne "" } {
	set ourcharset "--charset=$CHARSET"
    } else {
	set ourcharset ""
    }
    #set runprefix "$WINPREFIX "
    set runprefix ""
    
    if { "$ourwarn" eq "-Wnone" } {
	set ourwarn ""
    }
    if { "$ourdebug" eq "-gnone" } {
	set ourdebug ""
    }
    if { "$ourfixed" eq "--floatreal" } {
	set ourfixed ""
    }
    
    #    set fulloptions "$OPT $ourwarn $COMPRESS"
    if { "$extraOpts" ne "" } {
	set fulloptions "$extraOpts"
    } else {
	set fulloptions "$OPT $ourwarn $ourdebug $ourfixed $ourcharset"
    }
    if { $COMPORT ne " " } {
	set fullcomport "$COMPORT"
    } else {
	set fullcomport ""
    }
    set bindir [file dirname $BINFILE]
    set srcfile [currentFile]
    set fileServer "\"-9$bindir\""
    set percentmap [ list "%%" "%" "%#" $runprefix "%D" $ROOTDIR "%I" [get_includepath] "%L" $config(library) "%S" $srcfile "%B" $BINFILE "%b" $bindir "%O" $fulloptions "%P" $fullcomport "%F" $config(flashprogram) "%r" $config(baud) "%t" $config(tabwidth) "%9" $fileServer]
    set result [string map $percentmap $str]
    return $result
}

proc mapPercent {str} {
    return [mapPercentEx "$str" ""]
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
    global curProj
    
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
	set BINFILE [file rootname [currentFile]]
	set BINFILE "$BINFILE.binary"
	# load the listing if a listing window is open
	if {[winfo exists .list]} {
	    doListing
	}
    }
    return $status
}

### utility: create a Zip file

proc doCreateZip {} {
    global config
    global BINFILE
    global filenames
    
    set status 0
    clearAllSearchTags
    saveFilesForCompile
    set cmdstr [mapPercentEx $config(compilecmd) "--zip"]
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
	set BINFILE [file rootname [currentFile]]
	set BINFILE "$BINFILE.binary"
	# load the listing if a listing window is open
	if {[winfo exists .list]} {
	    doListing
	}
    }
    return $status
}

# open a listing file

proc doListing {} {
    global filenames
    set w [.p.nb select]
    if { $w ne "" } {
	set LSTFILE [file rootname [currentFile]]
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
    global WINPREFIX
    global COMPORT
    
    if { [string first "-i " $COMPORT] != -1 } {
	set PORT_IS_WIFI 1
    } else {
	set PORT_IS_WIFI 0
    }
    if { $PORT_IS_WIFI } {
	set runConfig $config(wificmd)
    } else {
	set runConfig $config(serialcmd)
    }

    if { $config(internal_term) eq "none" } {
	# remove the -9 option, no terminal I/O available
	#puts "orig ($runConfig)"
	set runConfig [string map { " %9" "" " -k" "" } $runConfig]
	#puts "new ($runConfig)"
    }
    set cmdstr [mapPercent $runConfig]
    
    if { $extraargs ne "" } {
	set cmdstr [concat "$cmdstr" " " "$extraargs"]
    }
    if { $config(internal_term) eq "none" } {
	set runcmd [list exec -ignorestderr]
	set runcmd [concat $runcmd $cmdstr]
	lappend runcmd 2>@1
	#puts "External Running: $runcmd"
	if {[catch $runcmd errout options]} {
	    set status 1
	}
    } elseif { $config(internal_term) ne "0" } {
	#puts "Internal Running: $runcmd"
	::TkTerm::RunInWindow $cmdstr
    } else {
	set runcmd [list exec -ignorestderr]
	set cmdstr [concat $WINPREFIX $cmdstr]
	set runcmd [concat $runcmd $cmdstr]
	lappend runcmd 2>@1
	#puts "External Running: $runcmd"
	if {[catch $runcmd errout options]} {
	    set status 1
	}
    }
}

set flashMsg "
Note that many boards require jumpers or switches \
to be set before programming flash and/or \
before booting from it. \n\
\n\
Please ensure your board is configured for flash \
programming.
"

proc doJustFlash {} {
    global config
    global BINFILE
    global flashMsg
    global WINPREFIX
    global COMPORT
    global PROP_VERSION

    set flashcmd $config(flashcmd)
    
    if { [string first "-i " $COMPORT] != -1 } {
	set PORT_IS_WIFI 1
    } else {
	set PORT_IS_WIFI 0
    }
    if { $PORT_IS_WIFI } {
	if { $PROP_VERSION ne "P1" } {
	    set answer [tk_messageBox -icon warning -type okcancel -default cancel -message "Flashing over Wifi is not supported on P2"]
	    if { $answer ne "ok" } {
		return
	    }
	    if { [string first "loadp2" $flashcmd]  != -1 } {
		set flashcmd "\"%D/bin/proploader$EXE\" -2 -k -D baud-rate=%r %P \"%B\" -e"
	    }
	}
    }
    set answer [tk_messageBox -icon info -type okcancel -message "Flash Binary" -detail $flashMsg]
    
    if { $answer ne "ok" } {
	return
    }
    set cmdstr [mapPercent $flashcmd]
    if { $config(internal_term) ne "0" } {
	::TkTerm::RunInWindow $cmdstr
    } else {
	set runcmd [list exec -ignorestderr]
	set cmdstr [concat $WINPREFIX $cmdstr]
	set runcmd [concat $runcmd $cmdstr]
	lappend runcmd 2>@1
	if {[catch $runcmd errout options]} {
	    set status 1
	}
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
    %P = Replace with port to use prefixed by -p
    %r = Replace with current baud rate
    %S = Replace with current source file name
    %t = Replace with tab width
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
    set shadow(serialcmd) $config(serialcmd)
    set shadow(wificmd) $config(wificmd)
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

    ttk::labelframe .runopts.b -text "Serial run command"
    entry .runopts.b.runtext -width 40 -textvariable shadow(serialcmd)
    ttk::labelframe .runopts.b2 -text "Wifi run command"
    entry .runopts.b2.wifitext -width 40 -textvariable shadow(wificmd)

    ttk::labelframe .runopts.c -text "Flash command"
    entry .runopts.c.flashtext -width 40 -textvariable shadow(flashcmd)

    frame .runopts.change
    frame .runopts.end

#    ttk::button .runopts.change.p2a -text "P2a defaults" -command setShadowP2aDefaults
    ttk::button .runopts.change.p2b -text "P2 defaults" -command setShadowP2Defaults
    ttk::button .runopts.change.p2nu -text "P2 Bytecode defaults" -command setShadowP2NuDefaults
    ttk::button .runopts.change.p1 -text "P1 defaults" -command setShadowP1Defaults
    ttk::button .runopts.change.p1bc -text "P1 Bytecode defaults" -command setShadowP1BytecodeDefaults
    
    ttk::button .runopts.end.ok -text " OK " -command {copyShadowClose .runopts}
    ttk::button .runopts.end.cancel -text " Cancel " -command {destroy .runopts}

    grid .runopts.toplabel -sticky nsew
    grid .runopts.a -sticky nsew
    grid .runopts.b -sticky nsew
    grid .runopts.b2 -sticky nsew
    grid .runopts.c -sticky nsew
    grid .runopts.change -sticky nsew
    grid .runopts.end -sticky nsew

    grid .runopts.a.compiletext -sticky nsew
    grid .runopts.b.runtext -sticky nsew
    grid .runopts.b2.wifitext -sticky nsew
    grid .runopts.c.flashtext -sticky nsew

    grid .runopts.change.p2b .runopts.change.p2nu .runopts.change.p1 .runopts.change.p1bc -sticky nsew
    grid .runopts.end.ok .runopts.end.cancel -sticky nsew
    
    grid columnconfigure .runopts.a 0 -weight 1
    grid columnconfigure .runopts.b 0 -weight 1
    grid columnconfigure .runopts.b2 0 -weight 1
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

    # if searching on the frame, use the currently selected tab
    if { [string match "*.nb" $t] } {
	set t [$t select]
    }
    #puts "search window: $t"
    # make sure we are doing the search on a .txt
    if { ![string match "*.txt" $t ] } {
	set subw [winfo children $t]
	#puts "subwindows: $subw"
	foreach ch $subw {
	    if { [string match "*.txt" $ch] } {
		set t $ch
		break
	    }
	}
    }
    if { ![string match "*.txt" $t] } {
	# use whatever the currently selected tab is
	set t [.p.nb select].txt
    }
    if ![winfo exists $t] {
	# avoid crashing
	return
    }
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
       $w.f selection range 0 end
    } else {
       raise $w.f
       focus $w
       $w.f icursor end
       $w.f selection range 0 end
    }
    bind $w <Destroy> "searchrep'done $t"
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

# done search
proc searchrep'done w {
    foreach {from to} [$w tag ranges hilite] {
        $w tag remove hilite $from $to
    }
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
    proc ::tk::mac::ShowHelp {} {
	doGuiHelp
    }
    proc ::tk::mac::OpenDocument {args} {
	foreach f $args {
	    loadSourceFile "$f" 0
	}
    }
    proc tkAboutDialog {} {
	doAbout
    }
}

# main code
if { $::argc > 0 } {
    foreach argx $argv {
        loadSourceFile [file normalize $argx] 0
    }
} elseif { $config(savesession) && [llength $OPENFILES] } {
    openLastFiles
} else {
    createNewTab
}

rescanPorts
set dirlist [encoding dirs]
set dirlist [linsert $dirlist 0 "$ROOTDIR/tcl_library/tcl8.6/encoding"] 
encoding dirs $dirlist
