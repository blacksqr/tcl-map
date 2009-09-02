# toe.tcl -- 

# LICENSE
# 
# Copyright (c) 2009, Peter M. Martin
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
#   * Redistributions of source code must retain the above copyright notice, 
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice, 
#     this list of conditions and the following disclaimer in the documentation 
#     and/or other materials provided with the distribution.
#   * The name of the copyright holder may not be used to endorse or promote products 
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER BE LIABLE FOR ANY DIRECT, INDIRECT, 
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
# THE POSSIBILITY OF SUCH DAMAGE.
#

package require Tcl 8.5
package provide toe 1.0

# The root namespace for all related namespaces.
namespace eval ::toe {}

namespace eval ::toe::_ {
  # policy control
  variable aplcy
  array set aplcy {
    scoped 1
    revise 1
    replaceInterface 1 
    replaceMixin 1 
    replaceClass 1
    preventGarbage 1 
    strict 0
    novars 0
    debug 0
    seize 0
  }

  # initializing values
  variable aInit ; array set aInit {}
  set aInit(opts_class) {inherits {} implements {} mixes {} abstracts {}}

  array set aInit {
    count 0
    declare {
      inherits {}
      implements {}
      mixes {}
      abstracts {}
      inner {}
      params {
        common  {public {} protected {} private {}}
        dynamic {public {} protected {} private {}}
      }
      methods {
        common  {public {} protected {} private {}}
        dynamic {public {} protected {} private {}}
      }
      invalid {}
    }
    common {
      ns {}
      cmd {}
      sharedvars {}
      methods {public {} private {}}
      selfmap {}
      cmdmap {}
      mymap {}
      nsmap {}
      model {}
    }
    dynamic {
      publicvars {}
      supervars {}
      sharedvars {}
      methods {public {} protected {} private {}}
      imports {}
      exports {}
      exposes {}
      selfmap {}
      cmdmap {}
      mymap {}
      nsmap {}
      virtuals {}
      abstract {chain {} resolved {}}
      model {}
    }
    new {
      chain {}
      abstractchain {}
      abstractresolved 0
    }
  }

  foreach {n s} [array get aInit] {
    regsub -all {\s+} $s { } t
    set aInit($n) $t
  }
  unset n s t

  # core storage for the runtime classes, interfaces and mixins
  # each is an array of dicts, one for each entity
  variable acls ; array set acls {}
  variable amxn ; array set amxn {}
  variable aifc ; array set aifc {}

  # an array of parser paths
  variable aParser ; array set aParser {}
}

#
# policy - set or get one or more boolean-valued policies
#
proc ::toe::_::policy {args} {
  variable aplcy

  # 1 arg => return the value of the named policy
  if {[llength $args]==1} {
    return $aplcy($args)
  }
  # return a list of all policies for 0 or an odd number of arguments
  if {([llength $args]==0) || ([llength $args]%2==1)} {
    return [array get aplcy]
  }
  # modify the policy, according to args
  set res [list]
  foreach {n v} $args {
    # new policies cannot be created dynamically
    if {[info exists aplcy($n)]} {
      if {"$v" eq ""} {set v 0}
      set b [expr {$v != 0}]
      set aplcy($n) $b
      lappend res $n $b

      # apply the debug policy immediately
      if {"$n" eq {debug}} {Debug}

      # manage the revise policies en banc
      if {"$n" eq {revise}} {
        set b $aplcy(revise)
        foreach nn [array names aplcy revise?*] {
          set aplcy($nn) $b
        }
      }
    }
  }
  return $res
}

# The API, as an ensemble with no procs
namespace eval ::toe {

# enable the api as commands in ::toe
interp alias {} ::toe::new {} ::toe::_::new
interp alias {} ::toe::delete {} ::toe::_::delete
interp alias {} ::toe::class {} ::toe::_::class
interp alias {} ::toe::interface {} ::toe::_::interface
interp alias {} ::toe::mixin {} ::toe::_::mixin

namespace export class new delete interface mixin
# enable the api, and then some, as subcommands to ::toe
namespace ensemble create -map {
class     ::toe::_::class
interface ::toe::_::interface
mixin     ::toe::_::mixin
new       ::toe::_::new
delete    ::toe::_::delete
api       ::toe::_::api
info      ::toe::_::Info

policy    ::toe::_::policy
adopt     ::toe::_::adopt
orphan    ::toe::_::orphan
seize     ::toe::_::seize
revise    ::toe::_::revise
objects   ::toe::_::objects::show
reset     ::toe::_::reset
copy      ::toe::_::copy
clone     ::toe::_::clone


}
}

#
# unrecognized - generate an error and report the first item in the input list
#
proc ::toe::_::unrecognized {args} {
  set L $args
  lset L 0 [namespace tail [lindex $L 0]]
  error [subst {unrecognized object method or subcommand: "$L"}]
}

#
# PublicVar - support public read/write access of a public class variable
#
proc ::toe::_::PublicVar {cname scope ons args} {
  variable acls

  lassign $args name val
  if {[string length $name]==0} {error {missing variable name}}
  # the variable must exist in the namespace
  if { ![info exists ${ons}::$name] } {
    error [subst {variable not found: $name}]
  }
  # the variable name must be declared public in this class
  switch $scope {
    common {
      if {$name ni [dict keys [dict get $acls($cname) declare params common public]]} {
        error [subst {variable not found: $name}]
      }
    }
    dynamic {
      if {$name ni [dict get $acls($cname) dynamic publicvars]} {
        error [subst {variable not found: $name}]
      }
    }
  }

  if {$val!={}} {
    return [set ${ons}::$name $val]
  } else {
    return [set ${ons}::$name]
  }
}

#
# CommonVar - declare in the local method a variable that was declared in the common namespace
#
proc ::toe::_::CommonVar {args} {
  if {[llength $args]>0} {
    set cmn [uplevel 1 self common]
    set ns [$cmn self namespace]
    foreach varname $args {
      lappend L [list namespace upvar $ns $varname $varname]
    }
    uplevel 1 "[join $L \n]"
  }
  return
}

#
# delete a dynamic instance; cannot use this to delete a common object or a class
#
proc ::toe::_::delete {args} {
  variable aplcy
  set togo {}
  foreach c $args {
    set cmd "::[string trimleft $c :]"
    set i [::toe::_::objects::exact 1 $cmd]
    if {$i<0} {error "delete: object not found: $cmd" "delete $cmd"}
    while {$i>-1} {
      lassign [::toe::_::objects::get $i] ns - bns
      if {[namespace exists $ns]} {
        namespace eval $ns {destructor}
        # delete owned objects
        if {$aplcy(preventGarbage) && ([::toe::_::objects::exact 3 $cmd]>-1)} {
          DeleteOwnedObjects $cmd
        }
        lappend togo $ns
      }
      ::toe::_::objects::remove $i
      if {[string length $bns]==0} {
        break
      }
      set i [::toe::_::objects::exact 0 $bns]
    }
  }
  namespace delete {*}$togo
  return
}

# internal: DeleteOwnedObjects - delete objects owned by the named instance
proc ::toe::_::DeleteOwnedObjects {name} {
  set togo {}
  foreach row [::toe::_::objects::matchexact 3 $name] {
    lappend togo [lindex $row 1]
  }
  if {[llength $togo]>0} {
    ::toe::_::delete {*}$togo
  }
  return
}

# internal: DeleteLocal - delete a locally-owned instance, and remove the associated trace
proc ::toe::_::DeleteLocal {cmd args} {
  trace remove variable __local__ unset "::toe::_::DeleteLocal $cmd"
  toe::_::delete $cmd
  return
}

# ownership management: orphan, adopt, seize
# return 1 if successful, else return 0

# orphan - the owner yields ownership of the object; the object is unowned.
proc ::toe::_::orphan {obj owner} {
  # validate the inputs
  set n [objects::exact 1 $obj]
  if {$n<0} {error [subst {not an object: $obj}]}

  set regowner [lindex [objects::get $n] 3]
  if {([string length $regowner]>0) && (![string equal $regowner $owner])} {
    error [subst {owner of record: $regowner}]
  }
  ::toe::_::objects::replace3 $obj $owner {}
  return
}

# adopt - transfer ownership of the object from the owner to the adopter
proc ::toe::_::adopt {obj {owner {}} {adopter {}}} {
  # validate the inputs
  set n [objects::exact 1 $obj]
  if {$n<0} {error [subst {not an object: $obj}]}

  if { ([string length $adopter]==0) && ([catch {set adopter [uplevel self object]}]) } {
    error [subst {invalid adopter $adopter}]
  }

  set m [objects::exact 1 $adopter]
  if {$m<0} {error [subst {invalid adopter $adopter}]}

  set regowner [lindex [objects::get $n] 3]

  if {([string length $regowner]>0) && (![string equal $regowner $owner])} {
    error [subst {invalid owner; current owner: $regowner}]
  }

  ::toe::_::objects::replace3 $obj $owner $adopter
  return $obj
}

# seize - the adopter takes ownership, independent of who the owner is!
# return 1 if successful, else return 0
# 
proc ::toe::_::seize {obj {acquirer ""}} {
  variable aplcy
  if {!$aplcy(seize)} {error {"seize" is disabled}}

  if {([string length $acquirer]==0) && ([catch {set acquirer [uplevel self object]}])} {
    error [subst {invalid acquirer $acquirer}]
  }

  set i [ ::toe::_::objects::exact 1 $obj ]
  if {$i>-1} {
    ::toe::_::objects::put3 $i $acquirer
    return 1
  }
  return 0
}

#
# interface - parse and register the interface
#
proc ::toe::_::interface {iname args} {
  variable aifc
  variable aParser
  variable aplcy

  # validate the interface name
  #
  # enforce the convention that an interface name be alphanumeric and start with a letter
  set name [ string trim $iname : ]
  if { ![ regexp {[a-zA-Z][\w\:]*} $name ] } {
    error "invalid interface name: $iname" "interface $iname"
  }
  # enforce the replacement policy
  if { ($name in [array names aifc]) && (!$aplcy(replaceInterface)) } {
    error "interface already defined: $iname" "interface $iname"
  }

  # parse the interface body into a local dict
  set L [list \
    [list [namespace current]::Init $name]\
    [lindex $args end]\
    [namespace current]::Final\
    ]

  if { [ catch {
    set D [ $aParser(Interface) eval "[join $L \n]" ]
  } msg ] } {
    error "$msg" "interface $name"
  }

  # save the internal representation of the interface
  set aifc($name) $D
  return $name
}

#
# mixin -- parse and register the mixin
#
proc ::toe::_::mixin {name body} {
  variable amxn
  variable aplcy
  variable aParser

  set L [list \
    [list [namespace current]::Init $name]\
    $body \
    [namespace current]::Final\
    ]

  if { [ catch {
    set amxn($name) [ $aParser(Mixin) eval "[join $L \n]" ]
  } msg ] } {
    error "$msg" "mixin $name"
  }
  # enforce the replacement policy
  if { ($name in [array names amxn]) && (!$aplcy(replaceMixin)) } {
    error "mixin already defined: $name" "mixin $name"
  }

  return $name
}

