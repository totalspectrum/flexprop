#!/usr/bin/env wish
#
# Simple GUI for Spin
# Copyright 2018-2019 Total Spectrum Software
# Distributed under the terms of the MIT license;
# see License.txt for details.
#
# Top level program

variable myScript [file normalize [info script]]
variable ROOTDIR [file dirname $myScript]

package require Tk
#package require autoscroll
#package require ctext

source $ROOTDIR/version.tcl
source $ROOTDIR/autoscroll.tcl
source $ROOTDIR/browser.tcl
source $ROOTDIR/ctext/ctext.tcl
source $ROOTDIR/checkserial.tcl
source $ROOTDIR/pathbox.tcl
source $ROOTDIR/fontchooser.tcl
source $ROOTDIR/balloon.tcl
source $ROOTDIR/gui.tcl

namespace import ::choosefont::choosefont
