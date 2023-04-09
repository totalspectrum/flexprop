#
# code for creating project (.fpide) files
#

# test for file types
proc is_c_file {name} {
    if { [string match -nocase "*.\[ch\]" $name] } {
	return 1
    }
    if { [string match -nocase "*.cc" $name] } {
	return 1
    }
    if { [string match -nocase "*.\[ch\]pp" $name] } {
	return 1
    }
    return 0
}

proc is_proj_file {name} {
    if { [string match -nocase "*.fpide" $name] } {
	return 1
    }
    if { [string match -nocase "*.side" $name] } {
	return 1
    }
    return 0
}

proc is_basic_file {name} {
    if { [string match -nocase "*.bas" $name] } {
	return 1
    }
    if { [string match -nocase "*.bi" $name] } {
	return 1
    }
    return 0
}

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


set project_msg "#
# this is a FlexProp project file
# it has a list of files, one per line
# followed by a list of definitions prefixed by >
# change the file names or add more as appropriate
#"

proc createNewProject {existingFiles} {
    global filenames
    global BINFILE
    global SpinTypes
    global config
    global project_msg
    global file_filtervar
    
    set initdir $config(lastdir)
    set initfilename ""
    set fileList ""
    
    if { $existingFiles } {
	set fileList [tk_getOpenFile -filetypes $SpinTypes -initialdir $config(lastdir) -title "Select files to include" -multiple true]
	if { "$fileList" eq "" } {
	    return
	}
	set firstfile [lindex $fileList 0]
	set initdir [file dirname $firstfile]
	set config(spinext) [file extension $firstfile]
    }
    
    set file_filtervar "Project files"
    set filename [tk_getSaveFile -filetypes $SpinTypes -defaultextension ".fpide" -initialdir $initdir -initialfile $initfilename -title "New Project File" -typevariable file_filtervar]

    if { "$filename" eq "" } {
	return
    }
    set config(lastdir) [file dirname $filename]
    set fileroot [file rootname $filename]
    set BINFILE ""

    if { "$fileList" eq "" } {
	set fileList [concat "$fileroot.c" ">-DPROJNAME=\"$fileroot\""]
    }

    # write new data to the file
    set fp [open $filename w]
    puts $fp $project_msg
    foreach i $fileList {
	puts $fp $i
    }
    close $fp

    loadSourceFile "$filename" 0
}
