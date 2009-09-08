proc tk_getString {w var title text} {
   variable ::tk::Priv
   upvar $var result
   catch {destroy $w}
   set focus [focus]
   set grab [grab current .]

   toplevel $w -bd 1 -relief raised -class TkSDialog
   wm title $w $title
   wm iconname  $w $title
   wm protocol  $w WM_DELETE_WINDOW {set ::tk::Priv(button) 0}
   wm transient $w [winfo toplevel [winfo parent $w]]
   wm attributes $w -topmost 1
   wm resizable $w 0 0

   ttk::frame $w.f
   ttk::entry  $w.f.entry -width 20
   ttk::button $w.f.ok -width 5 -text Ok -default active -command {set ::tk::Priv(button) 1}
   ttk::button $w.f.cancel -text Cancel -command {set ::tk::Priv(button) 0}
   ttk::label  $w.f.label -text $text

   grid $w.f -sticky nwes
   grid rowconfigure $w 0 -weight 1; grid columnconfigure $w 0 -weight 1
   grid $w.f.label -columnspan 2 -sticky ew -padx 3 -pady 3
   grid $w.f.entry -columnspan 2 -sticky ew -padx 3 -pady 3
   grid $w.f.ok $w.f.cancel -padx 3 -pady 3
   grid rowconfigure $w.f 2 -weight 1
   grid columnconfigure $w.f {0 1} -uniform 1 -weight 1

   bind $w <Return>  {set ::tk::Priv(button) 1}
   bind $w <Destroy> {set ::tk::Priv(button) 0}
   bind $w <Escape>  {set ::tk::Priv(button) 0}

   wm withdraw $w
   update idletasks
   focus $w.f.entry
   set x [expr {[winfo screenwidth  $w]/2 - [winfo reqwidth  $w]/2 - [winfo vrootx $w]}]
   set y [expr {[winfo screenheight $w]/2 - [winfo reqheight $w]/2 - [winfo vrooty $w]}]
   wm geom $w +$x+$y
   wm deiconify $w
   grab $w

   tkwait variable ::tk::Priv(button)
   set result [$w.f.entry get]
   bind $w <Destroy> {}
   grab release $w
   destroy $w
   focus -force $focus
   if {$grab != ""} {grab $grab}
   update idletasks
   return $::tk::Priv(button)
}
