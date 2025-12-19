#!/bin/bash

# Компилируем
echo "--- Compiling CUDA ---"
nvcc -O3 main.cu -o main_cuda

# Параметры теста
POINTS_LIST=(1024 2048 4096 8192 16384)
T_END=500.0
INPUT_DIR="../Inputs"

echo "Points,Time_Seconds" > benchmark_results.csv

# === WARM-UP (Разогрев) ===
# Запускаем один раз вхолостую, чтобы драйвер CUDA загрузился
echo "--- GPU Warm-up (ignoring result) ---"
if [ -f "$INPUT_DIR/input_1024.txt" ]; then
    ./main_cuda 10.0 "$INPUT_DIR/input_1024.txt" > /dev/null 2>&1
fi
# ==========================

# Настраиваем формат времени для bash (только секунды)
export TIMEFORMAT='%R'

for points in "${POINTS_LIST[@]}"; do
    INPUT_FILE="$INPUT_DIR/input_${points}.txt"
    
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Skip $points: file not found"
        continue
    fi

    echo "Running CUDA: Points=$points..."
    
    # Запуск с замером времени. 
    # 2> temp_time.txt перенаправляет вывод времени (stderr) в файл
    # > /dev/null глушит обычный вывод программы
    { time ./main_cuda $T_END $INPUT_FILE > /dev/null; } 2> temp_time.txt
    
    # Читаем время из файла (оно там теперь просто числом, например 0.422)
    REAL_TIME=$(cat temp_time.txt)
    echo "Time: $REAL_TIME s"
    
    echo "$points,$REAL_TIME" >> benchmark_results.csv
done

echo "Done. Results:"
cat benchmark_results.csv