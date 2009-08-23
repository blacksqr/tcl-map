#!/usr/bin/wish
#
# Copyright (C) 1997,1998 D. Richard Hipp
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
# 
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.
#
# Author contact information:
#   drh@acm.org
#   http://www.hwaci.com/drh/
#
# $Revision: 1.3 $
#
#
# Modified Peter Turner CSIRO Atmospheric Research November 2000
# Fixed Tree:delitem bug for removal of whole tree
# Fixed bug relating to names with imbedded spaces.
# Put the whole thing into a namespace!
# Trying to add the same node again is nolonger an error
# Added attribute option 
#
# This whole tree drawing library is oriented towards 
# drawing directory structures. Hence there is extensive
# use of the "/" in determining the tree structure.
# To avoid these sort of problems the whole library needs
# to be modified to use Tcl lists to specify tree structures.
#
# Better error treatement is needed!
# 
#
# Example
# 
# frame .t -bg white
# pack .t -fill both -expand 1
# Tree:create .t.w -width 400 -height 200
# Tree:newitem .t.w "/new level"
# Tree:newitem .t.w "/new level/level1"
#
# Having created a small tree bind button
# click events to the tree and return the
# value of the item in the tree that has been
# selected.
#
# .t.w bind x <1> {
# set lbl [Tree:labelat %W %x %y]
# <insert your code here to deal with the value returned>
# }
#
# A double click can be set to open the tree
# structure.
#
# .t.w bind x <Double-1> {
# Tree:open %W [Tree:labelat %W %x %y]
# }
# update
#
# Photo images can be created and included in the tree
# structure:
#
# image create photo idir -data {
#    R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4APj4+P///wAAAAAAACwAAAAAEAAQAAADPVi63P4w
#    LkKCtTTnUsXwQqBtAfh910UU4ugGAEucpgnLNY3Gop7folwNOBOeiEYQ0acDpp6pGAFArVqt
#    hQQAO///
# }
#
# Tree:newitem .t.w /fredbear -image idir
#
# or for a file
#
# image create photo ifile -data {
#    R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACwAAAAAEAAQAAADPkixzPOD
#    yADrWE8qC8WN0+BZAmBq1GMOqwigXFXCrGk/cxjjr27fLtout6n9eMIYMTXsFZsogXRKJf6u
#    P0kCADv/
# }
#
# Attributes giving extra information about the tree itme
# can be added using the attribute option:
#
# Tree:newitem .t.w /nedbear -image ifile -attributes "height 3 metres"
#
# Proceedure calls available are listed below
# to use without needing to prepend Tree0:: the
# proceedures can be imported:
#
# namespace import Tree0::Tree:create
#
#

namespace eval Tree0 {
    variable Tree

