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


proc createNewProject {} {
    if { [winfo exists .newprj] } {
	raise .newprj
    } else {
	do_proj_create
	wm title .newprj "New Project"
    }
}

proc createNewProjectWindow {name} {
    global filenames
    global config
    global tabEnterScript
    global tabLeaveScript
    global newprj_name

    set fname "$name.fpide"
    set w [newTabName]
    
    #.p.bot.txt delete 1.0 end
    set filenames($w) "$fname"
    setupFramedText $w
    setHighlightingForFile $w.txt "$fname"
    setfont $w.txt $config(font)
    .p.nb add $w
    .p.nb tab $w -text "$fname"
    
    .p.nb select $w

    bind $w <Enter> $tabLeaveScript
    bind $w <Leave> $tabEnterScript
    
    return $w
}

proc doNewProject {} {
    createNewProject
}

proc addFilesToProject {} {
    
}