#
# internal: Debug - apply the debug policy
#
proc ::toe::_::Debug {} {
  variable aplcy

  if {$aplcy(debug)} {
    # use Tcl's error command
    catch { rename ::toe::_::error ::toe::_::_error }
  } else {
    # override ::error in this namespace
    proc ::toe::_::error {msg {info ""}} {
      return -level 2 -code error -errorinfo "$info" "$msg"
    }
  }
  return
}

# internal utility: list logic: A NOT B
proc ::toe::_::AnotB {A B} {
  set res {}
  foreach a $A {
    if {$a ni $B} {lappend res $a}
  }
  return $res
}

#
# class - the drive method for parsing a new class definition
#
proc ::toe::_::class {cname args} {
  variable aInit
  variable acls
  variable aplcy

  lassign [ClassQualify $cname [llength $args]] err lmsgs name
  if {$err} {error {*}$lmsgs}

  # initialize the class data accumulator
  array set A [array get aInit]
  # parse the class specification
  if { [catch {
    ClassParse A $name $args
  } msg ]} {
    error "$msg" "class $cname"
  }
  # create the internal representation
  Compile A $name common
  Compile A $name dynamic

  # save compiled data and make the common object
  set acls($cname) [dict create {*}[array get A]]
  MakeCommon $cname

  # use a queue to allow recursively inner classes
  set L [list $cname [dict get $A(declare) inner]]
  while {[llength $L]>0} {
    set L [lassign $L head double]
    lassign $double inner ibody
    if {[string length $inner]>0} {
      set icname "${head}::$inner"

      lassign [ClassQualify $icname] err lmsgs icname
      if {$err} {error {*}$lmsgs}

      # re-initialize the class data accumulator
      array unset A *
      array set A [array get aInit]

      if {[catch {
        ClassParse A $icname [list $ibody]
      } msg ]} {
        error "$msg" "nested class $icname"
      }
      ClassParse A $icname [list $ibody]
      Compile A $icname common
      Compile A $icname dynamic

      # save compiled data and make the nested common object
      set acls($icname) [dict create {*}[array get A]]
      MakeCommon $icname

      # setup for another
      set next [dict get $A(declare) inner]
      if {[llength $next]>0} {
        lappend L $icname $next
      }
    }
  }
  # return the class name
  return $name
}

#
# ClassQualify - preconditions for parsing a class definition
#
proc ::toe::_::ClassQualify {cname {nargs 1}} {
  variable acls
  variable aplcy

  set err 0
  set lmsgs {}

  while {1} {
    # enforce the naming convention of alphanumeric, with a leading letter
    set name [string trim $cname :]
    if { ![regexp {[a-zA-Z][\w\:]*} $name] } {
      incr err
      lappend lmsgs [subst {invalid class name: $cname}]
      break
    }

    # enforce the replacement policy
    if { ($cname in [array names acls]) && (!$aplcy(replaceClass)) } {
      incr err
      lappend lmsgs [subst {class already defined: $cname}]
      break
    }

    # argument count must be odd
    if {$nargs%2 != 1} {
      incr err
      lappend lmsgs [subst {invalid specification for class: $cname}]
      break
    }
    # single-pass
    break
  }
  return [list $err $lmsgs $name]
}

#
# ClassParse - parse and record the class
#
proc ::toe::_::ClassParse {a cname arglist} {
  upvar 1 $a A
  variable acls
  variable aifc
  variable aplcy
  variable aParser

  # process class options and return the new working dict
  set E [ClassParseOptions $cname $arglist]
  set D [dict merge $A(declare) $E]

  # parse the body and accumulate parsed units in the local dict D
  set body [lindex $arglist end]
  $aParser(Class) eval [namespace current]::Init $cname
  if { [catch {
    $aParser(Class) eval $body
  } msg ] } {
    error [subst {parsing error for class $cname: $msg}]
  }
  set D [dict merge $D [$aParser(Class) eval [namespace current]::Final]]

  # insert procs for abstract interfaces
  set d [dict create]
  set lIntfNames [dict get $D abstracts]
  foreach iname $lIntfNames {
    foreach pname [dict get $aifc($iname) exports] {
      set decl [dict get $aifc($iname) dynamic $pname]
      set decl [lassign $decl -]
      dict set d $pname [list $decl 1]
    }
  }
  set lAbstracts [dict get $d]
  # abstracted interface methods are initially created as protected
  if {[llength $lAbstracts]>0} {
    set L [dict get $D methods dynamic protected]
    lappend L {*}$lAbstracts
    dict set D methods dynamic protected $L
  }

  # merge common-protected with common-public
  foreach key {params methods} {
    set L2 [dict get $D $key common protected]
    if {[llength $L2]>0} {
      set L1 [dict get $D $key common public]
      dict set D $key common protected {}
      dict set D $key common public [concat $L1 $L2]
    }
  }
  # save the class parsing result
  set A(declare) $D
  return
}

#
# internal: ClassParseOptions - support ClassParse by parsing the options
#
proc ::toe::_::ClassParseOptions {cname arglist} {
  variable aInit

  set D [dict create]

  array set A $aInit(opts_class)
  set names1 [array names A]
  array set A [lrange $arglist 0 end-1]
  set names2 [array names A]
  if {$names1 != $names2} {
    error "invalid class option: [AnotB $names2 $names1]"
  }

  if {[string length [set cbase $A(inherits)]]>0} {
    if {[catch {
      dict set D inherits $cbase
      ClassValidate super $cname $cbase
    } msg]} {
      error "$msg" "class $cname"
    }
  }
  if {[string length $A(implements)]>0} {
    if {[catch {
      dict set D implements $A(implements)
      ClassValidate interface $cname $A(implements)
    } msg]} {
      error "$msg" "class $cname"
    }
  }
  if {[string length $A(abstracts)]>0} {
    if {[catch {
      dict set D abstracts $A(abstracts)
      ClassValidate interface $cname $A(abstracts)
    } msg]} {
      error "$msg" "class $cname"
    }
  }
  if {[string length $A(mixes)]>0} {
    if {[catch {
      dict set D mixes $A(mixes)
      ClassValidate mixin $cname $A(mixes)
    } msg]} {
      error "$msg" "class $cname"
    }
  }
  return $D
}

proc ::toe::_::MakeCommon {cname} {
  variable acls

  # get the class data
  set D $acls($cname)
  # get the creation script-as-template
  set script [dict get $D common model]
  if {[llength $script]>0} {
    # get the substitution values
    set cmd [subst {::[string trim [dict get $D common cmd] :]}]
    set ns [dict get $D common ns]
    # substitute
    set script "[join $script \n]"
    set script [string map "%@cmd@% $cmd %@ns@% $ns" $script]
    namespace eval $ns {}
    namespace eval $ns "$script"

    # add the common object to the objects list
    set i [objects::exact 1 $cmd]
    objects::insert [list $ns $cmd {} {}] $i
  }
  return
}

#
# internal: delete a class, including current instances of the class
#
proc ::toe::_::ClassDelete {ns cname} {
  variable acls
  variable aplcy

  # list the child namespaces (using the internal namespace naming convention)
  set objects [namespace children $ns {[0-9]*}]
  if {[llength $objects]} {
    foreach obj $objects {
      set i [ objects::exact 2 $obj ]
      # If the objects have inheritance dependencies, adverse side effects are possible
      # Control behavior with the "strict" policy
      # does this child namespace own instances? i>-1 => yes
      if {$i>-1} {
        if {$aplcy(strict)} {
          error "class deletion failed -- inheritance/ownership dependencies: $cname" "delete $cname"
        }
        # include deletion of this derived instance
        lappend objects [lindex [objects::get $i] 0]
      }
    }

    # delete instances of this class, and any inheriting instances
    foreach obj $objects {
      if {([string length "[info command $obj]"]>0)\
        && ([string length "[info command ${obj}::self]"]>0)} {
        set cmd [${obj}::self object]
        toe::_::delete $cmd
        set idx [objects::exact 1 $cmd]
        if {$idx>-1} {
          objects::remove $idx
        }
      }
    }
  }

  # delete any objects owned by the common object
  DeleteOwnedObjects $ns
  namespace delete $ns

  # purge the internal representation
  array unset acls $cname
  return
}

#
# internal: validate the option argument for the class
#
proc ::toe::_::ClassValidate {key cname first args} {
  switch -- $key {
    super {
      # validate the base class name as not null and currently registered
      variable acls
      set cbase [lindex $first 0]
      if {[string length "$cbase"]==0 } {
        error {null base class not allowed} "class $cname"
      }
      if {[string equal "$cbase" "$cname"]} {
        error "a class cannot inherit itself" "class $cname"
      }
      if {$cbase ni [array names acls]} {
        error "base class not found: $cbase" "class $cname"
      }
    }
    mixin {
      # validate the mixin names
      variable amxn
      set lMixins [concat $first $args]
      set lNames [array names amxn]
      foreach name $lMixins {
        if {[string length "$name"]==0} {
          error {null mixin not allowed}  "class $cname"
        }
        if { $name ni $lNames } {
          error "mixin not found: $name"  "class $cname"
        }
      }
    }
    interface {
      # validate the interface names
      variable aifc
      set lInterfaces [concat $first $args]
      if {[lsearch -exact $lInterfaces {}]>-1} {
        error {null interface not allowed}  "class $cname"
      }
      set lNames [ array names aifc ]
      foreach name $lInterfaces {
        if {$name ni $lNames} {
          error "interface not found: $name"  "class $cname"
        }
      }
    }
  }
  return
}

proc ::toe::_::Recompile {cname scope} {
  variable acls
  variable aInit

  set name [string trim $cname {:}]
  array set A [dict get $acls($cname)]
  set A($scope) $aInit($scope)
  set A(new) $aInit(new)
  Compile A $name $scope

  # save compiled data and make the common object
  set acls($name) [dict create {*}[array get A]]
  if {[string equal $scope {common}]} {
    MakeCommon $name
  }
  return
}

proc ::toe::_::Compile {a cname scope} {
  upvar 1 $a A
  variable acls
  variable aplcy

  # setup input and output dicts
  set X $A(declare)
  set Y $A($scope)

  switch -- $scope {
    common {
      # set and record the common namespace and command
      set ns [namespace parent]::$cname
      if {$aplcy(scoped)} {
        set cmd [namespace parent]::$cname
      } else {
        set cmd ::$cname
      }
      dict set Y ns $ns
      dict set Y cmd $cmd
    }
    dynamic {
      # retrieve the common namespace and command
      set ns [dict get $A(common) ns]
      set cmd [dict get $A(common) cmd]
    }
  }

  # build lists for ...
  #   variable names
  CompileVars $X Y $scope
  #   methods
  CompileMethods $X Y $scope $cname
  #   ensemble commands
  CompileMaps $X Y $scope $cname $ns $cmd
  # prepare the model
  CompileModel $X Y $scope $cname
  set A($scope) $Y
  return
}

