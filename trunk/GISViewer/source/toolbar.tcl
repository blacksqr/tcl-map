package require Tcl 8.5
package require Tk 8.5
package require toe 1.0

toe::class Toolbar {
  private variable toolbar
  private variable orientation
  private variable groups
  private variable thickness
  private variable toolbar

  method constructor {frame orient thick} {
      set orientation $orient
      set thickness $thick
      
      #XXX The following does not work
      ttk::style configure toolbar.TPanedwindow -showHandle 1 -handleSize 0 -sashRelief ridge -sashWidth 2 -sashPad 4
      
      switch -exact -- $orientation {
          "horizontal" {
              set toolbar [ttk::panedwindow $frame.panedwin -height $thickness -orient horizontal -style toolbar.TPanedwindow]
          }
          "vertical" {
              set toolbar [ttk::panedwindow $frame.panedwin -width $thickness -orient vertical -style toolbar.TPanedwindow]
          }
          default {error}
      }
      
      grid $toolbar -row 0 -column 0 -sticky nswe
  }
  
  public method group {action name} {
      switch -exact -- $action {
          "add" {
              if {! [info exists groups($name)]} {
                  set groups($name) [list]
                  if {$orientation eq "horizontal"} {
                      ttk::frame $toolbar.$name -padding {0 0 10 0}
                  } else {
                      ttk::frame $toolbar.$name -padding {0 0 0 10}
                  }
                  $toolbar add $toolbar.$name
              }
          }
          "del" {
              if {[info exists groups($name)]} {
                  unset groups($name)
                  $toolbar del $toolbar.$name
                  destroy $toolbar.$name
              }
          }
          "activate" -
          "deactivate" {
              if {[info exists groups($name)]} {
                  foreach n $groups($name) {
                      my item $action $name $n
                  }
              }
          }
          default {error}
      }
  }
  
  public method button {action group name args} {
      set gsize [llength $groups($group)]
      
      switch -exact -- $action {
          "add" {
              lassign $args img cmd pos
              if {$pos eq ""} {
                  set pos $gsize
              }
              
              ttk::button $toolbar.$group.$name -image $img -command $cmd -default disabled -style Flat.TButton
              if {$orientation eq "horizontal"} {
                  grid $toolbar.$group.$name -row 0 -column $pos -sticky w -padx 2 -pady 2
              } else {
                  grid $toolbar.$group.$name -row $pos -column 0 -sticky n -padx 2 -pady 2
              }
              
              lappend groups($group) $name
          }
          "del" {
              destroy $toolbar.$group.$name
              lremove groups($group) $name
          }
          "activate" {
              $toolbar.$group.$name configure -state normal
          }
          "deactivate" {
              $toolbar.$group.$name configure -state disabled
          }
          default {error}
      }
  }
  
  public method widget {action group widget {pos ""}} {
      set gsize [llength $groups($group)]
      
      switch -exact -- $action {
          "add" {
              if {$pos eq ""} {
                  set pos $gsize
              }
              
              if {$orientation eq "horizontal"} {
                  grid $widget -in $toolbar.$group -row 0 -column $pos -sticky w -padx 2 -pady 2
              } else {
                  grid $widget -in $toolbar.$group -row $pos -column 0 -sticky n -padx 2 -pady 2
              }
              
              lappend groups($group) $widget
          }
          "del" {
              destroy $widget
              lremove groups($group) $widget
          }
          "activate" {
              $widget configure -state normal
          }
          "deactivate" {
              $widget configure -state disabled
          }
          default {error}
      }
  }
} ;# class