#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <complex.h>
#include <time.h>
#include <string.h>


#define MAX_ITER 1000

#define X_MIN -2.0
#define X_MAX 1.0
#define Y_MIN -1.5
#define Y_MAX 1.5

int in_mandelbrot(double complex c) {
    double complex z = 0.0;

    for (int i = 0; i < MAX_ITER; i++) {
        double re = creal(z);
        double im = cimag(z);

        if (re * re + im * im >= 4.0) {
            return 0;
        }

        z = z * z + c;
    }

    return 1;
}


int main(int argc, char** argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <nthreads> <npoints>\n", argv[0]);
        return 1;
    }

    int nthreads = atoi(argv[1]);
    long long npoints = atoll(argv[2]);

    if (nthreads <= 0) {
        fprintf(stderr, "Error: non-positive <nthreads> count");
        return 0;
    }

    if (npoints <= 0) {
        fprintf(stderr, "Error: non-positive <npoints> count");
        return 0;
    }

    double complex *results = malloc(sizeof(double complex) * npoints);
    if (!results) {
        fprintf(stderr, "Error: Could not allocate memory for %lld points.\n", npoints);
        return 1;
    }

    omp_set_num_threads(nthreads);

    long long count = 0;

    double start_time = omp_get_wtime();

    #pragma omp parallel
    {
        unsigned int seed = (unsigned int)time(NULL) ^ (unsigned int)omp_get_thread_num();

        while (1) {
            if (count >= npoints) break;

            double re = X_MIN + (X_MAX - X_MIN) * ((double)rand_r(&seed) / RAND_MAX);
            double im = Y_MIN + (Y_MAX - Y_MIN) * ((double)rand_r(&seed) / RAND_MAX);
            
            double complex c = re + im * I;

            if (in_mandelbrot(c)) {
                long long index;
                #pragma omp atomic capture
                {
                    index = count;
                    count++;
                }
                if (index < npoints) {
                    results[index] = c;
                } else {
                    break;
                }
            }
        }
    }

    double end_time = omp_get_wtime();

    double elapsed_time = end_time - start_time;

    fprintf(stdout, "Time taken: %f seconds. Found %lld points using %d threads.\n", elapsed_time, npoints, nthreads);

    fprintf(stdout, "Writing to file...\n");
    FILE *fp = fopen("mandelbrot-points.csv", "w");
    if (!fp) {
        perror("Error opening file");
        free(results);
        return 1;
    }

    char buffer[1024 * 1024];
    setvbuf(fp, buffer, _IOFBF, sizeof(buffer));

    fprintf(fp, "real,imagine\n");
    for (long long i = 0; i < npoints; i++) {
        fprintf(fp, "%.6f,%.6f\n", creal(results[i]), cimag(results[i]));
    }

    fclose(fp);
    free(results);
    fprintf(stdout, "Done. Saved to mandelbrot-points.csv\n");

    return 0;
}