proc ::toe::_::CompileVars {X y scope} {
  upvar 1 $y Y
  variable acls

  switch -- $scope {
    common {
      # accumulate the common sharedvars list
      dict for {access d} [dict get $X params common] {
        if {[llength $d]>0} {
          foreach name [dict keys $d] {
            dict lappend Y sharedvars [list {variable} $name]
          }
        }
      }
    }
    dynamic {
      # build lists for declared variables and variables to-be-inherited
      #
      #   accumulate a list of commands to declare the inherited variables
      set cbase [dict get $X inherits]
      if {[string length $cbase]>0} {
        set LL [dict get $acls($cbase) dynamic supervars]
        foreach L $LL {
          dict lappend Y sharedvars [list {variable} [lindex $L end]]
        }
        # copy down the public variables from the base class
        dict set Y publicvars [dict get $acls($cbase) dynamic publicvars]
      }

      #   accumulate a list of commands to declare the class variables
      set sharedvars [dict get $Y sharedvars]
      if {[llength $sharedvars]>0} {
        set inheritedvars [lsearch -all -inline -index 1 -subindices $sharedvars *]
      } else {
        set inheritedvars {}
      }

      dict for {access d} [dict get $X params dynamic] {
        if {[llength $d]>0} {
          set lnames [dict keys $d]
          foreach name $lnames {
            if {$name in $inheritedvars} {
              error [subst {inherited variable name already in use: $name}]
            }
            dict lappend Y sharedvars [list {variable} $name]
          }

          # accumulate as supervars the public and protected variable names
          if {![string equal $access {private}]} {
            foreach name $lnames {
              dict lappend Y supervars [list namespace upvar {%@bns@%} $name $name]
            }
          }
          if {[string equal $access {public}]} {
            set L [dict get $Y publicvars]
            lappend L {*}$lnames
            dict set Y publicvars [lsort -unique $L]
          }
        }
      }
    }
  }
  return
}

proc ::toe::_::CompileMethods {X y scope cname} {
  upvar 1 $y Y
  variable acls

  # setup
  set lInterfaces [dict get $X implements]
  # build a property table for all methods of interest: name origin access
  set LL [LLMethods $X $scope]

  switch -- $scope {
    common {
      foreach access {public private} {
        array set arr {}
        array unset arr *
        array set arr [GetMethodsArray $X Y common $access]
        if {[array size arr]>0} {
          Filters $X arr common
          InsertVars arr [dict get $Y sharedvars]
          dict set Y methods $access [array get arr]
        }
      }

      # impose interface conformance
      if {[llength $lInterfaces]>0} {
        set msg [CompileConform Y $lInterfaces $LL common $cname]
        if {[string length $msg]>0} {error $msg}
      }
    }
    dynamic {
      # accumulate base class exports for importing and command exports
      set cbase [dict get $X inherits]
      if {[string length $cbase]>0} {
        set L [dict get $acls($cbase) dynamic exports]
        foreach name $L {
          dict lappend Y imports "%@bns@%::$name"
          dict lappend Y exports $name
        }
        dict set Y exposes [dict get $acls($cbase) dynamic exposes]
      }

      # assemble the methods
      foreach access {public protected private} {
        array set arr {} ; array unset arr *
        set L [GetMethodsArray $X Y dynamic $access]
        array set arr $L
        if {[array size arr]>0} {
          Filters $X arr dynamic
          InsertVars arr [dict get $Y sharedvars]

          dict set Y methods $access [array get arr]
          if {[string equal $access {public}]} {
            # build "exposes" sub-dict
            foreach name [array names arr] {
              dict set Y exposes $name $cname
            }
          } else {
            # unexpose if more restricted access is encountered
            foreach name [array names arr] {
              if {[dict exists $Y exposes $name]} {
                dict unset Y exposes $name
              }
            }
          }
        }
      }

      # impose interface conformance
      if {[llength $lInterfaces]>0} {
        set msg [CompileConform Y $lInterfaces $LL dynamic $cname]
        if {[string length $msg]>0} {error $msg}
      }

      # accumulate abstract methods
      set lAbstracts [dict get $X abstracts]
      if {[llength $lAbstracts]>0} {
        CompileAbstracts Y $lAbstracts $cname
      }

      # populate the exports list
      set lnames [dict get $Y exports]
      lappend lnames {*}[dict keys [dict get $Y methods public]]
      lappend lnames {*}[dict keys [dict get $Y methods protected]]
      lappend lnames {*}[dict keys [dict get $Y virtuals]]
      dict set Y exports [lsort -unique [concat $lnames]]
    }
  }
  return
}

proc ::toe::_::CompileAbstracts {y lAbstracts cname} {
  variable aifc
  upvar 1 $y Y

  foreach aname $lAbstracts {
    set D [dict get $aifc($aname) dynamic]
    dict for {iname decl} $D {
      # "virtuals" accumulates proc declarations for the instance
      dict set Y virtuals $iname [concat proc $decl]
      dict lappend Y exports $iname
      dict set Y mymap $iname "%@dns@%::$iname"
    }
  }
}

# include class variables in methods without the "-novars" option
proc ::toe::_::InsertVars {m varslist} {
  variable aplcy
  upvar 1 $m M

  if { ([llength $varslist]>0) && (!$aplcy(novars)) } {
    set vars "[join $varslist \n]\n"
    foreach name [array names M] {
      set novars [lindex $M($name) 1]
      if {!$novars} {
        set body [lindex $M($name) 0 2]
        lset M($name) 0 2 "$vars$body"
      }
      set M($name) [lindex $M($name) 0]
    }
  } else {
    foreach name [array names M] {
      set M($name) [lindex $M($name) 0]
    }
  }
  return
}

# build a list-of-lists, for methods; columns: name source access nargs
proc ::toe::_::LLMethods {X scope} {
  variable acls
  variable amxn
  set res {}
  set laccess {private protected public}

  if {[string equal $scope {dynamic}]} {
    # inherited methods
    set cbase [dict get $X inherits]
    if {[string length $cbase]>0} {
      # skip private access
      foreach access [lassign $laccess -] {
        foreach name [dict keys [dict get $acls($cbase) dynamic methods $access]] {
          lappend res [list $name {base} $access 0]
        }
      }
    }
  }

  # native methods
  foreach access $laccess {
    set D [dict get $X methods $scope $access]
    foreach name [dict keys $D] {
      set params [lindex [dict get $D $name] 0 1]
      set nparams [NParams $params]
      lappend res [list $name {this} $access $nparams]
    }
  }

  # mixin methods
  set lMixins [dict get $X mixes]
  if {[llength $lMixins]>0} {
    foreach mname $lMixins {
      foreach name [dict get $amxn($mname) $scope,0] {
        lassign [dict get $amxn($mname) $name] access - params
        set nparams [NParams $params]
        lappend res [list $name {mixin} $access $nparams]
      }
    }
  }
  return $res
}

# helper for LLMethods
proc ::toe::_::NParams {lparams} {
  set nparams [llength $lparams]
  if {($nparams==1) && ([string equal $lparams {args}])} {set nparams -1}
  return $nparams
}

# require that all interface methods have an implementation
proc ::toe::_::CompileConform {y lInterfaces LL scope cname} {
  variable aifc
  variable aplcy
  upvar 1 $y Y

  set msg {}
  set triples {}

  # accumulate error messages for interface mismatches
  foreach iname $lInterfaces {
    dict for {mname decl} [dict get $aifc($iname) $scope] {
      lassign $decl access pname params body

      set i [lsearch -index 0 -exact $LL $pname]
      if {$i<0} {
        # interface method missing as a class method
        lappend triples [list {method not implemented:} $iname $pname]
      } elseif {"$access" ne "[lindex $LL $i 2]"} {
        # interface method and matching class method have mismatched access specifiers
        lappend triples [list {method not available:} $iname $pname]
      } elseif { (![string equal $params {args}]) && ([llength $params]!=[lindex $LL $i 3]) } {
        # arg counts mismatch
        lappend triples [list {method and interface arguments mismatch:} $iname $pname]
      }
    }
  }

  if {[llength $triples]>0} {
    set head [subst {in class $cname,}]
    if {[string equal $scope {common}]} {append head { common}}

    # selective error production
    if {$aplcy(strict)} {
      # for compile time reporting
      foreach triple $triples {
        lappend L "$head [join $triple { }]"
      }
      set msg "[join $L \n]"
    } else {
      # for delayed, execution time reporting; overwrite existing subcommands
      foreach triple $triples {
        set pname [lindex $triple 2]
        dict set Y cmdmap $pname [::list ::error "$head [join $triple { }]" ]
      }
    }
  }
  return "$msg"
}

proc ::toe::_::GetMethodsArray {X y scope access} {
  upvar 1 $y Y
  variable amxn

  # build an array, M, of class methods for the indicated access
  array set M [dict get $X methods $scope $access]

  # add mixin methods, possibly overriding
  foreach mixin [dict get $X mixes] {
    set MX [dict get $amxn($mixin)]
    set lMethodNames [dict get $MX $scope,0]
    foreach mname $lMethodNames {
      lassign [dict get $amxn($mixin) $mname] mxaccess - params body novars
      if {[string equal $mxaccess $access]} {
        set M($mname) [list [list $mname $params $body] $novars]
      }
    }
  }
  return [array get M]
}

proc ::toe::_::Filters {X arrname scope} {
  upvar 1 $arrname M
  variable amxn

  # add mixin methods, possibly overriding, and mixin filters
  foreach mixin [dict get $X mixes] {
    set MX [dict get $amxn($mixin)]

    # mixin filters
    set lFilterNames [dict get $amxn($mixin) $scope,1]
    foreach mxname $lFilterNames {
      if {[string equal $mxname {*}]} {
        set lTargets [array names M]
      } elseif {[info exists M($mxname)]} {
        set lTargets $mxname
      } else {
        continue
      }
      set spec [dict get $MX $mxname]
      foreach mname $lTargets {
        lassign $spec - - pre post
        set body [lindex $M($mname) 0 2]
        set body [concat ::toe::_::B \
          [list "\[ [string trim $pre] \]"] \
          [list "\[catch [list "$body" ] __msg__\]"] \
          [list "\[set __msg__\]"]\
          [list "\[ [string trim $post] \]"] ]
        lset M($mname) 0 2 "[join $body "\\\n"]"
      }
    }
  }
  return [array get M]
}

