#!/bin/bash

BUILD_DIR="BuildFiles"
mkdir -p $BUILD_DIR

echo "--- Compiling Custom RWLock ---"
gcc -O3 -pthread SourceFiles/main.c SourceFiles/my_rwlock.c SourceFiles/my_rand.c -o $BUILD_DIR/custom_rwl

echo "--- Compiling Standard Library RWLock ---"
gcc -O3 -pthread -DUSE_STD_LIB SourceFiles/main.c SourceFiles/my_rwlock.c SourceFiles/my_rand.c -o $BUILD_DIR/std_rwl

# Параметры теста
INITIAL_INSERTS=1000
TOTAL_OPS=100000
# 90% поиск, 5% вставка, 5% удаление (автоматически считается)
SEARCH_PCT=0.90
INSERT_PCT=0.05

THREADS_LIST=(1 2 4 8)

echo "Benchmark: $TOTAL_OPS operations, 90% reads"
echo "Threads | Custom (s) | StdLib (s)"
echo "---------------------------------"

for threads in "${THREADS_LIST[@]}"; do
    # Формируем ввод для программы: InitialInserts, TotalOps, Search%, Insert%
    INPUT_DATA="$INITIAL_INSERTS $TOTAL_OPS $SEARCH_PCT $INSERT_PCT"
    
    # Запуск Custom
    TIME_CUSTOM=$(echo "$INPUT_DATA" | $BUILD_DIR/custom_rwl $threads | grep "Elapsed time" | awk '{print $4}')
    
    # Запуск Standard
    TIME_STD=$(echo "$INPUT_DATA" | $BUILD_DIR/std_rwl $threads | grep "Elapsed time" | awk '{print $4}')
    
    echo "   $threads    |  $TIME_CUSTOM  |  $TIME_STD"
done