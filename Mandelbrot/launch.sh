#!/bin/bash

SRC_MC="Monte-Carlo/main.c"
SRC_GRID="Grid/main.c"

BUILD_DIR="BuildFiles"
EXE_MC="$BUILD_DIR/monte_carlo"
EXE_GRID="$BUILD_DIR/grid_search"

OUT_DIR="ComputedSets"

THREADS_LIST=(1 2 4 8 12 16)
POINTS_LIST=(10000 100000 1000000 10000000)

mkdir -p $BUILD_DIR
mkdir -p $OUT_DIR

echo "==========================================="
echo "Compiling Monte Carlo method..."
gcc -O3 -fopenmp $SRC_MC -o $EXE_MC -lm

if [ $? -ne 0 ]; then
    echo "Error: Monte Carlo compilation failed!"
    exit 1
fi

echo "Compiling Grid Search method..."
gcc -O3 -fopenmp $SRC_GRID -o $EXE_GRID -lm

if [ $? -ne 0 ]; then
    echo "Error: Grid Search compilation failed!"
    exit 1
fi

echo "Compilation successful for both programs."
echo "==========================================="

METHODS=("montecarlo" "grid")

for method in "${METHODS[@]}"; do
    LOG_FILE="benchmark_results.csv"
    if [ "$method" = "montecarlo" ]; then
        CURRENT_EXE=$EXE_MC
        LOG_FILE="Monte-Carlo/$LOG_FILE"
        CSV_NAME="mandelbrot-points.csv"
    else
        CURRENT_EXE=$EXE_GRID
        LOG_FILE="Grid/$LOG_FILE"
        CSV_NAME="mandelbrot.csv"
    fi
    
    echo "Threads,Points,Time_Seconds" > $LOG_FILE

    for threads in "${THREADS_LIST[@]}"; do
        for points in "${POINTS_LIST[@]}"; do      
            echo "[Method: $method] Running: Threads=$threads, Points=$points..."
            
            OUTPUT=$($CURRENT_EXE $threads $points)
            echo "$OUTPUT"

            if [ "$method" = "montecarlo" ]; then
                EXEC_TIME=$(echo "$OUTPUT" | grep "Time taken" | awk '{print $3}')
            else
                EXEC_TIME=$(echo "$OUTPUT" | grep "Time taken" | awk '{print $3}')
            fi
        
            echo "$threads,$points,$EXEC_TIME" >> $LOG_FILE

            TARGET_CSV="$OUT_DIR/mandelbrot-${method}-${threads}-${points}.csv"

            if [ -f "$CSV_NAME" ]; then
                mv "$CSV_NAME" "$TARGET_CSV"
                echo "Saved result to: $TARGET_CSV"
            else
                echo "Error: Output CSV ($CSV_NAME) not found!"
            fi
            
            echo "-------------------------------------------"
        done
    done
done

python3 charts_gen.py

echo "All tests completed."
echo "Results saved to $LOG_FILE"