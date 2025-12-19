import pandas as pd
import matplotlib.pyplot as plt

def plot_mandelbrot_from_csv(csv_filename, output_filename):
    try:
        df = pd.read_csv(csv_filename)
        x = df.iloc[:, 0]
        y = df.iloc[:, 1]
        
    except Exception as e:
        print(f"Ошибка при чтении файла: {e}")
        return

    plt.figure(figsize=(12, 8))
    plt.scatter(x, y, s=1, c='black', marker=',', alpha=0.8)
    plt.xlim(-2.1, 1.1)
    plt.ylim(-1.5, 1.5)

    plt.gca().set_aspect('equal', adjustable='box')

    plt.grid(True, linestyle='--', alpha=0.5)
    plt.title(f"Mandelbrot Set ({len(x)} points)")
    plt.xlabel("Re")
    plt.ylabel("Im")

    plt.savefig(output_filename, dpi=300, bbox_inches='tight')
    plt.show()
    plt.close()

if __name__ == "__main__":
    input_csv = "ComputedSets/mandelbrot-grid-1-100000.csv" 
    output_png = "mandelbrot_full_beetle.png"
    plot_mandelbrot_from_csv(input_csv, output_png)
