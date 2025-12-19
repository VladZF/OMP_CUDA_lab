#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <omp.h>
#include <time.h>

typedef struct {
    double x;
    double y;
} Point;

int is_mandelbrot(double cr, double ci, int max_iter) {
    double zr = 0.0;
    double zi = 0.0;
    
    for (int i = 0; i < max_iter; i++) {
        double zr_new = zr * zr - zi * zi + cr;
        double zi_new = 2.0 * zr * zi + ci;
        
        zr = zr_new;
        zi = zi_new;
        
        if (zr * zr + zi * zi > 4.0) {
            return 0; 
        }
    }
    return 1;
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <nthreads> <npoints>\n", argv[0]);
        return 1;
    }

    int nthreads = atoi(argv[1]);
    long long npoints = atoll(argv[2]);

    if (nthreads <= 0 || npoints <= 0) {
        fprintf(stderr, "Error: Arguments must be positive integers.\n");
        return 1;
    }

    int side = (int)sqrt((double)npoints);
    
    double x_min = -2.0;
    double x_max = 1.0;
    double y_min = -1.5;
    double y_max = 1.5;
    
    int max_iter = 1000;

    Point* results = (Point*)malloc(sizeof(Point) * side * side);
    if (results == NULL) {
        fprintf(stderr, "Error: Failed to allocate memory.\n");
        return 1;
    }

    long long total_found = 0; 

    omp_set_num_threads(nthreads);
    double start_time = omp_get_wtime();

    #pragma omp parallel
    {
        #pragma omp for schedule(dynamic) collapse(2)
        for (int i = 0; i < side; i++) {
            for (int j = 0; j < side; j++) {
                
                double x = x_min + i * (x_max - x_min) / side;
                double y = y_min + j * (y_max - y_min) / side;

                if (is_mandelbrot(x, y, max_iter)) {
                    long long idx;
                    #pragma omp atomic capture
                    {
                        idx = total_found;
                        total_found++;
                    }
                    
                    results[idx].x = x;
                    results[idx].y = y;
                }
            }
        }
    }

    double end_time = omp_get_wtime();
    printf("Time taken: %f seconds.\n", end_time - start_time);
    printf("Found %lld points out of %d scanned using %d threads.\n", total_found, side * side, nthreads);

    FILE* fp = fopen("mandelbrot.csv", "w");
    if (fp == NULL) {
        perror("Error opening file");
        free(results);
        return 1;
    }

    char buffer[1024 * 1024]; 
    setvbuf(fp, buffer, _IOFBF, sizeof(buffer));

    fprintf(fp, "x,y\n");
    for (long long i = 0; i < total_found; i++) {
        fprintf(fp, "%.6f,%.6f\n", results[i].x, results[i].y);
    }

    fclose(fp);
    free(results);

    printf("Results saved to mandelbrot.csv\n");

    return 0;
}