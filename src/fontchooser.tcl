 ###############################
 #
 # a pure Tcl/Tk font chooser
 #
 # by ulis, 2002
 #
 # NOL (No Obligation Licence)
 #
 ###############################
 
 namespace eval ::choosefont \
 { 
   variable w .choosefont;
   variable font;
 
   # Martin Lemburg Aug. 20th, 2002
   # initialization moved into proc choosefont
   #
   variable listvar;
   #
   # Martin Lemburg Aug. 20th, 2002
 
   variable family;
   variable size;
   variable bold;
   variable italic;
   variable underline;
   variable overstrike;
   variable ok;
   variable lock 1;
 
   # ================
   # choose a font
   # ================
   # args:
   #       f   an initial (and optional) font
   #       t   an optional title
   # returns:
   #       "" if the user aborted
   #       or the created font name
   # usage:
   #       namespace import ::choosefont::choosefont
   #       choosefont "Courier 10 italic" "new font"
 
   namespace export choosefont;
 
   proc choosefont {{f ""} {t ""}} \
   {
     # ------------------
     # get choosefont env
     # ------------------
     variable ::choosefont::w;
     variable ::choosefont::font;
     variable ::choosefont::listvar;
     variable ::choosefont::family;
     variable ::choosefont::size;
     variable ::choosefont::bold;
     variable ::choosefont::italic;
     variable ::choosefont::underline;
     variable ::choosefont::overstrike;
     variable ::choosefont::ok;
     variable ::choosefont::lock;
 
     # Martin Lemburg Aug. 20th, 2002 
     # refreshing, with every call, lsort added
     #
     set listvar [lsort -dictionary [font families]];
     #
     # Martin Lemburg Aug. 20th, 2002
 
     # ------------------
     # dialog
     # ------------------
     if {[winfo exists $w]} \
     {
       # show the dialog
       wm deiconify $w;
     } \
     else \
     {
       # create the dialog
       toplevel $w;
       wm title $w "Choose a font";
 
       # create widgets
 
       frame $w.f -bd 1 -relief sunken;
         label $w.f.h -height 4;
         label $w.f.l -textvariable ::choosefont::family;
       
       frame $w.fl;
         # Martin Lemburg Aug. 20th, 2002
         # added selectmode setting
         #
         listbox $w.fl.lb \
           -listvar ::choosefont::listvar \
           -width 20 \
           -yscrollcommand [list $w.fl.sb set] \
           -selectmode single;
         #
         # Martin Lemburg Aug. 20th, 2002
         scrollbar $w.fl.sb -command [list $w.fl.lb yview];
 
       # Martin Lemburg Aug. 20th, 2002
       # added underline options for mnemonics
       #
       frame $w.fa -bd 2 -relief groove;
         frame $w.fa.f ;
           label $w.fa.f.lsize -text size -underline 0;
           entry $w.fa.f.esize \
           -textvariable ::choosefont::size \
           -width 3 \
           -validate focusout \
           -vcmd {string is integer -strict %P};
           checkbutton $w.fa.f.bold \
           -text bold \
           -underline 0 \
           -variable ::choosefont::bold;
           checkbutton $w.fa.f.italic -text italic \
           -underline 0 \
           -variable ::choosefont::italic;
           checkbutton $w.fa.f.under \
           -text underline \
           -underline 0 \
           -variable ::choosefont::underline;
           checkbutton $w.fa.f.over \
           -text overstrike \
           -underline 0 \
           -variable ::choosefont::overstrike;
       #
       # Martin Lemburg Aug. 20th, 2002,
 
       frame $w.fb;
         button $w.fb.ok \
           -text Ok \
           -width 10 \
           -command { set ::choosefont::ok 1 };
         button $w.fb.cancel \
           -text cancel \
           -width 10 \
           -command { set ::choosefont::ok 0 };
 
       # bind events
       bind $w.fl.lb <ButtonRelease-1> \
       { set ::choosefont::family [%W get [%W cursel]] };
 
       # Martin Lemburg Aug. 20th, 2002
       # extended bindings
       #
       tk_focusFollowsMouse;
 
       # listbox handling
       bind $w <Control-Home> \
       { ::choosefont::selectfont %W First };
       bind $w <Control-End> \
       { ::choosefont::selectfont %W Last };
       bind $w <KeyPress> \
       { ::choosefont::selectfont %W %K };
 
       bind $w <Escape> [list $w.fb.cancel invoke];
       bind $w <Return> [list $w.fb.ok invoke];
 
       # mnemonics
       bind $w <Alt-KeyRelease> \
       {
         set w [winfo toplevel %W];
 
         switch -exact -- [string tolower %K] \
         {
           s  {focus $w.fa.f.esize;}
           b  {focus $w.fa.f.bold; $w.fa.f.bold invoke;}
           i  {focus $w.fa.f.italic; $w.fa.f.italic invoke;}
           u  {focus $w.fa.f.under; $w.fa.f.under invoke;}
           o  {focus $w.fa.f.over; $w.fa.f.over invoke;}
         }
       }
       #
       # Martin Lemburg Aug. 20th, 2002
 
       set lock 1;
 
       trace variable ::choosefont::family     w ::choosefont::createfont;
       trace variable ::choosefont::size       w ::choosefont::createfont;
       trace variable ::choosefont::bold       w ::choosefont::createfont;
       trace variable ::choosefont::italic     w ::choosefont::createfont;
       trace variable ::choosefont::underline  w ::choosefont::createfont;
       trace variable ::choosefont::overstrike w ::choosefont::createfont;
 
       # place widgets
 
       grid $w.f           -row 0 -column 0 -columnspan 2 -sticky nsew;
       grid $w.fl          -row 1 -column 0 -padx 5 -pady 5;
       grid $w.fa          -row 1 -column 1 -sticky nsew -padx 5 -pady 5;
       grid $w.fb          -row 2 -column 0 -columnspan 2 -sticky ew -pady 20;
       grid $w.f.h         -row 0 -column 0;
       grid $w.f.l         -row 0 -column 1 -sticky nsew;
       grid $w.fl.lb       -row 0 -column 0;
       grid $w.fl.sb       -row 0 -column 1 -sticky ns;
       grid $w.fa.f        -padx 5 -pady 5;
       grid $w.fa.f.lsize  -row 0 -column 0 -padx 5 -sticky w;
       grid $w.fa.f.esize  -row 0 -column 1 -sticky w;
       grid $w.fa.f.bold   -row 1 -column 0 -columnspan 2 -sticky w;
       grid $w.fa.f.italic -row 2 -column 0 -columnspan 2 -sticky w;
       grid $w.fa.f.under  -row 3 -column 0 -columnspan 2 -sticky w;
       grid $w.fa.f.over   -row 4 -column 0 -columnspan 2 -sticky w;
       grid $w.fb.ok $w.fb.cancel -padx 20;
     };
 
     # ------------------
     # current font
     # ------------------
     if {$f != ""} { set font $f };
     if {![info exists font]} { set font [$w.f.l cget -font] };
     
     set family      [font actual $font -family];
     set size        [font actual $font -size];
     set bold        [expr {[font actual $font -weight] == "bold"}];
     set italic      [expr {[font actual $font -slant] == "italic"}];
     set underline   [font actual $font -underline];
     set overstrike  [font actual $font -overstrike];
     set lock        0;
     
     ::choosefont::createfont;
 
     # ------------------
     # end of dialog
     # ------------------
     if {$t != ""} { wm title $w $t };
 
     # Martin Lemburg Aug. 20th, 2002 - select current font
     #
     set newIndex  [lsearch -exact $listvar $family];
 
     $w.fl.lb selection set $newIndex;
     $w.fl.lb activate $newIndex; 
     $w.fl.lb see $newIndex;
     #
     # Martin Lemburg Aug. 20th, 2002
 
     vwait ::choosefont::ok;
     wm withdraw $w;
 
     if {$ok} \
     { return [::choosefont::createfont] } \
     else \
     { return "" };
   };
 
   # ================
   # ancillary procs
   # ================
 
   proc selectfont {w mode} \
   {
     if {[winfo class $w] != "Listbox"} \
     { return; }
 
     set oldIndex [$w curselection];
 
     if {[string length $mode] > 1} \
     {
       switch -exact -- $mode \
       {
         Down    {set newIndex [expr {$oldIndex+1}];}
         Up      {set newIndex [expr {$oldIndex-1}];}
         First   {set newIndex 0;}
         Last    {set newIndex end;}
         default \
         { return; }
       }

       if {($newIndex != "end") && $newIndex} \
       {
         if {$newIndex < 0} \
         { set newIndex 0; } \
         elseif {$newIndex > [$w size] - 1} \
         { set newIndex end; };
       }
     } \
     else \
     {
       set oldFamily  [lindex $::choosefont::listvar $oldIndex];
 
       if {[string match ${mode}* $oldFamily]} \
       {
         set newIndex  [expr {$oldIndex + 1}];
         set newFamily [lindex $::choosefont::listvar $newIndex];
 
         if {![string match ${mode}* $newFamily]} \
         {
           set newIndex [lsearch \
             -glob \
             $::choosefont::listvar \
             ${mode}* \
           ];
         }
       } \
       else \
       {
         set newIndex [lsearch \
           -glob \
           $::choosefont::listvar \
           ${mode}* \
         ];
       };
 
       if {$newIndex < 0} \
       { return; };
     };
 
     set ::choosefont::family  [$w get $newIndex];
 
     $w selection clear $oldIndex;
     $w selection set $newIndex;
     $w activate $newIndex;
     $w see $newIndex;
 
     return;
   }
 
   proc createfont {args} \
   {
     if {$::choosefont::lock} { return };
 
     variable ::choosefont::w;
     variable ::choosefont::font;
     variable ::choosefont::family;
     variable ::choosefont::size;
     variable ::choosefont::bold;
     variable ::choosefont::italic;
     variable ::choosefont::underline;
     variable ::choosefont::overstrike;
 
     catch { font delete $font };
 
     set f [list -family $family -size $size];
 
     foreach {var option value} {
       bold        -weight     bold 
       italic      -slant      italic 
       underline   -underline  1 
       overstrike  -overstrike 1
     } \
     { if {[set $var]} { lappend f $option $value } };
     
     $w.f.l config -font [set font  [eval font create $f]];
 
     return $font;
   }
 }
