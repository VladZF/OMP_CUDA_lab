#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <omp.h>

#define G 6.67430e-11
#define DT 50.0

typedef struct {
    double m;
    double x, y;
    double vx, vy;
} Body;

int main(int argc, char** argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <nthreads> <t_end> <input_file>\n", argv[0]);
        return 1;
    }

    int nthreads = atoi(argv[1]);
    double t_end = atof(argv[2]);
    char *filename = argv[3];

    omp_set_num_threads(nthreads);

    FILE *in = fopen(filename, "r");
    if (!in) {
        perror("Error: unable to open file\n");
        return 1;
    }

    int n;
    if (fscanf(in, "%d", &n) != 1) {
        fprintf(stderr, "Error: unable to read bodies count\n");
        return 1;
    }

    Body *bodies = malloc(sizeof(Body) * n);
    for (int i = 0; i < n; i++) {
        fscanf(in, "%lf %lf %lf %lf %lf", 
               &bodies[i].m, &bodies[i].x, &bodies[i].y, &bodies[i].vx, &bodies[i].vy);
    }
    fclose(in);

    FILE *out = fopen("output.csv", "w");
    if (!out) {
        perror("Error: unable to create output file");
        return 1;
    }

    fprintf(out, "t");
    for (int i = 1; i <= n; i++) {
        fprintf(out, ",x%d,y%d", i, i);
    }
    fprintf(out, "\n");

    double *fx = malloc(sizeof(double) * n);
    double *fy = malloc(sizeof(double) * n);

    double elapsed_time = 0;
    double t = 0.0;
    while (t <= t_end) {
        fprintf(out, "%.2f", t);
        for (int i = 0; i < n; i++) {
            fprintf(out, ",%.6f,%.6f", bodies[i].x, bodies[i].y);
        }
        fprintf(out, "\n");

        for (int i = 0; i < n; i++) {
            fx[i] = 0.0;
            fy[i] = 0.0;
        }

        double start_time = omp_get_wtime();
        #pragma omp parallel for reduction(+:fx[0:n], fy[0:n]) schedule(dynamic)
        for (int i = 0; i < n; i++) {
            for (int j = i + 1; j < n; j++) {
                double dx = bodies[j].x - bodies[i].x;
                double dy = bodies[j].y - bodies[i].y;
                double dist_sq = dx * dx + dy * dy;
                double dist = sqrt(dist_sq);

                if (dist < 1.0) continue;

                double f_mag = G * bodies[i].m * bodies[j].m / (dist_sq * dist);
                double dfx = f_mag * dx;
                double dfy = f_mag * dy;

                fx[i] += dfx;
                fy[i] += dfy;
                fx[j] -= dfx;
                fy[j] -= dfy;
            }
        }

        #pragma omp parallel for
        for (int i = 0; i < n; i++) {
            bodies[i].x += bodies[i].vx * DT;
            bodies[i].y += bodies[i].vy * DT;
            bodies[i].vx += (fx[i] / bodies[i].m) * DT;
            bodies[i].vy += (fy[i] / bodies[i].m) * DT;
        }

        double end_time = omp_get_wtime();
        elapsed_time += (end_time - start_time);
        t += DT;
    }

    fprintf(stdout, "Taken %lf seconds on %d threads.\n", elapsed_time, nthreads);

    fclose(out);
    free(bodies);
    free(fx);
    free(fy);

    printf("Results saved to output.csv\n");
    return 0;
}