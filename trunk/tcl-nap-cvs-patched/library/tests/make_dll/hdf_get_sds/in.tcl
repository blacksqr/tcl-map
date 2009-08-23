switch $::tcl_platform(platform) {
    unix	{load ./libhdf_get_sds.so}
    windows	{load ./hdf_get_sds.dll}
}

proc hdf_get_sds_short {filename sds_name start stride edge} {
    set result [nap "reshape(0s, edge)"]
    nap "status = 0"
    hdf_get_sds filename sds_name start stride edge result status
    if [$status] {
	error "hdf_get_sds_short: error code = [$status]"
    }
    return $result
}

puts_file out.txt [[nap "hdf_get_sds_short('s.hdf', 's', {0}, {1}, {8})"] value]
