#
# code for creating project (.fpide) files
#

proc do_proj_cancel {} {
    global newprj_name
    set newprj_name ""
    destroy .newprj
}

proc do_proj_ok {} {
    global newprj_name
    if { $newprj_name ne "" } {
	createNewProjectWindow $newprj_name
    }
    set newprj_name ""
    destroy .newprj
}

proc do_proj_create {} {
    global config
    global newprj_name

    toplevel .newprj
    ttk::label .newprj.prjlbl -text "Project Name"
    ttk::entry .newprj.name -textvariable newprj_name
    frame .newprj.buttons
    ttk::button .newprj.buttons.ok -text "OK" -command do_proj_ok
    ttk::button .newprj.buttons.cancel -text "Cancel" -command do_proj_cancel

    grid .newprj.buttons.ok .newprj.buttons.cancel
    grid columnconfigure .newprj.buttons 0 -weight 1
    grid rowconfigure .newprj.buttons 0 -weight 1

    grid .newprj.prjlbl -sticky we
    grid .newprj.name -sticky we
    grid .newprj.buttons
    grid columnconfigure .newprj 0 -weight 1
    grid rowconfigure .newprj 0 -weight 1
}


proc createNewProjectOld {} {
    if { [winfo exists .newprj] } {
	raise .newprj
    } else {
	do_proj_create
	wm title .newprj "New Project"
    }
}

set project_msg "#
# this is a FlexProp project file
# it has a list of files, one per line
# followed by a list of definitions prefixed by >
# change the file names or add more as appropriate
#
\$fileroot.c
>-DPROJNAME=\"\$fileroot\"
"

proc createNewProject {} {
    global filenames
    global BINFILE
    global SpinTypes
    global config
    global project_msg
    global file_filtervar
    
    set initdir $config(lastdir)
    set initfilename ""

#    set initdir [tk_chooseDirectory -initialdir $initdir -title "Choose directory for project"]
#    if { "$initdir" eq "" } {
#	return
    #    }
    set file_filtervar "Project files"
    set filename [tk_getSaveFile -filetypes $SpinTypes -defaultextension ".fpide" -initialdir $initdir -initialfile $initfilename -title "New Project" -typevariable file_filtervar]

    if { "$filename" eq "" } {
	return
    }
    set config(lastdir) [file dirname $filename]
    set config(spinext) [file extension $filename]
    set fileroot [file rootname $filename]
    set BINFILE ""

    set w [newTabName]
    setupFramedText $w
    setHighlightingForFile $w.txt $filename
    setfont $w.txt $config(font)

    .p.nb add $w
    .p.nb tab $w -text [file tail $filename]
    .p.nb select $w
    
    set filenames($w) $filename

    set ourmap [ list "\$fileroot" "$fileroot" ]
    set msg [string map $ourmap $project_msg]
    $w.txt insert end $msg
    saveCurFile
}


proc doNewProject {} {
    createNewProject
}

proc addFilesToProject {} {
    
}
