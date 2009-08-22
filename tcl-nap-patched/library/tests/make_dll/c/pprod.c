void pprod(int *n, float *x, float *result) {
    int		i;
    float	prod = 1;

    for (i = 0; i < *n; i++) {
	result[i] = prod = prod * x[i];
    }
}
