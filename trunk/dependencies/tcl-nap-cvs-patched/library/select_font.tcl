# select_font.tcl --
#
# Font selection dialog.
#
# Based on Brent Welch's 3rd edition CD Example 39-4
# Modified by Harvey Davies, CSIRO.
# $Id: select_font.tcl,v 1.4 2004/10/21 00:20:04 dav480 Exp $

proc select_font {
    parent
    label
    varname
} {
    upvar $varname f
    catch {font delete old_fontsel}
    eval font create old_fontsel [font actual $f]
    set top [create_window tmp $parent NW $label]
    FontReset
    Font_Select $top
    destroy $top
    set f $::font(name)
}


proc Font_Select {{top .fontsel}} {
	global font

	# Create Font, Size, and Format menus

	set menubar [menu $top.menubar]
	$top config -menu $menubar
	foreach x {Font Size Format} {
		set menu [menu $menubar.[string tolower $x]]
		$menubar add cascade -menu $menu -label $x
	}

	# The Fonts menu lists the available Font families.

	set allfonts [lsort [font families]]
	set numfonts [llength $allfonts]
	set limit 20
	if {$numfonts < $limit} {

		# Display the fonts in a single menu

		foreach family $allfonts {
			$menubar.font add radio -label $family \
				-variable font(-family) \
				-value $family \
				-command FontUpdate
		}
	} else {

		# Too many fonts. Create a set of cascaded menus to 
		# display all the font possibilities

		set c 0 ; set l 0
		foreach family $allfonts {
			if {$l == 0} {
				$menubar.font add cascade -label $family... \
					-menu $menubar.font.$c
				set m [menu $menubar.font.$c]
				incr c
			}
			$m add radio -label $family \
				-variable font(-family) \
				-value $family \
				-command FontUpdate
			set l [expr ($l +1) % $limit]
		}
	}

	# Complete the other menus

	set sizes "7 8 10 12 14 18 24 36 72"
	if {[lsearch $sizes $font(-size)] < 0} {
	    lappend sizes $font(-size)
	    set sizes [lsort -integer $sizes]
	}
	foreach size $sizes {
		$menubar.size add radio -label $size \
			-variable font(-size) \
			-value $size \
			-command FontUpdate
	}
	$menubar.size add command -label Other... \
			-command [list FontSetSize $top]
	$menubar.format add check -label Bold \
			-variable font(-weight) \
			-onvalue bold -offvalue normal \
			-command FontUpdate
	$menubar.format add check -label Italic \
			-variable font(-slant) \
			-onvalue italic -offvalue roman \
			-command FontUpdate
	$menubar.format add check -label underline \
		-variable font(-underline) \
		-command FontUpdate
	$menubar.format add check -label overstrike \
		-variable font(-overstrike) \
		-command FontUpdate

	# FontReset initializes the font array, which causes
	# the radio menu entries to get highlighted.

	FontReset

	# This label displays the current font

	label $top.font -textvar font(name) -bd 5
	# This message displays a sampler of the font.

	message $top.msg -aspect 1000 \
					-borderwidth 10 -font fontsel \
					-text  "
ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
0123456789
!@#$%^&*()_+-=[]{};:\"'` ~,.<>/?\\|
"

	# Lay out the dialog

	pack $top.font $top.msg  -side top
	set f [frame $top.buttons]
	button $f.reset -text Reset -command FontReset
	button $f.ok -text Ok -command {set font(ok) 1}
	button $f.cancel -text Cancel -command {set font(ok) 0}
	pack $f.reset $f.ok $f.cancel -padx 10 -side left
	pack $f -side top

	# Dialog_Wait is defined in Example 36-1 on page 521

	set font(ok) cancel
	Dialog_Wait $top font(ok)
	destroy $top
	if {$font(ok) == "ok"} {
		return [array get font -*]
	} else {
		return {}
	}
}

# FontReset recreates a default font

proc FontReset {} {
	catch {font delete fontsel}
	eval font create fontsel [font actual old_fontsel]
	FontSet
}

# FontSet initializes the font array with the settings
# returned by the font actual command

proc FontSet {} {
	global font

	# The name is the font configuration information
	# with a line break so it looks nicer

	set font(name) [font actual fontsel]
	regsub -- "-slant" $font(name) "\n-slant" font(name)

	# Save the actual parameters after any font substitutions

	array set font [font actual fontsel]
}

# FontSetSize adds an entry widget to the dialog so you
# can enter a specific font size.

proc FontSetSize {top} {
	set f [frame $top.size -borderwidth 10]
	pack $f -side top -fill x
	label $f.msg -text "Size:"
	entry $f.entry -textvariable font(-size)
	bind $f.entry <Return> FontUpdate
	pack $f.msg -side left
	pack $f.entry -side top -fill x
}

# FontUpdate is called when any of the font settings
# are changed, either from the menu or FontSetSize

proc FontUpdate { } {
	global font

	# The elements of font that have a leading - are
	# used directly in the font configuration command.

	eval {font configure fontsel} [array get font -*]
	FontSet
}


# From Brent Welch's 3rd edition CD Example 36-1

proc Dialog_Wait {top varName {focus {}}} {
	upvar $varName var

	# Poke the variable if the user nukes the window
	bind $top <Destroy> [list set $varName cancel]

	# Grab focus for the dialog
	if {[string length $focus] == 0} {
		set focus $top
	}
	set old [focus -displayof $top]
	focus $focus
	catch {tkwait visibility $top}
	catch {grab $top}

	# Wait for the dialog to complete
	tkwait variable $varName
	catch {grab release $top}
	focus $old
}
