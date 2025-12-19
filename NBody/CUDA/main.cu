#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>

#define G 6.67430e-11
#define DT 50.0
#define BLOCK_SIZE 256

#define checkCuda(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true) {
   if (code != cudaSuccess) {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

__global__ void calculate_forces(
    const double *d_m, const double *d_x, const double *d_y, 
    double *d_fx, double *d_fy, 
    int n) 
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    double my_x, my_y;
    double acc_fx = 0.0;
    double acc_fy = 0.0;

    if (i < n) {
        my_x = d_x[i];
        my_y = d_y[i];
    }

    __shared__ double sh_x[BLOCK_SIZE];
    __shared__ double sh_y[BLOCK_SIZE];
    __shared__ double sh_m[BLOCK_SIZE];

    for (int tile = 0; tile < gridDim.x; tile++) {
        int idx = tile * blockDim.x + threadIdx.x;
        
        if (idx < n) {
            sh_x[threadIdx.x] = d_x[idx];
            sh_y[threadIdx.x] = d_y[idx];
            sh_m[threadIdx.x] = d_m[idx];
        } else {
            sh_m[threadIdx.x] = 0.0; 
            sh_x[threadIdx.x] = 0.0;
            sh_y[threadIdx.x] = 0.0;
        }

        __syncthreads();

        if (i < n) {
            #pragma unroll 
            for (int j = 0; j < BLOCK_SIZE; j++) {
                double dx = sh_x[j] - my_x;
                double dy = sh_y[j] - my_y;
                double dist_sq = dx * dx + dy * dy + 1e-10;
                
                if (dist_sq > 1.0) {
                    double dist = sqrt(dist_sq);
                    double f_mag = G * d_m[i] * sh_m[j] / (dist_sq * dist);
                    acc_fx += f_mag * dx;
                    acc_fy += f_mag * dy;
                }
            }
        }
        __syncthreads();
    }

    if (i < n) {
        d_fx[i] = acc_fx;
        d_fy[i] = acc_fy;
    }
}

__global__ void integrate(
    double *d_m, double *d_x, double *d_y, 
    double *d_vx, double *d_vy, 
    const double *d_fx, const double *d_fy, 
    int n) 
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if (i < n) {
        double m = d_m[i];
        double fx = d_fx[i];
        double fy = d_fy[i];

        d_x[i] += d_vx[i] * DT;
        d_y[i] += d_vy[i] * DT;
        d_vx[i] += (fx / m) * DT;
        d_vy[i] += (fy / m) * DT;
    }
}

int main(int argc, char** argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <t_end> <input_file>\n", argv[0]);
        return 1;
    }

    double t_end = atof(argv[1]);
    char *filename = argv[2];

    FILE *in = fopen(filename, "r");
    if (!in) { perror("Error opening file"); return 1; }

    int n;
    if (fscanf(in, "%d", &n) != 1) { fprintf(stderr, "Error reading N\n"); return 1; }

    double *h_m, *h_x, *h_y, *h_vx, *h_vy;
    checkCuda(cudaMallocHost(&h_m, n * sizeof(double)));
    checkCuda(cudaMallocHost(&h_x, n * sizeof(double)));
    checkCuda(cudaMallocHost(&h_y, n * sizeof(double)));
    checkCuda(cudaMallocHost(&h_vx, n * sizeof(double)));
    checkCuda(cudaMallocHost(&h_vy, n * sizeof(double)));

    for (int i = 0; i < n; i++) {
        fscanf(in, "%lf %lf %lf %lf %lf", &h_m[i], &h_x[i], &h_y[i], &h_vx[i], &h_vy[i]);
    }
    fclose(in);

    double *d_m, *d_x, *d_y, *d_vx, *d_vy, *d_fx, *d_fy;
    checkCuda(cudaMalloc(&d_m, n * sizeof(double)));
    checkCuda(cudaMalloc(&d_x, n * sizeof(double)));
    checkCuda(cudaMalloc(&d_y, n * sizeof(double)));
    checkCuda(cudaMalloc(&d_vx, n * sizeof(double)));
    checkCuda(cudaMalloc(&d_vy, n * sizeof(double)));
    checkCuda(cudaMalloc(&d_fx, n * sizeof(double)));
    checkCuda(cudaMalloc(&d_fy, n * sizeof(double)));

    checkCuda(cudaMemcpy(d_m, h_m, n * sizeof(double), cudaMemcpyHostToDevice));
    checkCuda(cudaMemcpy(d_x, h_x, n * sizeof(double), cudaMemcpyHostToDevice));
    checkCuda(cudaMemcpy(d_y, h_y, n * sizeof(double), cudaMemcpyHostToDevice));
    checkCuda(cudaMemcpy(d_vx, h_vx, n * sizeof(double), cudaMemcpyHostToDevice));
    checkCuda(cudaMemcpy(d_vy, h_vy, n * sizeof(double), cudaMemcpyHostToDevice));

    int blocks = (n + BLOCK_SIZE - 1) / BLOCK_SIZE;
    
    FILE *out = fopen("output_cuda.csv", "w");
    fprintf(out, "t");
    for (int i = 1; i <= n; i++) fprintf(out, ",x%d,y%d", i, i);
    fprintf(out, "\n");

    printf("Starting GPU: N=%d, Blocks=%d, Threads=%d\n", n, blocks, BLOCK_SIZE);
    
    double t = 0.0;
    while (t <= t_end) {
        checkCuda(cudaMemcpy(h_x, d_x, n * sizeof(double), cudaMemcpyDeviceToHost));
        checkCuda(cudaMemcpy(h_y, d_y, n * sizeof(double), cudaMemcpyDeviceToHost));

        fprintf(out, "%.2f", t);
        for (int i = 0; i < n; i++) {
            fprintf(out, ",%.6f,%.6f", h_x[i], h_y[i]);
        }
        fprintf(out, "\n");

        calculate_forces<<<blocks, BLOCK_SIZE>>>(d_m, d_x, d_y, d_fx, d_fy, n);
        integrate<<<blocks, BLOCK_SIZE>>>(d_m, d_x, d_y, d_vx, d_vy, d_fx, d_fy, n);
        
        t += DT;
    }
    
    cudaDeviceSynchronize();
    printf("Simulation complete.\n");

    fclose(out);
    cudaFreeHost(h_m); cudaFreeHost(h_x); cudaFreeHost(h_y); 
    cudaFreeHost(h_vx); cudaFreeHost(h_vy);
    cudaFree(d_m); cudaFree(d_x); cudaFree(d_y); 
    cudaFree(d_vx); cudaFree(d_vy); cudaFree(d_fx); cudaFree(d_fy);

    return 0;
}