float *readfloat(char *filename, int *nx, int *ny, int *status);
char *readheader(char *filename, int *error_status);
void writefloat(char *filename, float *arr, long nx, long ny, int *error_status);
void writefloatspec(char *filename, float *x, float *arr, float *optarr,
                    float *skyarr, float *lambda, float *fits, float *segWithMasks, float *weights,
                    long npts, long nx, long ny, float crval, float crpix, float cdelt, int *error_status);
void writeFITS1D(char *filename, float *lambda, float *arr, float *optarr,
                 float *skyarr, float *electrons, long nx, int *error_status);
int savespectrum(char *filename, int nx, void *arr, int datatype, int p0, double pMin, double pMax,
                 double *coeffs, int ncoeff);
int checkForSimpleSpectrum(char *filename); 


