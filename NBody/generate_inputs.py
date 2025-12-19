import os
import random

# Список размеров входных файлов
points_list = [1024, 2048, 4096, 8192, 16384]
output_dir = "Inputs"

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

def generate_file(n):
    filename = os.path.join(output_dir, f"input_{n}.txt")
    with open(filename, "w") as f:
        f.write(f"{n}\n")
        
        for _ in range(n):
            m = random.uniform(7e22, 1e27)
            x = random.uniform(-1.5e12, 1.5e12)
            y = random.uniform(-1.5e12, 1.5e12)
            vx = random.uniform(-50000, 50000)
            vy = random.uniform(-50000, 50000)
            
            f.write(f"{m:.6e} {x:.6f} {y:.6f} {vx:.6f} {vy:.6f}\n")
    print(f"Файл {filename} успешно создан.")

for p in points_list:
    generate_file(p)

print("\nВсе файлы готовы для тестирования.")