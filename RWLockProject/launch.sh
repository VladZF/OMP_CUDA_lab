#!/bin/bash
export TIMEFORMAT='%R'
BUILD_DIR="BuildFiles"
CSV_FILE="benchmark_results.csv"

mkdir -p $BUILD_DIR

echo "--- Compiling Custom RWLock ---"
gcc -O3 -pthread SourceFiles/main.c SourceFiles/my_rwlock.c SourceFiles/my_rand.c -o $BUILD_DIR/custom_rwl

echo "--- Compiling Standard Library RWLock ---"
gcc -O3 -pthread -DUSE_STD_LIB SourceFiles/main.c SourceFiles/my_rwlock.c SourceFiles/my_rand.c -o $BUILD_DIR/std_rwl

INITIAL_INSERTS=1000
TOTAL_OPS=100000
THREADS_LIST=(1 2 4 8)

echo "Scenario,Threads,Custom_Time_Sec,StdLib_Time_Sec" > $CSV_FILE

SCENARIOS=("ReadHeavy 0.90 0.05" "WriteHeavy 0.50 0.25")

echo "Starting Comprehensive Benchmark..."
echo "---------------------------------------------------------"
printf "%-12s | %-7s | %-12s | %-12s\n" "Scenario" "Threads" "Custom (s)" "StdLib (s)"
echo "---------------------------------------------------------"

for scenario in "${SCENARIOS[@]}"; do
    read -r NAME SEARCH_PCT INSERT_PCT <<< "$scenario"
    
    for threads in "${THREADS_LIST[@]}"; do
        INPUT_DATA="$INITIAL_INSERTS $TOTAL_OPS $SEARCH_PCT $INSERT_PCT"
        
        OUTPUT_CUSTOM=$(echo "$INPUT_DATA" | timeout 15s $BUILD_DIR/custom_rwl $threads)
        if [ $? -eq 124 ]; then
            TIME_CUSTOM="TIMEOUT"
        else
            TIME_CUSTOM=$(echo "$OUTPUT_CUSTOM" | grep "Elapsed time" | awk '{print $4}')
        fi
        
        OUTPUT_STD=$(echo "$INPUT_DATA" | timeout 15s $BUILD_DIR/std_rwl $threads)
        if [ $? -eq 124 ]; then
            TIME_STD="TIMEOUT"
        else
            TIME_STD=$(echo "$OUTPUT_STD" | grep "Elapsed time" | awk '{print $4}')
        fi
        
        printf "%-12s | %-7d | %-12s | %-12s\n" "$NAME" "$threads" "$TIME_CUSTOM" "$TIME_STD"
        
        echo "$NAME,$threads,$TIME_CUSTOM,$TIME_STD" >> $CSV_FILE
    done
    echo "---------------------------------------------------------"
done

echo "Benchmark completed. Results saved to $CSV_FILE"