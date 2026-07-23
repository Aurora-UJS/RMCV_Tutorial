#!/usr/bin/env python3
"""Render or remeasure the compile-option benchmark used by the book.

The default mode renders the fixed record printed in the chapter, so rebuilding
the figure does not silently replace source data with a noisy local run. Pass
``--measure`` to compile and run the C++ workload on the current machine.

Output: chapters/5.Advanced/images/adv-compile-flags.png
Workload: examples/advanced/adv_compile_flags_bench.cpp
"""

import argparse
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

BLUE, MAGENTA, GRAY = "#3B6FD4", "#D6336C", "#8A8A8A"
mpl.rcParams.update({"font.size": 10.5, "axes.linewidth": 0.8})

HERE = Path(__file__).resolve().parent
SRC = HERE / "adv_compile_flags_bench.cpp"
OUT = HERE.parent.parent / "chapters" / "5.Advanced" / "images" / "adv-compile-flags.png"
BUILD = Path(os.environ.get("RMCV_BENCH_TMP", "/tmp")) / "rmcv_flag_bench"

DEFAULT_REPS = 300
CONFIGS = [
    ("-O0", ["-O0"]),
    ("-O2", ["-O2"]),
    ("-O3", ["-O3"]),
    ("-O3 -march=native", ["-O3", "-march=native"]),
    ("-O3 -march=native -flto", ["-O3", "-march=native", "-flto"]),
]

# Fixed summary from the environment stated in performance_tuning.typ; the raw
# samples are not retained. Segment medians are rounded for plotting, while
# total_med and total_p99 summarize each measured iteration's total.
RECORDED_RESULTS = [
    {"label": "-O0", "med": [6.06, 3.22, 2.16], "total_med": 11.45, "total_p99": 13.21},
    {"label": "-O2", "med": [0.61, 0.72, 0.16], "total_med": 1.49, "total_p99": 1.69},
    {"label": "-O3", "med": [0.04, 0.16, 0.16], "total_med": 0.36, "total_p99": 0.38},
    {"label": "-O3 -march=native", "med": [0.05, 0.18, 0.17], "total_med": 0.40, "total_p99": 0.42},
    {"label": "-O3 -march=native -flto", "med": [0.05, 0.18, 0.17], "total_med": 0.40, "total_p99": 0.42},
]
RECORDED_ENV = (
    "i7-13790F | g++ 13.3.0 | 1440x1080 | CPU 2 | "
    "20 warm-ups + 300 measured iterations"
)


def cpu_model() -> str:
    try:
        with open("/proc/cpuinfo", encoding="utf-8") as cpuinfo:
            for line in cpuinfo:
                if line.startswith("model name"):
                    return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return platform.processor() or "unknown CPU"


def gxx_version() -> str:
    proc = subprocess.run(["g++", "--version"], capture_output=True, text=True, check=False)
    return proc.stdout.splitlines()[0] if proc.stdout else "g++ ?"


def selected_cpu() -> str | None:
    requested = os.environ.get("RMCV_BENCH_CPU")
    if requested is not None:
        return requested
    if hasattr(os, "sched_getaffinity"):
        allowed = sorted(os.sched_getaffinity(0))
        if allowed:
            return str(allowed[0])
    return None


def vector_census(label: str, flags: list[str]) -> dict[str, int]:
    """Count disassembly lines mentioning each vector-register width.

    These are not instruction counts and do not identify whether a line belongs
    to the benchmark hot path. They are only a coarse generated-code check.
    """
    tag = label.replace(" ", "_").replace("-", "").replace("=", "")
    probe = BUILD / f"probe_{tag}"
    probe.unlink(missing_ok=True)
    subprocess.run(
        ["g++", "-std=c++17", *flags, str(SRC), "-o", str(probe)],
        check=True,
    )
    disassembly = subprocess.run(
        ["objdump", "-d", str(probe)], capture_output=True, text=True, check=True
    ).stdout
    return {
        width: sum(f"%{width}" in line for line in disassembly.splitlines())
        for width in ("xmm", "ymm", "zmm")
    }


def run_one(label: str, flags: list[str], reps: int, pin_cpu: str | None) -> dict:
    tag = label.replace(" ", "_").replace("-", "").replace("=", "")
    executable = BUILD / f"bench_{tag}"
    subprocess.run(
        ["g++", "-std=c++17", *flags, str(SRC), "-o", str(executable)],
        check=True,
    )

    run_cmd = [str(executable), str(reps)]
    if pin_cpu is not None and shutil.which("taskset"):
        run_cmd = ["taskset", "-c", pin_cpu, *run_cmd]
    proc = subprocess.run(run_cmd, capture_output=True, text=True, check=True)
    rows = [list(map(float, line.split())) for line in proc.stdout.splitlines() if line.strip()]
    if len(rows) != reps or any(len(row) != 3 for row in rows):
        raise RuntimeError(f"{label}: expected {reps} rows with three fields")

    samples = np.asarray(rows)
    totals = samples.sum(axis=1)
    return {
        "label": label,
        "med": np.median(samples, axis=0),
        "total_med": float(np.median(totals)),
        "total_p99": float(np.percentile(totals, 99)),
    }


