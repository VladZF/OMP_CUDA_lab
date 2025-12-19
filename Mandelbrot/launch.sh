#!/bin/bash

SRC_FILE="SourceFiles/main.c"
BUILD_DIR="BuildFiles"
EXE_FILE="$BUILD_DIR/main"
OUT_DIR="ComputedSets"
LOG_FILE="benchmark_results.csv"

THREADS_LIST=(1 2 4 8 16)
POINTS_LIST=(10000 100000 1000000 10000000)

mkdir -p $BUILD_DIR
mkdir -p $OUT_DIR

echo "--- Compiling $SRC_FILE ---"
gcc -O3 -fopenmp $SRC_FILE -o $EXE_FILE

if [ $? -ne 0 ]; then
    echo "Error: Compilation failed!"
    exit 1
fi
echo "Compilation successful."
echo "-------------------------------------------"

echo "Threads,Points,Time_Seconds" > $LOG_FILE

for threads in "${THREADS_LIST[@]}"; do
    for points in "${POINTS_LIST[@]}"; do      
        echo "Running: Threads=$threads, Points=$points..."
        OUTPUT=$($EXE_FILE $threads $points)

        echo "$OUTPUT"
        
        EXEC_TIME=$(echo "$OUTPUT" | grep "Time taken" | awk '{print $3}')
    
        echo "$threads,$points,$EXEC_TIME" >> $LOG_FILE

        SOURCE_CSV="mandelbrot-points.csv"
        TARGET_CSV="$OUT_DIR/mandelbrot-${threads}-${points}.csv"

        if [ -f "$SOURCE_CSV" ]; then
            mv "$SOURCE_CSV" "$TARGET_CSV"
            echo "Saved result to: $TARGET_CSV"
        else
            echo "Error: Output CSV not found!"
        fi
        
        echo "-------------------------------------------"
    done
done

python3 charts_gen.py

echo "All tests completed. Performance data saved to $LOG_FILE. Charts created in benchmark.png"