#!/usr/bin/env python3
"""编译选项的真实收益：把同一份 C++ 源码用不同选项编译，各跑一遍，画出结果。

产出 chapters/5.Advanced/images/adv-compile-flags.png。
配套源码 adv_compile_flags_bench.cpp。

诚实性说明（这些必须随图一起进书）：
  - 结果强依赖机器与编译器，脚本会把两者打印出来并写进图里；
  - 每档取中位数与 p99，不取平均——实时系统里平均值最没用；
  - -march=native 生成的二进制换机器可能直接非法指令崩溃，收益不是白拿的；
  - 这是一段刻意挑选的、对向量化友好的负载，真实工程的加速比通常更小。
"""
import subprocess, shutil, platform, statistics, sys, os
from pathlib import Path

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 11, "axes.linewidth": 0.8})

HERE = Path(__file__).resolve().parent
SRC = HERE / "adv_compile_flags_bench.cpp"
OUT = HERE.parent.parent / "chapters" / "5.Advanced" / "images" / "adv-compile-flags.png"
BUILD = Path(os.environ.get("BENCH_TMP", "/tmp")) / "rmcv_flag_bench"
BUILD.mkdir(parents=True, exist_ok=True)

REPS = 300
PIN_CPU = os.environ.get("BENCH_CPU", "2")   # 钉到固定核，避免调度迁移污染中位数

# (标签, 编译选项)。顺序即图中从左到右的顺序。
CONFIGS = [
    ("-O0",                 ["-O0"]),
    ("-O2",                 ["-O2"]),
    ("-O3",                 ["-O3"]),
    ("-O3 -march=native",   ["-O3", "-march=native"]),
    ("-O3 -march -flto",    ["-O3", "-march=native", "-flto"]),
]


def cpu_model() -> str:
    try:
        for line in open("/proc/cpuinfo"):
            if line.startswith("model name"):
                return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return platform.processor() or "unknown CPU"


def gxx_version() -> str:
    out = subprocess.run(["g++", "--version"], capture_output=True, text=True).stdout
    return out.splitlines()[0] if out else "g++ ?"


def vector_census(flags):
    """数编译产物里各宽度的向量指令条数。

    这一步是**确定性**的：反汇编不受 CPU 负载、频率、调度影响，
    因此哪怕计时数据被噪声污染，这张普查表依然可信。
    它回答的是机制问题——编译器到底有没有为你的循环发更宽的指令。
    """
    obj = BUILD / "probe.o"
    # 先删掉上一档的产物：若本档编译失败，objdump 会读到陈旧的 .o 而给出
    # 看似合理的错误计数（这类"上一档的数字"极难自查，务必别省这一行）。
    obj.unlink(missing_ok=True)
    subprocess.run(["g++", "-std=c++17", *flags, "-c", str(SRC), "-o", str(obj)], check=True)
    dis = subprocess.run(["objdump", "-d", str(obj)], capture_output=True, text=True).stdout
    return {w: sum(1 for l in dis.splitlines() if f"%{w}" in l) for w in ("xmm", "ymm", "zmm")}


def run_one(label, flags):
    exe = BUILD / ("bench_" + label.replace(" ", "_").replace("-", "").replace("=", ""))
    cmd = ["g++", "-std=c++17", *flags, str(SRC), "-o", str(exe)]
    subprocess.run(cmd, check=True)
    # 钉核跑。不钉的话调度迁移会把中位数打飞——实测同一档的中位数能在
    # 0.41 与 0.64 ms 之间跳（56% 波动），足以把两个编译档的真实差距淹掉。
    run_cmd = [str(exe), str(REPS)]
    if shutil.which("taskset"):
        run_cmd = ["taskset", "-c", PIN_CPU, *run_cmd]
    proc = subprocess.run(run_cmd, capture_output=True, text=True, check=True)
    rows = [list(map(float, l.split())) for l in proc.stdout.strip().splitlines()]
    a = np.array(rows)                      # (REPS, 3): threshold / conv / reduce
    total = a.sum(axis=1)
    return {
        "label": label,
        "med": np.median(a, axis=0),        # 每段中位数
        "total_med": float(np.median(total)),
        "total_p99": float(np.percentile(total, 99)),
    }