    namespace export Tree:create 
    namespace export Tree:newitem 
    namespace export Tree:delitem 
    namespace export Tree:config 
    namespace export Tree:setselection 
    namespace export Tree:getselection 
    namespace export Tree:open
    namespace export Tree:close
    namespace export Tree:labelat

#
# Tree:font--
#
# Set the font for the tree display according
# to the platform we are running on.
#
proc Tree:font {} {
    variable Tree
    global tcl_platform

    option add *highlightThickness 0

    switch $tcl_platform(platform) {
        unix {
            set Tree(font) \
            -adobe-helvetica-medium-r-normal-*-11-80-100-100-p-56-iso8859-1
        }
        windows {
            set Tree(font) \
            -adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
        }
    }
}

#
# Tree:create--
#
# Create a new tree widget.  $args become the configuration arguments to
# the canvas widget from which the tree is constructed.
# note that there is a binding between destroy and the Tree:delitem
# proceedure that will remove all Tree array elements.
#
proc Tree:create {w args} {
    variable Tree

    eval canvas $w -bg white $args
    bind $w <Destroy> "Tree0::Tree:delitem $w /"
# Set the font added here
    Tree:font
    Tree:dfltconfig $w /
    Tree:buildwhenidle $w
    set Tree($w:selection) {}
    set Tree($w:selidx) {}
}

#
# Tree:dfltconfig--
#
# Initialize an element of the tree.
# Internal use only
#
proc Tree:dfltconfig {w v} {
    variable Tree

    set Tree($w:$v:children) {}
    set Tree($w:$v:open) 0
    set Tree($w:$v:icon) {}
    set Tree($w:$v:attr) {}
    set Tree($w:$v:tags) {}
}

#
# Tree:config--
#
# Pass configuration options to the tree widget
#
proc Tree:config {w args} {
    eval $w config $args
}

#
# Tree:newitem--
#
# This is the major user interface routine.
# First call Tree:create
# and then multiple cals to this routine.
# All inserted elements have the form of the normal
# directory structure /name/name/...
#
# Options:
# -image <image name>		places an image before the node name
# -attributes <attributes>	adds a string 6 spaces after the node name
# -tags ? 
#
# Insert a new element $v into the tree $w.
#
proc Tree:newitem {w v args} {
    variable Tree
#
# if /hello       dir = /      and n = hello
# if /hello/world dir = /hello and n = world
#
    set dir [file dirname $v]
    set n [file tail $v]
    if {![info exists Tree($w:$dir:open)]} {
        error "parent item \"$dir\" is missing"
    }
    set i [lsearch -exact $Tree($w:$dir:children) $n]
    if {$i>=0} {
#
# Changed this to do nothing. If it already exists
# then in a general sense it does not matter if
# we try to create the same thing again.
#
        return
        error "item \"$v\" already exists"
    }
    lappend Tree($w:$dir:children) $n
    set Tree($w:$dir:children) [lsort $Tree($w:$dir:children)]
    Tree:dfltconfig $w $v
    foreach {op arg} $args {
        switch -exact -- $op {
            -image {set Tree($w:$v:icon) $arg}
            -tags {set Tree($w:$v:tags) $arg}
            -attributes {set Tree($w:$v:attr)  "$arg"}
        }
    }
    Tree:buildwhenidle $w
}

#
# Tree:delitem--
#
# Delete element $v from the tree $w.  If $v is /, then the widget is
# deleted.
#
proc Tree:delitem {w v} {
    variable Tree

    if {![info exists Tree($w:$v:open)]} return
#
# Get rid of the whole tree
#
    if {[string compare $v /]==0} {
#
# get rid of the widget and all associated Tree elements
#
        catch {destroy $w}
#
# get rid of each array item
#
        foreach t [array names Tree $w:*] {
            unset Tree($t)
        }
        return
    }
    foreach c $Tree($w:$v:children) {
        catch {Tree:delitem $w $v/$c}
    }
    unset Tree($w:$v:open)
    unset Tree($w:$v:children)
    unset Tree($w:$v:icon)
    set dir [file dirname $v]
    set n [file tail $v]
    set i [lsearch -exact $Tree($w:$dir:children) $n]
    if {$i>=0} {
        set Tree($w:$dir:children) [lreplace $Tree($w:$dir:children) $i $i]
    }
    Tree:buildwhenidle $w
}

#
# Tree:setselection--
#
# Change the selection to the indicated item
#
proc Tree:setselection {w v} {
    variable Tree

    set Tree($w:selection) $v
    Tree:drawselection $w
}

# 
# Tree:getselection--
#
# Retrieve the current selection
#
proc Tree:getselection w {
    variable Tree

    return $Tree($w:selection)
}

#
# Bitmaps used to show which parts of the tree can be opened.
#
set maskdata "#define solid_width 9\n#define solid_height 9"
append maskdata {
  static unsigned char solid_bits[] = {
   0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01,
   0xff, 0x01, 0xff, 0x01, 0xff, 0x01
  };
}
set data "#define open_width 9\n#define open_height 9"
append data {
  static unsigned char open_bits[] = {
   0xff, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7d, 0x01, 0x01, 0x01,
   0x01, 0x01, 0x01, 0x01, 0xff, 0x01
  };
}
image create bitmap Tree:openbm -data $data -maskdata $maskdata \
  -foreground black -background white
set data "#define closed_width 9\n#define closed_height 9"
append data {
  static unsigned char closed_bits[] = {
   0xff, 0x01, 0x01, 0x01, 0x11, 0x01, 0x11, 0x01, 0x7d, 0x01, 0x11, 0x01,
   0x11, 0x01, 0x01, 0x01, 0xff, 0x01
  };
}
image create bitmap Tree:closedbm -data $data -maskdata $maskdata \
  -foreground black -background white

#
# Tree:build--
#
# Internal use only.
# Draw the tree on the canvas
#
proc Tree:build {w} {
    variable Tree

    $w delete all
    catch {unset Tree($w:buildpending)}
    set Tree($w:y) 30
    Tree:buildlayer $w / 10
    $w config -scrollregion [$w bbox all]
    Tree:drawselection $w
}

#
# Tree:buildlayer--
#
# Internal use only.
# Build a single layer of the tree on the canvas.  Indent by $in pixels
# this is the guts of the whole thing. It also
# recursive.
#
proc Tree:buildlayer {w v in} {
  variable Tree

  if {$v=="/"} {
    set vx {}
  } else {
    set vx $v
  }
  #
  # Stop expr $y + 1 error if nothing to build
  #
  if {[string length $Tree($w:$v:children)] == 0} {
    return
  }
  set start [expr $Tree($w:y)-10]
  foreach c $Tree($w:$v:children) {
    set y $Tree($w:y)
    incr Tree($w:y) 17
    $w create line $in $y [expr $in+10] $y -fill gray50 
    set icon $Tree($w:$vx/$c:icon)
    set taglist x
    foreach tag $Tree($w:$vx/$c:tags) {
      lappend taglist $tag
    }
    set x [expr $in+12]
    if {[string length $icon]>0} {
      set k [$w create image $x $y -image $icon -anchor w -tags $taglist]
      incr x 20
      set Tree($w:tag:$k) $vx/$c
    }
    set a $Tree($w:$vx/$c:attr)
    set j [$w create text $x $y -text "$c $a" -font $Tree(font) \
                                -anchor w -tags $taglist]
    set Tree($w:tag:$j) $vx/$c
    set Tree($w:$vx/$c:tag) $j
    if {[string length $Tree($w:$vx/$c:children)]} {
      if {$Tree($w:$vx/$c:open)} {
         set j [$w create image $in $y -image Tree:openbm]
         $w bind $j <1> \
         "set [list Tree0::Tree($w:$vx/$c:open)] 0; Tree0::Tree:build $w"
         Tree:buildlayer $w $vx/$c [expr $in+18]
      } else {
         set j [$w create image $in $y -image Tree:closedbm]
         $w bind $j <1> \
         "set [list Tree0::Tree($w:$vx/$c:open)] 1; Tree0::Tree:build $w"
      }
    }
  }
  set j [$w create line $in $start $in [expr $y+1] -fill gray50 ]
  $w lower $j
}

#
# Tree:open--
#
# Open a branch of a tree
#
proc Tree:open {w v} {
    variable Tree

    if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==0
        && [info exists Tree($w:$v:children)] 
        && [string length $Tree($w:$v:children)]>0} {
        set Tree($w:$v:open) 1
        Tree:build $w
    }
}

