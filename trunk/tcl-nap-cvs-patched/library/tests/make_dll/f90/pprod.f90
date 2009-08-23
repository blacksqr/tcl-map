subroutine pprod(n, x, result)
    integer, intent(in) :: n
    real, intent(in) :: x(n)
    real, intent(out) :: result(n)
    integer :: i
    real :: prod
    prod = 1.0
    do i = 1, n
	prod = prod * x(i)
	result(i) = prod
    end do
end subroutine pprod
