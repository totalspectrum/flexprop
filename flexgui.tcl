#!/usr/bin/wish
#
# Simple GUI for Spin
# Copyright 2018 Total Spectrum Software
# Distributed under the terms of the MIT license;
# see License.txt for details.
#
# Top level program

variable myScript [file normalize [info script]]
variable myDir [file dirname $myScript]

package require Tk
#package require autoscroll
#package require ctext

source $myDir/src/version.tcl
source $myDir/src/autoscroll.tcl
source $myDir/src/ctext/ctext.tcl
source $myDir/src/checkserial.tcl
source $myDir/src/gui.tcl