#
# Tree:close--
#
# Close a branch of a tree
#
proc Tree:close {w v} {
  variable Tree

  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==1} {
    set Tree($w:$v:open) 0
    Tree:build $w
  }
}

#
# Tree:drawselection--
#
# Internal use only.
# Draw the selection highlight
#
proc Tree:drawselection w {
    variable Tree

    if {[string length $Tree($w:selidx)]} {
        $w delete $Tree($w:selidx)
    }
    set v $Tree($w:selection)
    if {[string length $v]==0} return
    if {![info exists Tree($w:$v:tag)]} return
    set bbox [$w bbox $Tree($w:$v:tag)]
    if {[llength $bbox]==4} {
        set i [eval $w create rectangle $bbox -fill skyblue -outline {{}}]
        set Tree($w:selidx) $i
        $w lower $i
    } else {
        set Tree($w:selidx) {}
    }
}

#
# Tree:buildwhenidle--
#
# Internal use only
# Call Tree:build then next time we're idle
#
proc Tree:buildwhenidle w {
    variable Tree

    if {![info exists Tree($w:buildpending)]} {
        set Tree($w:buildpending) 1
        after idle "Tree0::Tree:build $w"
    }
}

#
# Tree:labelat--
#
# Return the full pathname of the label for widget $w that is located
# at real coordinates $x, $y
#
proc Tree:labelat {w x y} {
    set x [$w canvasx $x]
    set y [$w canvasy $y]
    variable Tree
    foreach m [$w find overlapping $x $y $x $y] {
        if {[info exists Tree($w:tag:$m)]} {
            return $Tree($w:tag:$m)
        }
    }
    return ""
}

#End of namespace Tree
}
