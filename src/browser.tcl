#
# launch a url in the user's web browser
# from https://wiki.tcl-lang.org/page/Invoking+browsers
# written by Cameron Laird
#
#package require Tcl 8.5
proc launchBrowser url {
    global tcl_platform

    if {$tcl_platform(platform) eq "windows"} {
        # first argument to "start" is "window title", which is not used here
        set command [list {*}[auto_execok start] {}]
        # (older) Windows shell would start a new command after &, so shell escape it with ^
        #set url [string map {& ^&} $url]
        # but 7+ don't seem to (?) so this nonsense is gone
        if {[file isdirectory $url]} {
            # if there is an executable named eg ${url}.exe, avoid opening that instead:
            set url [file nativename [file join $url .]]
        }
    } elseif {$tcl_platform(os) eq "Darwin"} {
        # It *is* generally a mistake to use $tcl_platform(os) to select functionality,
        # particularly in comparison to $tcl_platform(platform).  For now, let's just
        # regard it as a stylistic variation subject to debate.
        set command [list open]
    } else {
        set command [list xdg-open]
    }
    exec {*}$command $url &
}

proc _launchBrowser {url} {
    if [catch {launchBrowser $url} err] {
        tk_messageBox -icon error -message "error '$err' with '$command'"
    }
}
