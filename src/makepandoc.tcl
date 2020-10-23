source src/version.tcl

proc makepandoc {} {
    global spin2gui_version
    global title
    set now [clock seconds]
    set date [clock format $now -format %D]
    puts "documentclass: book"
    puts "title: $title"
    puts "subtitle: $spin2gui_version"
    puts "author: Total Spectrum Software"
    puts "date: $date"
}

set filebase [lindex $argv 0]
#puts "original filebase = $filebase"
set filebase [file tail $filebase]
#puts "tail filebase = $filebase"

if { $filebase eq "" } {
    puts "Usage: makepandoc.tcl filename.md"
    exit 2
}
if { $filebase eq "basic.md" } {
    set title "FlexBASIC Language Reference"
} elseif { $filebase eq "c.md" } {
    set title "FlexC Language Reference"
} elseif { $filebase eq "spin.md" } {
    set title "FlexSpin Language Reference"
} else {
    set title "FlexProp Reference"
}
makepandoc
