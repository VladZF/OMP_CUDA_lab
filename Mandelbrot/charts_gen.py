import pandas as pd
import matplotlib.pyplot as plt
import io


for method in ["Monte-Carlo", "Grid"]:
    df = pd.read_csv(f"{method}/benchmark_results.csv")

    points_cases = df['Points'].unique()


    fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(20, 6))

    for p in points_cases:
        subset = df[df['Points'] == p].sort_values('Threads')
        threads = subset['Threads']
        times = subset['Time_Seconds']
        

        ax1.plot(threads, times, marker='o', label=f'N={p}')
        
        t1 = times.iloc[0]
        speedup = t1 / times
        
        ax2.plot(threads, speedup, marker='o', label=f'N={p}')
        
        efficiency = speedup / threads
        
        ax3.plot(threads, efficiency, marker='o', label=f'N={p}')

    ax1.set_title('Время выполнения')
    ax1.set_xlabel('Количество потоков')
    ax1.set_ylabel('Время (сек)')
    ax1.set_yscale('log')
    ax1.grid(True)
    ax1.legend()

    ax2.plot(threads, threads, 'k--', label='Идеал')
    ax2.set_title('Ускорение (Speedup)')
    ax2.set_xlabel('Количество потоков')
    ax2.set_ylabel('S = T1 / Tp')
    ax2.grid(True)
    ax2.legend()

    ax3.axhline(y=1, color='k', linestyle='--', label='Идеал')
    ax3.set_title('Эффективность (Efficiency)')
    ax3.set_xlabel('Количество потоков')
    ax3.set_ylabel('E = S / p')
    ax3.set_ylim(0, 1.1)
    ax3.grid(True)
    ax3.legend()

    plt.tight_layout()
    plt.savefig(f"{method}_performance_plots.png")