proc ::toe::_::CompileMaps {X y scope cname ns cmd} {
  upvar 1 $y Y
  variable acls
  variable aifc
  variable aplcy

  switch -- $scope {
    common {
      # update cmd and my map for the public methods
      foreach name [dict keys [dict get $Y methods public]] {
        dict set Y cmdmap $name ${ns}::$name
        dict set Y mymap $name ${ns}::$name
      }

      # add public variable access to the command maps
      dict set Y cmdmap variable [list ::toe::_::PublicVar $cname common $ns]

      # "self", for TclOO consistency
      dict set Y selfmap caller     [list ::toe::_::Caller $cmd ]
      dict set Y selfmap class      [list ::list $cname]
      dict set Y selfmap method     [list ::toe::_::Method $ns]
      dict set Y selfmap namespace  [list ::list $ns]
      dict set Y selfmap object     [list ::list $cmd]
      dict set Y selfmap methods    [list ::toe::_::Methods $ns]

      # enable "self" subcommand from the object command
      dict set Y cmdmap self ${ns}::self
    }
    dynamic {
      # access to base class through "next"
      set cbase [dict get $X inherits]
      if {"$cbase" ne ""} {
        dict set Y nsmap next [list ::toe::_::next %@ons@% %@bns@%]
      }

      # add public variable access to the command maps
      dict set Y cmdmap variable [list ::toe::_::PublicVar $cname dynamic %@ons@%]

      # add method names to the command maps
      foreach name [dict keys [dict get $Y methods public]] {
        dict set Y mymap $name $name
        dict set Y cmdmap $name $name
      }
      foreach name [dict keys [dict get $Y methods protected]] {
        dict set Y mymap $name $name
      }

      # accumulate interface constants
      set lInterfaces [ dict get $X implements]
      foreach intf $lInterfaces {
        set D [dict get $aifc($intf) consts]
        if {[dict size $D]>0} {
          dict for {n v} $D {
            dict set Y mymap $n $v
            dict set Y cmdmap $n $v
          }
        }
      }

      # external access to self
      dict set Y cmdmap self self

      # access to common variables
      dict set Y mymap common ::toe::_::CommonVar

      # access to common object
      dict set Y mymap $cname [list $cmd]

      # "self", for TclOO consistency
      dict set Y selfmap caller     [list ::toe::_::Caller %@cmd@% ]
      dict set Y selfmap class      [list ::list $cname]
      dict set Y selfmap method     [list ::toe::_::Method %@ons@%]
      dict set Y selfmap namespace  [list ::list %@ons@%]
      dict set Y selfmap object     [list ::list %@cmd@%]
      if { "[dict get $X inherits]" ne ""} {
        dict set Y selfmap next       [list ::toe::_::self_next %@ons@% %@bns@% %@bcmd@%]
      }

      # "self" supplemental, for this package
      dict set Y selfmap common     [list ::list $cmd]
      dict set Y selfmap super      [list ::list %@bcmd@%]
      dict set Y selfmap methods    [list ::toe::_::Methods %@ons@%]
      dict set Y selfmap variables  [list ::toe::_::Vars %@ons@%]
      dict set Y selfmap interfaces [list ::list [dict get $X implements]]
      dict set Y selfmap mixins     [list ::list [dict get $X mixes]]
      dict set Y selfmap abstracts  [list ::list [dict get $X abstracts]]
      dict set Y selfmap owner      [list ::toe::_::Owner %@ons@%]
      dict set Y selfmap owns       [list ::toe::_::Owns %@cmd@%]
    }
  }

  # access to a nested class common object
  set D [dict get $X inner]
  if {[dict size $D]>0} {
    foreach key [dict keys $D] {
      if {$aplcy(scoped)} {
        lappend model [list interp alias {} $key {} "${ns}::$key"]
        dict set Y mymap $key "${ns}::$key"
      } else {
        lappend model [list interp alias {} $key {} "::${cname}::$key"]
        dict set Y mymap $key "::${cname}::$key"
      }
    }
  }
  return
}

proc ::toe::_::CompileModel {X y scope cname} {
  upvar 1 $y Y
  variable acls
  variable aplcy

  set model [list]

  switch -- $scope {
    common {
      set ns [dict get $Y ns]
      set cmd [dict get $Y cmd]

      # check for an existing namespace
      if { [ namespace exists $ns ] } {
        if { !$aplcy(replaceClass) } {
          error "cannot replace existing class: $cname" "class $cname"
        }
        # permission to replace; expunge the old class and all dependencies
        ClassDelete $ns $cname
      }

      # common vars
      set lDecls [list]
      dict for {access D} [dict get $X params common] {
        lappend lDecls {*}[dict values $D ]
      }
      set s "[string trim [join $lDecls \n]]"
      if {[string length $s]>0} {
        lappend model $s
      }

      # common procs
      dict for {access D} [dict get $Y methods] {
        set L [dict values $D]
        foreach decl $L {
          lappend model [concat {proc} $decl]
        }
      }

      # namespace exports for the common object skipped: not supported

      # common ensembles
      lappend model [list namespace ensemble create -command my   -map [dict get $Y mymap]   -unknown ::toe::_::unrecognized ]
      lappend model [list namespace ensemble create -command self -map [dict get $Y selfmap] -unknown ::toe::_::unrecognized ]
      lappend model [list namespace ensemble create -command $cmd -map [dict get $Y cmdmap]  -unknown ::toe::_::unrecognized ]
      set nsmap [dict get $Y nsmap]
      if {[dict size $nsmap]>0} {
        lappend model [list namespace ensemble create           -map [dict get $nsmap]     -unknown ::toe::_::unrecognized ]
      }
    }
    dynamic {
      set cbase [dict get $X inherits]

      # accumulate base class vars and procs to import
      if {[string length $cbase]>0} {
        set L [dict get $acls($cbase) dynamic supervars]
        if {[llength $L]>0} {
          lappend model "[join $L \n]"
        }
        set L [dict get $Y imports]
        if { [llength $L]>0} {
          lappend model [list namespace import {*}$L]
        }
      }

      # accumulate class vars
      set D [dict get $X params dynamic]
      set lVars [list]
      dict for {access d} $D {
        lappend lVars {*}[dict values $d ]
      }
      if {[llength $lVars]>0} {
        set s "[join $lVars \n]"
        lappend model $s
      }

      # accumulate local procs
      dict for {access D} [dict get $Y methods] {
        set L [dict values $D]
        foreach decl $L {
          lappend model [concat {proc} $decl]
        }
      }
      # accumulate virtuals
      foreach {name decl} [dict values $Y virtuals] {
        lappend model $decl
      }
      # accumulate exports
      set L [dict get $Y exports]
      if {[llength $L]>0} {
        lappend model [list namespace export {*}$L]
      }
      # include a definition for "next"
      if {[string length $cbase]>0} {
        lappend model [list interp alias {} %@ons@%::next {} ::toe::_::next %@ons@% %@bns@%]
      }

      # accumulate ensembles, and maybe "next"
      lappend model [list namespace ensemble create -command my      -map [dict get $Y mymap]     -unknown ::toe::_::unrecognized]
      lappend model [list namespace ensemble create -command self    -map [dict get $Y selfmap]   -unknown ::toe::_::unrecognized]
      lappend model [list namespace ensemble create -command %@cmd@% -map [dict get $Y cmdmap]  -unknown ::toe::_::unrecognized]
      set nsmap [dict get $Y nsmap]
      if {[dict size $nsmap]>0} {
        lappend model [list namespace ensemble create -command %@ons@% -map [dict get $nsmap] -unknown ::toe::_::unrecognized]
      }
    }
  }
  dict set Y model $model
  return
}

# "curry" to "bracket" script b between scripts a and d, returning the value of c
proc ::toe::_::B {a b c d} {
  if {$b==2} {set b 0}
  return -level 2 -code $b -errorinfo "$::errorInfo" $c
}

#
# reset - reset all class variables to their initial values, and run the constructor;
# do the same for all ancestors;
# input arguments are supplied to the leaf constructor
#
proc ::toe::_::reset {cmd args} {
  variable acls
  variable aplcy

  set i [ ::toe::_::objects::exact 1 $cmd ]
  if {$i<0} { error "reset: object not found: $cmd" "reset $cmd" }
  set lns [list]
  while {$i>-1} {
    lassign [ ::toe::_::objects::get $i ] ns obj bns owner
    set cname [${ns}::self class]

    if {$aplcy(preventGarbage)} {
      # delete owned objects, most recent first
      DeleteOwnedObjects $ns
    }
    # unset all current variables
    unset -nocomplain -- {*}[ info vars ${ns}::* ]
    # initialize variables from class specification
    set decl {}
    dict for {access d} [dict get $acls($cname) declare params dynamic] {
      if {[dict size $d]>0} {
        lappend decl {*}[dict values $d *]
      }
    }
    if {[llength $decl]} {
      namespace eval $ns "[join $decl \n]"
    }

    lappend lns $ns
    # get the index of the next parent object
    set i [::toe::_::objects::exact 0 "$bns"]
  }

  # invoke the constructors, root first
  # but apply given arguments to only the tail constructor
  set ns [lindex $lns 0]
  foreach ons [lreverse [lrange $lns 1 end]] {
    namespace eval $ons {constructor}
  }
  namespace eval $ns [list constructor {*}$args]
  return
}

#
# "shallow" copy - copy an object to a new object of the same class.
# If the source object owns any other objects, they may be either
# adopted by the copy, or the ownership may be left unchanged, according to
# the value of the "adopt" flag; default is to leave the ownership unchanged.
#
proc ::toe::_::copy {obj adopt args} {
  set cls [$obj self class]
  set newobj [uplevel 2 ::toe::_::new $cls {*}$args]
  set sns [$obj self namespace]
  set ons [$newobj self namespace]
  foreach var [$obj self variables] {
    if {[array exists ${sns}::$var]} {
      array set ${ons}::$var [array get ${sns}::$var]
    } elseif {[info exists ${sns}::$var]} {
      set ${ons}::$var [set ${sns}::$var]
    }
  }
  if {$adopt} {
    # transfer ownership of owned objects to the new copy
    foreach ownee [$obj self owns] {
      toe::_::adopt $ownee $obj $newobj
    }
  }
  return $newobj
}

