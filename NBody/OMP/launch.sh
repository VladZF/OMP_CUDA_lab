#!/bin/bash

SRC_FILE="SourceFiles/main.c"
BUILD_DIR="BuildFiles"
EXE_FILE="$BUILD_DIR/main"
INPUT_DIR="../Inputs"
OUT_DIR="ComputedTrajectories"
LOG_FILE="benchmark_results.csv"

# Параметры запуска
THREADS_LIST=(1 2 4 8 12 16)
POINTS_LIST=(1024 2048 4096 8192 16384)
T_END=500.0

# Создаем необходимые директории
mkdir -p $OUT_DIR
mkdir -p $BUILD_DIR

# 1. Компиляция кода
echo "--- Compiling $SRC_FILE ---"
gcc -O3 -fopenmp $SRC_FILE -o $EXE_FILE -lm

if [ $? -ne 0 ]; then
    echo "Error: Compilation failed!"
    exit 1
fi
echo "Compilation successful."
echo "-------------------------------------------"

# 2. Подготовка заголовка CSV файла результатов
echo "Threads,Points,Time_Seconds" > $LOG_FILE

# 3. Основной цикл бенчмарка
for threads in "${THREADS_LIST[@]}"; do
    for points in "${POINTS_LIST[@]}"; do
        
        INPUT_FILE="$INPUT_DIR/input_${points}.txt"
        
        # Проверка наличия входного файла
        if [ ! -f "$INPUT_FILE" ]; then
            echo "Warning: File $INPUT_FILE not found! Skipping..."
            continue
        fi

        echo "Running: Threads=$threads, Points=$points, t_end=$T_END..."
        
        # Запуск программы и захват вывода
        # Аргументы: <nthreads> <t_end> <input_file>
        OUTPUT=$($EXE_FILE $threads $T_END $INPUT_FILE)

        # Выводим текст из программы в консоль (Taken ... seconds)
        echo "$OUTPUT"
        
        # Извлекаем время выполнения. 
        # Программа выводит: "Taken 1.234567 seconds on X threads."
        # Нам нужно 2-е слово.
        EXEC_TIME=$(echo "$OUTPUT" | grep "Taken" | awk '{print $2}')
    
        # Записываем данные в лог
        echo "$threads,$points,$EXEC_TIME" >> $LOG_FILE

        # Переименовываем и перемещаем выходной файл траекторий
        SOURCE_CSV="output.csv"
        TARGET_CSV="$OUT_DIR/trajectory_${threads}_${points}.csv"

        if [ -f "$SOURCE_CSV" ]; then
            mv "$SOURCE_CSV" "$TARGET_CSV"
            echo "Trajectory saved to: $TARGET_CSV"
        else
            echo "Error: output.csv not found!"
        fi
        
        echo "-------------------------------------------"
    done
done

python3 charts_gen.py

echo "All tests completed. Performance data saved to $LOG_FILE. Charts created in benchmark.png"