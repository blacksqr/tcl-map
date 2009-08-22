switch $::tcl_platform(platform) {
    unix	{load ./libpprod.so}
    windows	{load ./pprod.dll}
}

proc partialProd x {
    nap "result = reshape(f32(_), shape(x))"
    pprod  "nels(x)" x result
    nap "result"
}

puts_file out.txt [[nap "partialProd({2 1.5 3 0.5})"]]