#
# clone (aka "deep" copy) - the source object is copied, and all objects that it owns,
# recursively, are copied, preserving ownership hierarchy among the copied objects.
# Class variables in the copied objects are scanned for owned object names,
# and patched with new object names.
# Notably, the classes of the owned objects do not need to reference this mixin.
#
proc ::toe::_::clone {cmd args} {
  # create a dict with the root and base objects as keys
  # and the list of objects that each one owns as values
  set Src [dict create $cmd [$cmd self owns]]
  set src $cmd
  while {[string length [$src self super]]>0} {
    set src [$src self super]
    dict set Src $src [$src self owns]
  }
  # copy the root object, and its hierarchy of objects,
  # but do nothing about owned objects
  # "copy" means that all constructors are run
  set newcmd [uplevel ::toe::_::copy $cmd 0 {*}$args]

  # if none of the sources own any objects,
  # then clone becomes copy, and we're done now.
  if {[llength [concat [dict values $Src]]]==0} {
    return $newcmd
  }

  # create a Dst dict corresponding to the Src dict
  # ultimately, the Dst dict will become populated to be
  # structurally identical to Src
  set Dst [dict create $newcmd [$newcmd self owns]]
  set dst $newcmd
  while {[string length "[$dst self super]"]>0} {
    set dst [$dst self super]
    dict set Dst $dst [$dst self owns]
  }

  # clone owned objects as needed for src/dst object pair,
  # starting at the root of the inheritance chain
  set Res $Dst
  foreach src [lreverse [dict keys $Src]] dst [lreverse [dict keys $Dst]] {
    set srcOwned [dict get $Src $src]
    set dstOwned [dict get $Dst $dst]
    # if nothing owned for this pair, continue
    if {[llength $srcOwned]==0 && [llength $dstOwned]==0} {continue}
    # setup for some owned object replication
    # initialize the object name substitution map
    set map [list]
    # get the namespaces for src and dst, which will own the new object
    set sns [$src self namespace]
    set ons [$dst self namespace]
    if {[llength $srcOwned]==0 || [llength $dstOwned]==0} {
      # if one list is null, but not the other, we optimize by ...
      if {[llength $dstOwned]==0} {
        # ... cloning all src-owned objects, for ownership by dst
        foreach obj $srcOwned {
          set newobj [::toe::_::clone $obj]
          toe::_::adopt $newobj [$newobj self owner] $dst
          lappend map $obj $newobj
        }
      } else {
        # ... deleting all dst-owned objects, possibly resulting from the ctor
        foreach obj $dstOwned {
          delete $obj
          lappend map $obj {}
        }
      }
    } elseif {[llength $srcOwned]==[llength $dstOwned]} {
      # if the two lists are of equal (non-zero) length, we optimize by
      # replacing objects as needed such that
      # the classes of owned objects are represented with equal frequency
      set diff [list]
      foreach obj1 [lsort $srcOwned] obj2 [lsort $dstOwned] {
        if {![string equal [$obj1 self class] [$obj2 self class]]} {
          delete $obj2
          set newobj [namespace inscope $ons ::toe::_::clone $obj1]
          lappend map $obj2 $newobj
        }
      }
    } else {
      # worst case - dst owns something, src owns something, but no wholesale match
      # count the objects in src by class
      array set arr {}
      if {[llength $srcOwned]<[llength $dstOwned]} {
        # count the objects in src by class
        foreach obj $srcOwned {
          incr arr([$obj self class])
        }
        # remove dst objects that have no matching class in src
        foreach obj $dstOwned {
          set cls [$obj self class]
          if {$cls in [array names arr]} {
            incr arr($cls) -1
            if {$arr($cls)==0} {array unset arr $cls}
          } else {
            delete $obj
            lappend map $obj {}
          }
        }
      } else {
        # new objects can be created in dst to match what's in src,
        # but nothing in the owner's class variables will reference the new object
        # count the objects in dst by class
        foreach obj $dstOwned {
          incr arr([$obj self class])
        }
        foreach obj $srcOwned {
          set cls [$obj self class]
          if {$cls in [array names arr]} {
            incr arr($cls) -1
            if {$arr($cls)==0} {array unset arr $cls}
          } else {
            namespace inscope $ons toe::_::new $cls
          }
        }
      }
    }
    # update the Res dict
    dict set Res $dst [$dst self owns]

    # apply the map to the dst object
    #
    # patch class variables for the command names,
    set pat "[join [dict keys $map] |]"
    foreach var [$dst self variables] {
      set asize [array size ${sns}::$var]
      if {$asize} {
        # "shimmer" to substitute command names
        set i 0
        while {[incr i]<100} {
          set sep [subst \\x0$i]
          set L [array get ${sns}::$var]
          set s [join $L $sep]
          if {[regexp $pat $s]>0} {
            set t [string map $map $s]
            set L [split $t $sep]
          }
          if {$L/2 == $asize} {
            array set ${ons}::$var $L
            break
          }
        }
      } else {
        # "shimmer" implicitly, since EIAS
        set ${ons}::$var [string map $map [set ${sns}::$var]]
      }
    }
  }
  # end of cloning across all src/dst objects
  # dicts Dst and Res should differ; dict Res should be a subset of dict Src

  return $newcmd
}

