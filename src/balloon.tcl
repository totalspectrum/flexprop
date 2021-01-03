#
# Balloon help example from https://wiki.tcl-lang.org
#

proc setBalloonHelp {w msg args} {
  array set opt [concat {
      -tag ""
    } $args]
  if {$msg ne ""} then {
    set toolTipScript\
      [list showBalloonHelp %W [string map {% %%} $msg]]
    set enterScript [list after 1000 $toolTipScript]
    set leaveScript [list after cancel $toolTipScript]
    append leaveScript \n [list after 200 [list destroy .balloonHelp]]
  } else {
    set enterScript {}
    set leaveScript {}
  }
  if {$opt(-tag) ne ""} then {
    switch -- [winfo class $w] {
      Text {
        $w tag bind $opt(-tag) <Enter> $enterScript
        $w tag bind $opt(-tag) <Leave> $leaveScript
      }
      Canvas {
        $w bind $opt(-tag) <Enter> $enterScript
        $w bind $opt(-tag) <Leave> $leaveScript
      }
      default {
        bind $w <Enter> $enterScript
        bind $w <Leave> $leaveScript
      }
    }
  } else {
    bind $w <Enter> $enterScript
    bind $w <Leave> $leaveScript
  }
}

proc showBalloonHelp {w msg} {
  set t .balloonHelp
  catch {destroy $t}
  toplevel $t -bg black
  wm overrideredirect $t yes
  if {$::tcl_platform(platform) == "macintosh"} {
    unsupported1 style $t floating sideTitlebar
  }
  pack [label $t.l -text [subst $msg] -bg yellow -font {Helvetica 9}]\
    -padx 1\
    -pady 1
  set width [expr {[winfo reqwidth $t.l] + 2}]
  set height [expr {[winfo reqheight $t.l] + 2}]
  set xMax [expr {[winfo screenwidth $w] - $width}]
  set yMax [expr {[winfo screenheight $w] - $height}]
  set x [winfo pointerx $w]
  set y [expr {[winfo pointery $w] + 20}]
  if {$x > $xMax} then {
    set x $xMax
  }
  if {$y > $yMax} then {
    set y $yMax
  }
  wm geometry $t +$x+$y
  set destroyScript [list destroy .balloonHelp]
  bind $t <Enter> [list after cancel $destroyScript]
  bind $t <Leave> $destroyScript
}

# demo
if false {
  pack [button .b -text tryme -command {puts "you did it!"}]
  setBalloonHelp .b "Text that describes\nwhat the button does"
  #
  pack [text .t -width 30 -height 5] -expand yes -fill both
  .t insert end abcDEFghi
  .t tag configure yellow -background yellow
  .t tag add yellow 1.1 1.6
  setBalloonHelp .t "Colorised Text" -tag yellow
  #
  pack [canvas .c] -expand yes -fill both
  set id [.c create rectangle 10 10 100 100 -fill white]
  setBalloonHelp .c {Geometry: [.c coords $::id]} -tag $id
}
