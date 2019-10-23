#!/usr/bin/wish

proc do_pb_delete {} {
    set sel [.pb.pathbox curselection]
    if { $sel ne "" } {
	set se [lindex $sel 0]
	.pb.pathbox del $se
	.pb.pathbox selection clear 0 end
    }
}

proc do_pb_add {} {
    global config
    set lib [tk_chooseDirectory -title "Choose library directory" -initialdir $config(library) ]
    if { $lib ne "" } {
	.pb.pathbox insert end $lib
    }
}

proc do_pb_ok {} {
    global config

    set config(liblist) [.pb.pathbox get 0 end]
    wm withdraw .pb
}

proc do_pb_create {} {
    global config
    
    toplevel .pb
    listbox .pb.pathbox
    scrollbar .pb.sb -command [list .pb.pathbox yview]
    .pb.pathbox configure -yscrollcommand [list .pb.sb set]
    foreach i $config(liblist) {
	.pb.pathbox insert end $i
    }
    frame .pb.buttons
    button .pb.buttons.ok -text "OK" -command do_pb_ok
    button .pb.buttons.add -text "Add..." -command do_pb_add
    button .pb.buttons.delete -text "Delete" -command do_pb_delete
    #button .pb.buttons.print -text "Print" -command { puts [.pb.pathbox get 0 end] }
    grid .pb.buttons.ok .pb.buttons.add .pb.buttons.delete
    grid columnconfigure .pb.buttons 0 -weight 1
    grid rowconfigure .pb.buttons 0 -weight 1

    grid .pb.pathbox .pb.sb -sticky nsew
    grid .pb.buttons
    grid columnconfigure .pb 0 -weight 1
    grid rowconfigure .pb 0 -weight 1
}