def main():
    if shutil.which("g++") is None:
        sys.exit("需要 g++")
    print(f"CPU: {cpu_model()}")
    print(f"{gxx_version()}   reps={REPS}")

    results = []
    for label, flags in CONFIGS:
        try:
            r = run_one(label, flags)
        except subprocess.CalledProcessError as e:
            print(f"  [跳过] {label}: 编译或运行失败 ({e})")
            continue
        results.append(r)
        seg = "  ".join(f"{n}={v:.2f}" for n, v in zip(("thr", "conv", "red"), r["med"]))
        print(f"  {label:22s} 中位 {r['total_med']:6.2f} ms   p99 {r['total_p99']:6.2f} ms   [{seg}]")

    if not results:
        sys.exit("没有任何配置跑通")

    base = results[0]["total_med"]           # 以 -O0 为基准算加速比
    o2 = next((r for r in results if r["label"] == "-O2"), None)

    labels = [r["label"] for r in results]
    xs = np.arange(len(results))
    seg_names = ["threshold (memory-bound)", "conv3x3 (compute-bound)", "reduce (dependency)"]
    colors = [BLUE, MAGENTA, GRAY]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12.5, 4.8))

    # 左：堆叠条形，看每档总耗时的构成
    bottom = np.zeros(len(results))
    for k, (name, c) in enumerate(zip(seg_names, colors)):
        vals = np.array([r["med"][k] for r in results])
        ax1.bar(xs, vals, 0.6, bottom=bottom, color=c, label=name,
                edgecolor="white", linewidth=0.6)
        bottom += vals
    for i, r in enumerate(results):
        ax1.annotate(f"{r['total_med']:.1f} ms\n{base / r['total_med']:.1f}x",
                     xy=(i, bottom[i]), xytext=(0, 5), textcoords="offset points",
                     ha="center", fontsize=9)
    ax1.set_xticks(xs); ax1.set_xticklabels(labels, rotation=18, ha="right", fontsize=9)
    ax1.set_ylabel("median time per frame (ms)")
    ax1.set_ylim(0, bottom.max() * 1.22)
    ax1.set_title("Where the time goes, per compile config\n(speedup vs -O0 on top)", fontsize=11)
    ax1.legend(fontsize=8.5, frameon=False)
    ax1.spines[["top", "right"]].set_visible(False)

    # 右：只看 -O2 之后还剩多少收益——这才是工程上要回答的问题
    if o2 is not None:
        rest = [r for r in results if r["label"] != "-O0"]
        rx = np.arange(len(rest))
        gain = [(o2["total_med"] / r["total_med"] - 1) * 100 for r in rest]
        bars = ax2.bar(rx, gain, 0.55, color=[BLUE if g >= 0 else MAGENTA for g in gain],
                       edgecolor="white", linewidth=0.6)
        for b, g in zip(bars, gain):
            ax2.annotate(f"{g:+.1f}%", xy=(b.get_x() + b.get_width() / 2, g),
                         xytext=(0, 4 if g >= 0 else -13), textcoords="offset points",
                         ha="center", fontsize=9)
        ax2.axhline(0, color=GRAY, lw=1.0)
        ax2.set_xticks(rx)
        ax2.set_xticklabels([r["label"] for r in rest], rotation=18, ha="right", fontsize=9)
        ax2.set_ylabel("further gain over -O2 (%)")
        ax2.set_title("The real question: what is left after -O2?\n"
                      "(-O0 is not a baseline anyone ships)", fontsize=11)
        ax2.spines[["top", "right"]].set_visible(False)
        lo, hi = min(gain + [0]), max(gain + [0])
        ax2.set_ylim(lo - max(4, abs(lo) * 0.35), hi + max(6, abs(hi) * 0.35))

    fig.suptitle(f"{cpu_model()}  |  {gxx_version()}  |  1440x1080, median of {REPS} runs",
                 fontsize=9, color=GRAY, y=0.015)
    fig.tight_layout(rect=(0, 0.035, 1, 1))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT, dpi=150)
    print(f"\n写出 {OUT}")

    print("\n给正文用的数字：")
    for r in results:
        print(f"  {r['label']:22s} 中位 {r['total_med']:6.2f} ms  p99 {r['total_p99']:6.2f} ms  "
              f"vs -O0 {base / r['total_med']:.2f}x"
              + (f"  vs -O2 {o2['total_med'] / r['total_med']:.3f}x" if o2 else ""))


if __name__ == "__main__":
    main()