#
# Initialize this package
#
proc ::toe::_::Init {} {
  variable aInit
  variable aplcy
  variable aParser

  # create parsers in separate interpreters that are pseudo-uniquely and obscurely named
  set n [clock clicks]
  foreach p {Class Interface Mixin} {
    if { [info exists aParser($p)] } {
      interp delete $aParser($p)
    }
    set aParser($p) [list _${n}_${p}]
    interp create -safe -- $aParser($p)
  }

  # ensure deletion of slave interpreters if the array, aParser, is unset
  trace add variable [namespace current]::aParser {unset} [list\
    interp delete {*}[lsearch -all -inline [interp slaves] "_$n*"] \;\
    trace remove variable [namespace current]::aParser {unset}\
    ]

  # prepare error-handling
  set ::errorInfo {}
  if {!$aplcy(debug)} {
    # override ::error in this namespace
    proc ::toe::_::error {msg {info ""}} {
      return -level 2 -code error -errorinfo "$info" "$msg"
    }
  }

  # create the parsing interpreters
interp eval $aParser(Class) [string map [list %@ns@% [namespace parent] ] {
  interp alias {} Return {} _return

  namespace eval %@ns@%::_ {
    variable init 0
    variable dDefaults [ dict create \
      inner {} \
      params [list \
      common  [list public {} protected {} private {}]\
      dynamic [list public {} protected {} private {}]\
      ] \
      methods [list \
      common  [list public {} protected {} private {}]\
      dynamic [list public {} protected {} private {}]\
      ] \
      invalid {}\
      ]

    proc Init {args} {
      _variable init
      _variable dDefaults
      if {$init} {::unknown {parsing error on previous class}}
      set ::scope {dynamic}
      set ::access {public}
      set ::ctor 0
      set ::dtor 0
      set ::D $dDefaults
      set ::init 1
      Return
    }

    # ensure that a ctor and dtor are included
    proc Final {} {
      _variable init
      if {!$::ctor} { ::method constructor {args} {return} }
      if {!$::dtor} { ::method destructor {} {return} }
      set init 0
      if { [llength [dict get $::D invalid]]>0 } {
        _error [subst {invalid class element [dict get $::D invalid]}]
      }
      Return $::D
    }
  }

  # prime for Tcl's clock services
  clock seconds

  # inner class definitions
  # the inner class has no inheritance, interfaces or mixins
  proc ::class {args} {
    dict lappend ::D inner [lindex $args 0] [lindex $args end]
    Return
  }
  namespace eval %@ns@% {
    proc class {args} {
      dict lappend ::D inner [lindex $args 0] [lindex $args end]
    }
  }

  # common keyword handler
  proc ::common {args} {
    set ::scope {common}
    eval $args
    set ::scope {dynamic}
    Return
  }

  # modal scope setters; note the final ":" in the name
  proc ::common: {} {set ::scope {common};Return}
  proc ::object: {} {set ::scope {dynamic};Return}

  # modal access setters; note the final ":" in the name
  proc ::public: {args} {
    set ::access {public}
    eval $args
    Return
  }
  proc ::protected: {args} {
    set ::access {protected}
    eval $args
    Return
  }
  proc ::private: {args} {
    set ::access {private}
    eval $args
    Return
  }

  # individual access setters
  proc ::public {args} {
    set temp $::access; set ::access {public}
    eval $args
    set ::access $temp
    Return
  }
  proc ::protected {args} {
    set temp $::access; set ::access {protected}
    eval $args
    set ::access $temp
    Return
  }
  proc ::private {args} {
    set temp $::access; set ::access {private}
    eval $args
    set ::access $temp
    Return
  }

  # accumulate a variable declaration
  proc ::param {name {value __##__ }} {
    set decl [ list {variable} $name ]
    if { "$value" ne {__##__} } {
      lappend decl [subst -nocommands $value]
    }
    set d [dict get $::D params $::scope $::access]
    dict set ::D params $::scope $::access [lappend d $name $decl ]
    Return
  }

  proc ::constructor {args} {
    method constructor {*}$args
    Return
  }
  proc ::destructor  {args} {
    method destructor  {*}$args
    Return
  }

  # accumulate a method declaration
  proc ::method {args} {
    if { [llength $args]>3 } {
      set novars [string match [lindex $args 0] {-novars}]
      set decl [lrange $args 1 3]
      set name [lindex $decl 0]
    } else {
      set novars 0
      lassign {{} {} {return}} name arglist body
      lassign [lrange $args 0 2] name arglist body
      if {[string length $body]==0} {set body {return}}
      set decl [list $name "$arglist" "$body"]
    }

    switch -- $name {
      constructor {
        if { !$::ctor } {
          set ::ctor 1
          set d [dict get $::D methods dynamic private]
          dict set ::D methods dynamic private [lappend d \
            {constructor} [list $decl $novars] ]
        }
      }
      destructor {
        if { !$::dtor } {
          set ::dtor 1
          set d [dict get $::D methods dynamic private]
          dict set ::D methods dynamic private [lappend d \
            {destructor} [list $decl $novars] ]
        }
      }
      default {
        set d [dict get $::D methods $::scope $::access]
        dict set ::D methods $::scope $::access [lappend d \
          $name [list $decl $novars] ]
      }
    }
    Return
  }

  proc ::unknown {args} {
    dict lappend ::D invalid [concat $args]
    Return
  }
  namespace unknown ::unknown

  # last
  rename variable _variable
  rename param variable
  rename proc _proc
  rename error _error
  rename return _return
  rename rename _rename
}]

interp eval $aParser(Interface) [string map [list %@ns@% [namespace parent] ] {
  namespace eval %@ns@%::_ {
    proc Init {name} {
      set ::scope {dynamic}
      set ::access {public}
      set ::pname $name
      set ::D [ dict create common {} dynamic {} exports {} params {} consts {} ]
    }

    proc Final {} {
      return $::D
    }
  }

  # "common" option handler
  proc ::common {args} {
    set ::scope {common}
    eval $args
    set ::scope {dynamic}
  }

  # modal scope setters; note the final ":" in the name
  proc ::common: {} {set ::scope {common}}
  proc ::object: {} {set ::scope {dynamic}}


  # modal access setters; note the final ":" in the name
  proc ::public:    {args} {set ::access {public};{*}$args}
  proc ::protected: {args} {set ::access {protected};{*}$args}

  # individual access setters
  proc ::public {args} {
    set temp $::access; set ::access {public} ; eval $args
    set ::access $temp
  }
  proc ::protected {args} {
    set temp $::access; set ::access {protected} ; eval $args
    set ::access $temp
  }

  # accumulate the interface constants in a list
  proc ::param {name {value ""}} {
    dict lappend ::D params $name
    dict set ::D consts $::pname\($name\) [list ::list "$value"]
    return
  }

  # accumulate a method declaration; "-novars" is not allowed
  proc ::method {name {params ""}} {
    set body [ list ::error [subst {interface not implemented: ${::pname}::$name}] ]
    switch $::scope {
      common {
        dict set ::D common $name [ list public $name $params $body ]
      }
      dynamic {
        dict set ::D dynamic $name [ list $::access $name $params $body ]
        dict lappend ::D exports $name
      }
    }
    return
  }

  # last
  rename variable _variable
  rename param const
  rename proc _proc
}]

interp eval $aParser(Mixin) [string map [list %@ns@% [namespace parent] ] {
  namespace eval %@ns@%::_ {
    proc Init {args} {
      set ::scope {dynamic}
      set ::access {public}
      set ::D [ dict create common,0 {} dynamic,0 {} common,1 {} dynamic,1 {} ]
    }

    proc Final {} {
      return $::D
    }
  }

  # modal scope setters; note the final ":" in the name
  proc ::common: {} {set ::scope {common}}
  proc ::object: {} {set ::scope {dynamic}}

  # common keyword handler
  proc ::common {args} {
    set ::scope {common}
    eval $args
    set ::scope {dynamic}
  }

  # modal access setters; note the final ":" in the name
  proc ::public:    {args} {set ::access {public} ; eval $args}
  proc ::protected: {args} {set ::access {protected} ; eval $args}
  proc ::private:   {args} {set ::access {private} ; eval $args}

  # individual access setters
  proc ::public {args} {
    set temp $::access; set ::access {public} ; eval $args
    set ::access $temp
  }
  proc ::protected {args} {
    set temp $::access; set ::access {protected} ; eval $args
    set ::access $temp
  }
  proc ::private {args} {
    set temp $::access; set ::access {private} ; eval $args
    set ::access $temp
  }
  # accumulate a filter definition
  proc ::filter {args} {
    if {[lindex $args 0] eq {-novars}} {
      lassign $args - name arglist body
      set novars 1
    } else {
      lassign $args name arglist body
      set novars 0
    }
    dict set ::D $name [list $::access $name "$arglist" "$body" $novars ]
    dict lappend ::D $::scope,1 $name
    return
  }

  # accumulate a method definition
  proc ::method {args} {
    if {[lindex $args 0] eq {-novars}} {
      lassign $args - name arglist body
      set novars 1
    } else {
      lassign $args name arglist body
      set novars 0
    }
    if {[string length $body]==0} {set body {return}}
    dict set ::D $name [list $::access $name "$arglist" "$body" $novars ]
    dict lappend ::D $::scope,0 $name
    return
  }

  # last
  rename variable _variable
  rename proc _proc
}]

} ;# end proc Init


# Maps -
# return a formatted user list describing the ensemble maps for this class

proc ::toe::_::Maps {cls} {
  variable acls
  if {$cls ni [array names acls]} {
    error "class not found: $cls"
  }
  set res {}

  foreach scope {common dynamic} {
    set dMap [dict filter [dict get $acls($cls) $scope] key *map]
    set prefix [string map {common common dynamic instance} $scope]
    dict for {name map} $dMap {
      set key [string map {selfmap self cmdmap <command> mymap my nsmap <namespace>} $name]
      dict for {n v} $map { lappend res [list [list $prefix $key $n] "$v"] }
    }
  }
  return [Tabify $res]
}

proc ::toe::_::Models {cls} {
  variable acls
  if {$cls ni [array names acls]} {
    error "class not found: $cls"
  }
  set res {}

  foreach scope {common dynamic} {
    set model [dict get $acls($cls) $scope model]
    << "$cls $scope" join $model \n
  }
}

# Caller -
# return a triple of: <object command> <calling object's command> <calling object's method name>

proc ::toe::_::Caller {cmd} {
  set caller [info level -2]
  set ns [namespace qualifiers $caller]
  set ccmd [lindex [objects::get [objects::exact 0 $ns]] 1]
  return [list $cmd $ccmd [namespace tail $caller]]
}

proc ::toe::_::Owner {ns} {
  return [lindex [objects::get [objects::exact 0 $ns]] 3]
}

proc ::toe::_::Owns {cmd} {
  set res {}
  set rows [objects::match 3 $cmd]
  foreach row $rows {
    lappend res [lindex $row 1]
  }
  return $res
}

# Method -
# return the name of the method from which this proc was invoked

proc ::toe::_::Method {ns} {
  if { "$ns" ne "[uplevel 1 namespace current]" } {
    error {self method, but not in a method}
  }
  set name [info level -1]
  return [namespace tail $name]
}

# Methods -
# return a list of all method names in this namespace

proc ::toe::_::Methods {ns} {
  set L [namespace inscope $ns info procs *]
  return [lsort $L]
}

# Vars -
# return a list of all variable names in this namespace

proc ::toe::_::Vars {ns} {
  set res {}
  set L [info vars ${ns}::*]
  foreach var $L {
    lappend res [namespace tail $var]
  }
  return [lsort $res]
}

# next - call the same-named method in the base class, if it exists, else an error

proc ::toe::_::next {ns bns args} {
  if {[info level]< 1} {error {next: invalid calling frame}}
  set name [lindex [info level -1] 0]
  if { "$ns" ne "[namespace qualifiers $name]" } {
    error {next, but not in a valid method}
  }
  set mname [lindex [namespace tail $name] 0]
  if { "[info procs ${bns}::$mname]" eq "" } {
    error "next not found"
  }
  return [uplevel 1 ${bns}::$mname {*}$args]
}

# self_next -
# return a double of <base class object command> <method name>

proc ::toe::_::self_next {ns bns bcmd} {
  set name [info level -1]
  if { "$ns" ne "[namespace qualifiers $name]" } {
    error {next, but not in a valid method}
  }
  set mname [namespace tail $name]
  if { "[info proc ${bns}::$mname]" eq "" } {
    return
  }
  if {$mname in {constructor destructor}} {
    set mname "<$mname>"
  }
  return [list $bcmd $mname]
}

# Info -
# return a user list of items or associations for the named key and pattern

proc ::toe::_::Info {key {pattern *}} {
  variable acls
  variable aifc
  variable amxn
  variable aplcy

  set res {}
  switch -exact -- $key {
    classes    {set res [ lsort [array names acls $pattern] ]}
    interfaces {set res [ lsort [array names aifc $pattern] ]}
    mixins     {set res [ lsort [array names amxn $pattern] ]}
    common     {
      set lnames [ array names acls $pattern ]
      if {[llength $lnames]>0} {
        lassign $lnames name
        set res [dict get $acls($name) common cmd]
      }
    }
    objects {
      set lnames [array names acls $pattern]
      foreach name $lnames {
        set L [dict get $acls($name) common cmd]
        foreach tuple [ ::toe::_::objects::match 1 *$name\#* ] {
          lappend L [lindex $tuple 1]
        }
        if {[llength $L]} {
          lappend res $name $L
        }
      }
    }
    implemented {
      set lnames [ array names aifc $pattern ]
      foreach name $lnames {
        set L {}
        foreach {cname D} [ array get acls ] {
          if {$name in [ dict get $D declare implements ]} {
            lappend L $cname
          }
        }
        if {[llength $L]} {lappend res $name $L}
      }
    }
    abstracted {
      set lnames [ array names aifc $pattern ]
      foreach name $lnames {
        set L {}
        foreach {cname D} [ array get acls ] {
          if {$name in [dict get $D declare abstracts]} {
            lappend L $cname
          }
        }
        if {[llength $L]} {lappend res $name $L}
      }
    }
    mixed {
      set lnames [array names amxn $pattern]
      foreach name $lnames {
        set L {}
        foreach {cname D} [ array get acls ] {
          if {$name in [dict get $D declare mixes]} {
            lappend L $cname
          }
        }
        if {[llength $L]} {lappend res $name $L}
      }
    }
    inherited {
      set lnames [ array names acls $pattern ]
      foreach name $lnames {
        set L {}
        foreach {cname D} [ array get acls ] {
          if {$name in [ dict get $D declare inherits ]} {
            lappend L $cname
          }
        }
        if {[llength $L]} {lappend res $name $L}
      }
    }
    ancestors {
      set lnames [ array names acls $pattern ]
      if {[llength $lnames]>0} {
        foreach name $lnames {
          lappend res $name
          set L {}
          while { "[set name [ dict get $acls($name) declare inherits ]]" ne "" } {
            lappend L $name
          }
          lappend res $L
        }
      } else {
        set lNames [::toe::_::objects::subindices 1 $pattern]
        foreach name $lNames {
          lappend res $name
          set L {}
          set name [$name self super]
          while {[string length $name]>0} {
            lappend L $name
            set name [$name self super]
          }
          lappend res $L
        }
      }
    }
    default {
      error [subst {invalid key: $key;  must be among: classes,interfaces,mixins,ancestors,objects,inherited,implemented,abstracted,mixed}]
    }
  }
  return $res
}

# runtime
proc ::toe::_::api {cname} {
  variable acls
  if { ![ info exists acls($cname) ] } {
    error "class not defined: $cname" "api $cname"
  }
  set res [ list "class $cname" ]

  # setup
  set dVar [dict create]
  set dProc [dict create]
  set D [dict get $acls($cname)]
  set lChain {}

  # handle base classes, if any
  set base [ dict get $D declare inherits ]
  if {[string length $base]>0} {
    lappend res "  inherits $base"
    while {[string length $base]>0} {
      lappend lChain $base
      set base [ dict get $acls($base) declare inherits ]
    }
    foreach base [lreverse $lChain] {
      set dVar  [dict merge $dVar  [ Api vars  $acls($base) $base ]]
      set dProc [dict merge $dProc [ Api procs $acls($base) $base ]]
    }
  }

  # variables
  set L [Api vars $D]
  if {[llength $L]>0} {set dVar [ dict merge $dVar $L ]}

  # methods
  set L [ Api procs $D ]
  if {[llength $L]>0} {set dProc [ dict merge $dProc $L ]}

  # wrapup - accumulate
  foreach name [lsort [dict keys $dVar]] {
    lappend res [dict get $dVar $name]
  }
  foreach name [lsort [dict keys $dProc]] {
    lappend res [dict get $dProc $name]
  }
  # return a user list for interactive reading
  join $res \n
}

# runtime
proc ::toe::_::Api {opt D {base 0}} {
  set X [dict get $D declare]
  set Y [dict get $D common]
  set Z [dict get $D dynamic]
  set res [dict create]
  switch -- $opt {
    vars {
      foreach {name decl} [dict get $X params common public] {
        dict set res $name [subst {  common variable $name}]
      }
      foreach access {public protected} {
        foreach {name decl} [ dict get $X params dynamic $access ] {
          dict set res $name [subst {         variable $name}]
        }
      }
    }
    procs {
      dict for {name decl} [ dict get $Y methods public ] {
        lassign $decl - arglist
        dict set res $name [subst {  common public method $name [ list "$arglist" ]}]
      }
      foreach access {public protected} {
        set d [ dict get $Z methods $access ]
        dict for {name decl} $d {
          lassign $decl - arglist
          dict set res $name [subst {         $access method $name [ list "$arglist" ]}]
        }
      }
    }
  }
  if {$base!=0} {
    foreach name [ dict keys $res ] {
      dict append res $name [subst {\t(in: class $base)}]
    }
  }
  return $res
}

# Llwidths - help Tabify by listing the longest string length for each column
proc ::toe::_::Llwidths {ll} {
  set res [list]
  set D [dict create]
  foreach row $ll {
  set col -1
  foreach item $row {
    dict lappend D [incr col] [string length $item]
  }
  }
  foreach L [dict values $D] {
  lappend res [lindex [lsort -integer $L] end]
  }
  return $res
}

# Tabify - format a list of lists into a justified set of columns
proc ::toe::_::Tabify {ll {sep "\t"}} {
  set widths [Llwidths $ll]
  set ncolumns [llength $widths]
  set null [lrepeat $ncolumns {}]
  set last [expr {$ncolumns-1}]
  set fmt [subst {%-[join $widths "s$sep%-" ]s}]
  foreach row $ll {
    set L [lrange [concat $row $null] 0 $last]
    lappend res "[format $fmt {*}$L ]"
  }
  return [join $res \n]
}

#
# new - instantiate a new object for the named class
#
proc ::toe::_::new {cname args} {
  variable acls
  variable aplcy

  # set a flag for the -local option
  set local 0
  if {[string first $cname {-local}]==0} {
    set local 1
    set args [lassign $args cname]
  }

  # designate a possible owner of this instance
  set ns [uplevel 1 namespace current]
  set idx [::toe::_::objects::exact 0 $ns]

  # the namespace may correspond to a current instance
  set owner {}
  if {$idx>-1} {
    # Designate the owner of this new instance;
    # If the caller is an object, then it owns this new object
    set owner [lindex [::toe::_::objects::get $idx] 1]
  }

  if {![info exists acls($cname)]} {
    # adjust cname for an inner class
    set FAIL 1
    if {("$ns" ne {::}) && ($idx > -1)} {
      set j [::toe::_::objects::exact 0 $ns]
      if {$j>-1} {
        set cname [namespace tail [namespace parent $ns]]::$cname
        set FAIL 0
      }
    }
    if {$FAIL} {error "class undefined: $cname" "new $cname"}
  }

  #
  # get the inheritance chain, this class first, root class last
  #
  set cbase $cname
  set lClasses [dict get $acls($cname) new chain]
  if {[llength $lClasses]==0} {
    set lClasses $cbase
    set cbase [dict get $acls($cbase) declare inherits]
    set len [string length $cbase]
    while {$len>0} {
      lappend lClasses $cbase
      set cbase [dict get $acls($cbase) declare inherits]
      set len [string length $cbase]
    }
    # cache the list in the internal class data
    dict set acls($cname) new chain $lClasses
  }

  #
  # instantiate objects for the inheritance hierarchy, root class first
  #
  lassign {{} {} {}} bname ons cmd
  set ancestor [list $bname $ons $cmd]
  set lNamespaces [list]
  set level [llength $lClasses]

  foreach bname [lreverse $lClasses] {
    incr level -1
    lassign [New $bname $ancestor $level] bns ons cmd
    # accumulate the object
    set idx [::toe::_::objects::exact 0 $ons]
    set row [list $ons $cmd "$bns" $owner]
    ::toe::_::objects::insert $row $idx
    lappend lNamespaces $ons
    # prep for the next derived class
    set ancestor [list $bname $ons $cmd]
  }

  # assign initial ownership for this instance
  # define "__local__" in the caller's context, to attach a cleanup trace
  if {([string length $owner]>0) && ($local!=0)} {
    upvar 1 __local__ __local__
    set __local__ 0
    if {$aplcy(preventGarbage)} {
      # trigger a call to DeleteLocal when __local__ is unset, i.e., upon exit from proc
      trace add variable __local__ unset [list ::toe::_::DeleteLocal $cmd]
    }
  }

  # modify the cmdmap for inherited methods
  set D [dict get $acls($cname) dynamic exposes]
  if {[dict size $D]>0} {
    foreach cls $lClasses ns [lreverse $lNamespaces] {
      set A($cls) $ns
    }
    set map [namespace ensemble configure $cmd -map]
    dict for {name cls} $D {
      set ns $A($cls)
      dict set map $name "${ns}::$name"
    }
    namespace ensemble configure $cmd -map $map
  }

  # invoke the constructors, root first,
  #  using the input arguments for the leaf only
  set tail [lindex $lNamespaces end]
  foreach ons [lrange $lNamespaces 0 end-1] {
    ${ons}::constructor
  }
  ${tail}::constructor {*}$args

  # return the external command to invoke this instance
  return $cmd
}

#
# New: configure the namespace for this instance
#
proc ::toe::_::New {cname ancestor level} {
  variable acls
  variable aifc
  variable aplcy

  lassign $ancestor bname bns bcmd
  # bump the instance counter
  set count [dict get [dict incr acls($cname) count] count]

  # create the namespace name and the command name for the new instance
  # WARNING: these names are volatile and should not be hacked

  set ns [dict get $acls($cname) common ns]
  set ons "${ns}::$count"
  if {$aplcy(scoped)} {
    set cmd "[namespace parent]::${cname}#$count"
  } else {
    set cmd "::${cname}#$count"
  }

  # get the instance model
  set model [dict get $acls($cname) dynamic model]

  # if this implements AND inherits, and its base abstracts, then more prep
  if {([string length $bname]>0) && ([string length $bns]>0)} {
    set lImplements [dict get $acls($cname) declare implements]

    if {[llength $lImplements]>0} {
      set lAbstracts [dict get $acls($bname) declare abstracts]

      if {[llength $lAbstracts]>0} {
        set dMy [namespace ensemble configure ${bns}::my -map]
        set dirty 0
        #
        # implement down-calling for abstracted methods
        # patch namespace $bns for the methods in each interface of lMatches
        # to call their counterparts in namespace $ons
        #
        foreach item $lImplements {
          if {$item in $lAbstracts} {
            dict for {name decl} [dict get $aifc($item) dynamic] {
              namespace inscope $bns proc $name args [concat my $name {{*}$args}]
              dict set dMy $name "${ons}::$name"
            }
            incr dirty
          }
        }
        if {$dirty} {
          namespace ensemble configure ${bns}::my -map $dMy
        }
      }
    }
  }

   # if not in debug mode, use the runtime error proc
  if {!$aplcy(debug)} {
    lappend model [list interp alias {} %@ons@%::error {} ::toe::_::error]
  }

  # patch the model for this instance
  set map [list {%@bns@%} "$bns" {%@ons@%} "$ons" {%@cmd@%} "$cmd" {%@bcmd@%} "$bcmd"]

   set script [string map $map [join $model \n]]

  # populate the namespace and ensembles
  namespace eval $ons {}
  namespace eval $ons $script
  return [list $bns $ons $cmd]
}

namespace eval ::toe::_::objects {
# a list of 4-tuples, one for each object, consisting of: <ns cmd super-ns owner>
# ns and cmd are guaranteed unique; super-ns and owner may be null or replicate
  variable count 0
  variable D [dict create]
  variable A; array set A {}
  variable B; array set B {}

# insert a 4-tuple; idx>-1 => replace
proc insert {tuple {idx -1}} {
  variable count
  variable D
  variable A
  variable B

  if {$idx<0} {
    dict set D [incr count] $tuple
    lassign $tuple a b
    set A($a) $count ; set B($b) $count
  } else {
    if {[dict exists $D $idx]} {
      lassign [dict get $D $idx] a b
      array unset A $a ; array unset B $b
    }
    dict set D $idx $tuple
    lassign $tuple a b
    set A($a) $idx ; set B($b) $idx
  }
  return
}

proc remove {idx} {
  variable A
  variable B
  variable D
  if {[dict exists $D $idx]} {
    lassign [dict get $D $idx] a b
    dict unset D $idx
    array unset A $a
    array unset B $b
  }
  return
}

# return the index, given a column index and the exact pattern to match
proc exact {col pat} {
  variable count
  variable D
  variable A
  variable B

  switch $col {
    0 {
      if {[info exists A($pat)]} {
        return $A($pat)
      } else {
        return -1
      }
    }
    1 {
      if {[info exists B($pat)]} {
        return $B($pat)
      } else {
        return -1
      }
    }
    2 - 3 {
      set i [lsearch -exact -index $col [dict values $D] $pat]
    }
  }
  if {$i>-1} {
    return [lindex [dict keys $D] $i]
  } else {
    return -1
  }
}

# return all indices, given a column index and a matching pattern
proc match {col pat} {
  variable D
  variable A
  variable B

  set res {}
  switch $col {
    0 {foreach {n v} [array get A $pat] {lappend res $v}}
    1 {foreach {n v} [array get B $pat] {lappend res $v}}
    2 - 3 {
      set res [lsearch -all -inline -index $col [dict values $D] $pat]
    }
  }
  return $res
}

# return all indices, given a column index and the exact pattern to match
proc matchexact {col pat} {
  variable D
  variable A
  variable B

  set res {}
  switch $col {
    0 {foreach {n v} [array get A $pat] {lappend res $v}}
    1 {foreach {n v} [array get B $pat] {lappend res $v}}
    2 - 3 {
      set res [lsearch -all -exact -inline -index $col [dict values $D] $pat]
    }
  }
  return $res
}

proc subindices {col pat} {
  variable D
  return [lsearch -all -inline -index $col -subindices [dict values $D] $pat]
}

# return a row, given a row index
proc get {n} {
  variable D
  return [dict get $D $n]
}

# replace item 3 in the row where pat matches to the item in column 1
proc replace3 {pat old new} {
  variable A
  variable B
  variable D
  if {![info exists B($pat)]} {return 0}
  set tuple [dict get $D $B($pat)]
  if {"[lindex $tuple 3]" ne  "$old"} {return 0}
  lset tuple 3 $new
  dict set D $B($pat) $tuple
  return 1
}

# revise a cell, given its row and column indices
proc put3 {idx val} {
  variable D
  set tuple [dict get $D $idx]
  lset tuple 3 $val
  dict set D $idx $tuple
  return
}

proc show {} {
  variable D
  set res [list]
  foreach row [dict values $D] {
    lappend res "[join $row \t]"
  }
  return [join $res \n]
}
}

#
# Revision means to perform an insert or replace action on an element.
#
proc ::toe::_::revise {args} {
  variable aArgs
  variable aplcy

  # check if enabled
  if {!$aplcy(revise)} {error {toe revise is disabled}}

  ParseArgs $args

  # validate the arguments
  lassign [ValidateEntityExists $aArgs(entity) $aArgs(ename) $aArgs(target)] OK msg
  if {!$OK} {error "$msg"}

  # adjust the entity of interest, if indirectly identified
  if {("$aArgs(entity)" eq {object}) && ([llength $aArgs(ename)]>1)} {
    set aArgs(ename) $msg
  } elseif {[string length $msg]>0} {
    set aArgs(ename) $msg
  }

  if {$aArgs(entity) eq {class} && $aArgs(target) eq {} } {
    # just recompile the named class
    Recompile $aArgs(ename) common
    Recompile $aArgs(ename) dynamic
  } else {
    # explicit revision of some entity
    #
    # validate existence of the target
    lassign [ValidateTargetExists] found msg

    # dispatch to revise
    switch $aArgs(entity) {
      class {ReviseClass $found}
      object {ReviseObject $found}
      interface {ReviseInterface $found}
      mixin {ReviseMixin $found}
    }
  }
}

proc ::toe::_::ReviseObject {found} {
  variable aArgs
  variable acls

  # setup
  set obj $aArgs(ename)
  set tname $aArgs(tname)
  set scope $aArgs(scope)
  set i [ ::toe::_::objects::exact 1 $obj ]

  # get the namespace and class and common state for this object
  set ns [lindex [::toe::_::objects::get $i] 0]
  set cname [$obj self class]

  switch $aArgs(target) {
    method {
      set vars "[join [dict get $acls($cname) $scope sharedvars] \n]"
      if {$found} {
        # get the proc's argument list and novars state from the internal rep
        set cname [$obj self class]
        dict for {access d} [dict get $acls($cname) declare methods $scope] {
          if {$tname in [dict keys $d]} {break}
        }
        set pair [dict get $acls($cname) declare methods $scope $access $tname]
        set params [lindex $pair 0 1]
        set novars [lindex $pair 1]
        # adjust the proc body, if necessary
        if {$novars} {
          set body $aArgs(body)
        } else {
          set body "[join [list $vars $aArgs(body)] \n]"
        }

        # put the new/revised proc in the namespace
        namespace inscope $ns proc $tname "$params" "$body"
        # update the ensemble commands
        if {[string equal $access {public}]} {
          set map [namespace ensemble configure $obj -map]
          dict set map $tname ${ns}::$tname
          namespace ensemble configure $obj -map $map
          set map [namespace ensemble configure ${ns}::my -map]
          dict set map $tname ${ns}::$tname
          namespace ensemble configure ${ns}::my -map $map
        }
      }
    }
    variable {
      namespace inscope $ns variable $tname $aArgs(params)
    }
  }
}

proc ::toe::_::ReviseClass {found} {
  variable aArgs
  variable acls
  variable aInit

  # setup
  set cname $aArgs(ename)
  set X [dict get $acls($cname) declare]
  set tname $aArgs(tname)
  set scope $aArgs(scope)
  set access $aArgs(access)

  switch $aArgs(target) {
    method {
      if {$found} {
        dict for {access1 d} [dict get $X methods $scope] {
          if {$tname in [dict keys $d]} {break}
        }
        if {$access1 != $access} {
          error "revise cannot change method access: $cname $tname"
        }
      }

      set decl [list $aArgs(tname) $aArgs(params) $aArgs(body)]
      dict set X methods $scope $access $tname [list $decl 0]
    }
    variable {
      if {$found} {
        dict for {access1 d} [dict get $X params $scope] {
          if {$tname in [dict keys $d]} {break}
        }
      }
      if {$access1 != $access} {
        error "revise cannot change variable access: $cname $tname"
      }

      set decl [list variable $aArgs(tname) $aArgs(params)]
      dict set X declare params $scope $access $aArgs(tname) $decl
    }
    inherits {
      dict set X inherits "[lindex $tname 0]"
      dict set acls($cname) new chain {}
    }
    implements {
      dict set X implements $tname
    }
    mixes {
      dict set X mixes $tname
    }
    abstracts {
      dict set X abstracts $tname
    }
  }
  # wrapup
  dict set acls($cname) declare $X
  toe::_::Recompile $cname $scope
  return
}

proc ::toe::_::ReviseInterface {found} {
  variable aArgs
  variable aifc

  # setup
  set ename $aArgs(ename)
  set tname $aArgs(tname)
  set scope $aArgs(scope)
  set I $aifc($ename)
  set access $aArgs(access)

  switch -- $aArgs(target) {
    method {
      if {$found} {
        foreach scope1 {common dynamic} {
          if {[dict exists $I $scope1 $tname]} {
            if {$scope1 != $scope} {
              error [subst {revise cannot change from $scope1 to $scope: $ename $tname}]
            }
          }
          break
        }
      }
      set body [ list ::error "interface not implemented: $ename $tname" ]
      set decl [ list $access $tname $aArgs(params) $body ]
      dict set I $scope $tname $decl
    }
    constant {
      set name "$ename\($tname\)"
      set value [list ::list "$aArgs(params)" ]
      if {$tname in [dict get $I params]} {
        # replace
        set L [dict get $I consts]
        set i [lsearch -glob $L *$tname*]
        set L [lreplace $L $i [incr i] $name $value]
        dict set I consts $L
      } else {
        # insert
        dict lappend I consts $name $value
        dict lappend I params $tname
      }
    }
  }
  # wrapup
  set aifc($ename) $I
  return
}

proc ::toe::_::ReviseMixin {found} {
  variable aArgs
  variable amxn

  # setup
  set ename $aArgs(ename)
  set tname $aArgs(tname)
  set scope $aArgs(scope)
  set access $aArgs(access)
  set M $amxn($ename)

  set filter [string equal $aArgs(target) {filter}]

  set novars 0
  if {$ename in [dict get $M $scope,$filter]} {
    set novars [lindex [dict get $M $ename] end]
  }
  if {$filter} {
    set decl [list $access $tname $aArgs(pre) $aArgs(post)]
  } else {
    set decl [list $access $tname $aArgs(params) $aArgs(body)]
  }
  # wrapup
  dict set M $tname [concat $decl $novars]
  if {$tname ni [dict get $M $scope,$filter]} {
    dict lappend M $scope,$filter $tname
  }
  set amxn($ename) $M
  return
}

proc ::toe::_::ValidateTargetExists {} {
  variable aArgs
  variable acls
  set res {}

  # locate the named target
  # ( note multiple exit points )
  set entity $aArgs(entity)
  set ename $aArgs(ename)
  set target $aArgs(target)
  set tname $aArgs(tname)
  set scope $aArgs(scope)

  switch $entity,$target {
    class,method {
      set matched 0
      dict for {access d} [dict get $acls($ename) declare methods $scope] {
        if {$tname in [dict keys $d]} {
          set matched 1
          set res [list declare methods $scope $tname]
          break
        }
      }
      if {!$matched} {
        return [list 0 [subst {method not found in class $ename : $tname}]]
      }
    }
    object,method {
      set obj $aArgs(ename)
      set ns [$obj self namespace]
      if {"[info procs ${ns}::$tname]" eq {}} {
        return [list 0 [subst {method not found in object $ename : $tname}]]
      }
      set res [list $obj]
    }
    class,variable {
      set matched 0
      dict for {access d} [dict get $acls($ename) declare params $scope] {
        if {$tname in [dict keys $d]} {
          set matched 1
          set res [list declare params $scope $tname]
          break
        }
      }
      if {!$matched} {
        return [list 0 [subst {variable not found in class $ename : $tname}]]
      }
    }
    object,variable {
      set obj $aArgs(ename)
      set ns [$obj self namespace]
      if {[string length [info vars ${ns}::$tname]]==0} {
        return [list 0 [subst {variable not found in object $ename : $tname}]]
      }
      set res [list $obj]
    }
    interface,constant {
      variable aifc
      set lNames [dict get $aifc($ename) params]
      if {$tname ni $lNames} {
        return [list 0 [subst {constant not found in interface $ename : $tname}]]
      }
      set res [list consts "$aArgs(ename)\($tname\)"]
    }
    interface,method {
      variable aifc
      if { ![dict exists $aifc($ename) $scope $tname] } {
        return [list 0 [subst {method not found in $entity : $tname}]]
      }
      set res [list $scope $tname]
    }
    mixin,method {
      variable amxn
      set lNames [dict get $amxn($ename) $scope,0]
      if {$tname ni $lNames} {
        return [list 0 [subst {method not found in $entity : $tname}]]
      }
      set res $tname
    }
    mixin,filter {
      variable amxn
      set lNames [dict get $amxn($ename) $scope,1]
      if {$tname ni $lNames} {
        return [list 0 [subst {filter not found in $entity : $tname}]]
      }
      set res $tname
    }

    class,inherits -
    class,implements -
    class,mixes -
    class,abstracts {
      variable acls
      set res [dict get $acls($ename) declare $target]
    }
    default {error [subst {invalid entity/target combination: $entity $target}]}
  }
  return [list 1 $res]
}

proc ::toe::_::ValidateEntityExists {entity ename target} {
  set res {}
  switch $entity {
    class {
      variable acls
      lassign $ename name
      if {$name ni [array names acls]} {
        return [list 0 [subst {class not found: $name}]]
      }
      if {$target in {method variable} && [llength $ename]>1} {
        set inner [join $ename {::}]
        if {"$inner" ni [array names acls]} {
          return [list 0 [subst {inner class not found: $inner}]]
        }
        set res $inner
      }
    }
    interface {
      variable aifc
      lassign $ename name
      if {$name ni [array names aifc]} {
        return [list 0 [subst {interface not found: $name}]]
      }
    }
    mixin {
      variable amxn
      lassign $ename name
      if {$name ni [array names amxn]} {
        return [list 0 [subst {mixin not found: $name}]]
      }
    }
    object {
      set ename [lassign $ename obj]
      set n [objects::exact 1 $obj]
      if {$n<0} {
        return [list 0 [subst {object not found: $obj}]]
      }
      # maybe the object is for a base class of the given object;
      # walk up the class inheritance to find a class name match
      if {[llength $ename]>0} {
        lassign $ename name
        variable acls
        set cname [$obj self class]
        set ons [$obj self namespace]
        while {1} {
          set bname [dict get $acls($cname) declare inherits]
          set bns [lindex [objects::get 0 $ons] 2]
          if {[string length $bname]==0} {
            return [list 0 [subst {base class not found: $obj $name}]]
          }
          if {[string equal $bname $name]} {
            set obj [lindex [objects::get 0 $bns] 1]
            set res $obj
            break
          }
          set ons $bns
          set cname $bname
        }
      }
    }
  }
  return [list 1 $res]
}

proc ::toe::_::ParseArgs {arglist} {
  variable aArgs
  array set aArgs [list entity {} ename {} target {} tname {} \
    access {public} scope {dynamic} params {} pre {} post {} body {}]

  # the first two fields are not ambiguous
  set spec [lassign $arglist aArgs(entity) aArgs(ename) ]
  # the next two fields may be 0,1, or more access and scope specifiers
  while {[lindex $spec 0] in {public protected private common}} {
    set spec [lassign $spec key]
    if {[string equal $key {common}]} {
      set aArgs(scope) $key
    } else {
      set aArgs(access) $key
    }
  }
  set spec [lassign $spec aArgs(target) aArgs(tname)]

  switch -- $aArgs(entity),$aArgs(target) {
    class, {return}
    class,method -
    mixin,method -
    object,method {
      if {[llength $spec]<2} {
        error [subst {missing arguments for the method specification: $aArgs(entity) $aArgs(target)}]
      }
      lassign $spec aArgs(params) aArgs(body)
    }
    interface,method -
    mixin,filter {
      lassign $spec aArgs(pre) aArgs(post)
    }
    interface,constant {
      if {[llength $spec]<1} {
        error [subst {missing argument for the constant value: $aArgs(entity) $aArgs(target)}]
      }
      lassign $spec aArgs(params)
    }
    class,variable -
    object,variable {
      lassign $spec aArgs(params)
    }
    class,inherits -
    class,implements -
    class,mixes -
    class,abstracts {}
    default {
      error [subst {invalid entity/target combination: $aArgs(entity) $aArgs(target)}]
    }
  }
}
::toe::_::Init
package provide toe 1.0


