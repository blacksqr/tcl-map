#
# This set of proceedures implements part of a class of
# sigmoid functions. These functions can be used as neural
# network activation functions. The first function, linsig
# is not suitable for use with neural networks because it is 
# linear. Applying such a function in a complex neural network would 
# effectively reduce the network to a single layer system. 
# 
# linsig --
# Linear sigmoid function
#
# This function implements a function of the form
#
#                high
#  1.0              _________
#                  /
#                 /
#                /
#  0.0  ________/
#
#              low         
#
# The method used is to use linear interpolation between
# low and high to produce a result between 0 and 1
#
# Author P.J. Turner with advice from Harvey Davies
#
proc linsig {data low high} {

nap "x = -1if // low // high // 1if"
nap "y = {0f 0f 1f 1f}"
$y set coord x

nap "y(@data)"
}

#
# sfunc --
#
# S function nonlinear
#
#                  /
#                  |  0                            d <= a 
#                  |
#                  |  2*((d - a)/(c - a))**2       a < d <= b
#  S(d, a, b, c) = | 
#                  |
#                  |  1 - 2*((d - c)/(c - a))**2   b < d < c
#                  |
#                  |  1                            d >= c 
#                  \
#
# where
#
#
#                          c 
# 1.0                     .----------
#                        /
#                       /
#                      /
#                     /b
#                    /
#                   /
# 0.0     ________ .
#                 a
#
#             xaxis
#

proc sfunc {data a b c} {

    nap range = c - a

    nap "data <= a ? 0.0 :
            data >= c ? 1.0 :
                data <= b ? 2f*((data - a)/range)**2 :
                            1f - 2f*((data - c)/range)**2" 
}

#
# logistic --
#
# logistic activation function

proc logistic {data} {

    nap 1f/(1f + exp(-data))

}


# Note that f(x) = tanh(x) is also a useful sigmoid function.
# This function can be used directly so is not defined here.
