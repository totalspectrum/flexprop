source src/version.tcl

proc makepandoc {} {
    global spin2gui_version
    set now [clock seconds]
    set date [clock format $now -format %D]
    puts "documentclass: book"
    puts "title: FlexGUI Reference"
    puts "subtitle: $spin2gui_version"
    puts "author: Total Spectrum Software"
    puts "date: $date"
}

makepandoc