def measure(reps: int) -> tuple[list[dict], str]:
    if shutil.which("g++") is None or shutil.which("objdump") is None:
        sys.exit("--measure requires g++ and objdump")
    BUILD.mkdir(parents=True, exist_ok=True)
    pin_cpu = selected_cpu() if shutil.which("taskset") else None
    print(f"CPU: {cpu_model()}")
    print(f"{gxx_version()} | reps={reps} | pinned CPU={pin_cpu or 'none'}")

    results = []
    for label, flags in CONFIGS:
        try:
            result = run_one(label, flags, reps, pin_cpu)
            census = vector_census(label, flags)
        except (subprocess.CalledProcessError, RuntimeError) as exc:
            print(f"  [skip] {label}: {exc}")
            continue
        results.append(result)
        segments = "  ".join(
            f"{name}={value:.3f}" for name, value in zip(("thr", "conv", "red"), result["med"])
        )
        print(
            f"  {label:30s} median {result['total_med']:.3f} ms  "
            f"p99 {result['total_p99']:.3f} ms  [{segments}]  registers={census}"
        )
    if not results:
        sys.exit("no benchmark configuration completed")

    environment = (
        f"{cpu_model()} | {gxx_version()} | 1440x1080 | "
        f"CPU {pin_cpu or 'not pinned'} | 20 warm-ups + {reps} measured iterations"
    )
    return results, environment


def render(results: list[dict], environment: str) -> None:
    baseline = next((result for result in results if result["label"] == "-O0"), None)
    if baseline is None:
        raise ValueError("results must contain the -O0 baseline")
    base = baseline["total_med"]
    o2 = next((result for result in results if result["label"] == "-O2"), None)
    labels = [result["label"] for result in results]
    x_positions = np.arange(len(results))
    segment_names = ["threshold", "3x3 convolution", "reduction"]
    colors = [BLUE, MAGENTA, GRAY]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12.8, 5.2))
    bottoms = np.zeros(len(results))
    for index, (name, color) in enumerate(zip(segment_names, colors)):
        values = np.asarray([result["med"][index] for result in results])
        ax1.bar(
            x_positions, values, 0.6, bottom=bottoms, color=color,
            label=name, edgecolor="white", linewidth=0.6,
        )
        bottoms += values
    p99_values = np.asarray([result["total_p99"] for result in results])
    total_medians = np.asarray([result["total_med"] for result in results])
    for index, result in enumerate(results):
        ax1.annotate(
            f"{result['total_med']:.2f} ms\n{base / result['total_med']:.1f}x vs -O0",
            xy=(index, p99_values[index]), xytext=(0, 5), textcoords="offset points",
            ha="center", fontsize=8.5,
        )
    ax1.vlines(
        x_positions, total_medians, p99_values, color="black", linewidth=0.9,
        label="total p99",
    )
    ax1.scatter(x_positions, p99_values, marker="_", s=90, color="black", zorder=4)
    ax1.set_xticks(x_positions)
    ax1.set_xticklabels(labels, rotation=18, ha="right", fontsize=8.5)
    ax1.set_ylabel("median time per frame (ms)")
    ax1.set_ylim(0, max(bottoms.max(), p99_values.max()) * 1.12)
    ax1.set_title("(a) segment medians by compile option", fontsize=10.5, loc="left")
    ax1.legend(fontsize=8.5, frameon=False)
    ax1.spines[["top", "right"]].set_visible(False)

    if o2 is not None:
        later = [result for result in results if result["label"] != "-O0"]
        right_x = np.arange(len(later))
        gains = [(o2["total_med"] / result["total_med"] - 1) * 100 for result in later]
        bars = ax2.bar(
            right_x, gains, 0.55,
            color=[BLUE if gain >= 0 else MAGENTA for gain in gains],
            edgecolor="white", linewidth=0.6,
        )
        for bar, gain in zip(bars, gains):
            ax2.annotate(
                f"{gain:+.1f}%", xy=(bar.get_x() + bar.get_width() / 2, gain),
                xytext=(0, 4 if gain >= 0 else -13), textcoords="offset points",
                ha="center", fontsize=8.5,
            )
        ax2.axhline(0, color=GRAY, lw=1.0)
        ax2.set_xticks(right_x)
        ax2.set_xticklabels(
            [result["label"] for result in later], rotation=18, ha="right", fontsize=8.5
        )
        ax2.set_ylabel("speedup relative to -O2 (%)")
        ax2.set_title("(b) measured speedup after -O2", fontsize=10.5, loc="left")
        ax2.spines[["top", "right"]].set_visible(False)
        low, high = min(gains + [0]), max(gains + [0])
        ax2.set_ylim(low - max(4, abs(low) * 0.35), high + max(6, abs(high) * 0.25))

    fig.suptitle(
        "Compile-option benchmark for one fixed workload",
        fontsize=12.5, fontweight="bold", x=0.012, ha="left", y=0.985,
    )
    fig.text(0.5, 0.012, environment, ha="center", va="bottom", fontsize=8, color=GRAY)
    fig.tight_layout(rect=(0, 0.065, 1, 0.94))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT, dpi=150, metadata={"Software": "Matplotlib"})
    plt.close(fig)
    print(f"wrote {OUT}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--measure", action="store_true",
        help="compile and measure on this machine instead of rendering the fixed record",
    )
    parser.add_argument("--reps", type=int, default=DEFAULT_REPS)
    args = parser.parse_args()
    if args.reps <= 0:
        parser.error("--reps must be positive")

    if args.measure:
        results, environment = measure(args.reps)
    else:
        results = [dict(result, med=np.asarray(result["med"])) for result in RECORDED_RESULTS]
        environment = RECORDED_ENV
        print("rendering the fixed chapter record; pass --measure to rerun the benchmark")
    render(results, environment)


if __name__ == "__main__":
    main()
