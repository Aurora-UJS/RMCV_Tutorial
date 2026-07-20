// 编译选项对一段典型视觉流水线的实际收益。
// 由 adv_compile_flags_bench.py 用不同的 -O / -march / -flto 组合反复编译并计时。
//
// 工作负载刻意选成 RM 里真实存在的三段，且三段的瓶颈类型不同：
//   1) threshold  —— 访存密集，几乎没有算术，考验编译器能否向量化 + 预取
//   2) conv3x3    —— 计算密集，规则的乘加，是 SIMD 的主场
//   3) reduce     —— 归约，带循环依赖，考验能否拆成多路累加再合并
// 三段合起来，比只测一个 for 循环诚实得多。

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <random>
#include <vector>

constexpr int W = 1440, H = 1080;  // 与书中相机分辨率一致
constexpr int N = W * H;

// 1) 二值化：访存密集
static void threshold_op(const uint8_t* src, uint8_t* dst, uint8_t thr) {
  for (int i = 0; i < N; ++i) dst[i] = src[i] > thr ? 255 : 0;
}

// 2) 3x3 卷积（Sobel-x）：计算密集
static void conv3x3(const uint8_t* src, int16_t* dst) {
  for (int y = 1; y < H - 1; ++y) {
    const uint8_t* r0 = src + (y - 1) * W;
    const uint8_t* r1 = src + y * W;
    const uint8_t* r2 = src + (y + 1) * W;
    int16_t* o = dst + y * W;
    for (int x = 1; x < W - 1; ++x) {
      o[x] = static_cast<int16_t>(-r0[x - 1] + r0[x + 1] - 2 * r1[x - 1] +
                                  2 * r1[x + 1] - r2[x - 1] + r2[x + 1]);
    }
  }
}

// 3) 归约：带循环依赖的累加
static uint64_t reduce_op(const int16_t* src) {
  uint64_t acc = 0;
  for (int i = 0; i < N; ++i) acc += static_cast<uint64_t>(src[i] > 0 ? src[i] : -src[i]);
  return acc;
}

int main(int argc, char** argv) {
  const int reps = (argc > 1) ? std::atoi(argv[1]) : 200;

  std::vector<uint8_t> src(N), bin(N);
  std::vector<int16_t> grad(N, 0);
  std::mt19937 rng(42);  // 固定种子：同一份输入，跨编译选项可比
  for (int i = 0; i < N; ++i) src[i] = static_cast<uint8_t>(rng() & 0xFF);

  // 预热：把数据拉进缓存、让频率升上来，避免把冷启动算进结果
  uint64_t sink = 0;
  for (int i = 0; i < 20; ++i) {
    threshold_op(src.data(), bin.data(), 128);
    conv3x3(bin.data(), grad.data());
    sink += reduce_op(grad.data());
  }

  std::vector<double> t_thr, t_conv, t_red;
  t_thr.reserve(reps); t_conv.reserve(reps); t_red.reserve(reps);

  for (int i = 0; i < reps; ++i) {
    auto a = std::chrono::steady_clock::now();
    threshold_op(src.data(), bin.data(), 128);
    auto b = std::chrono::steady_clock::now();
    conv3x3(bin.data(), grad.data());
    auto c = std::chrono::steady_clock::now();
    sink += reduce_op(grad.data());
    auto d = std::chrono::steady_clock::now();

    using ms = std::chrono::duration<double, std::milli>;
    t_thr.push_back(ms(b - a).count());
    t_conv.push_back(ms(c - b).count());
    t_red.push_back(ms(d - c).count());
  }

  // sink 必须被用掉，否则整段计算可能被优化器整体删除，
  // 那样测到的就是"什么都不做有多快"。
  std::fprintf(stderr, "sink=%llu\n", static_cast<unsigned long long>(sink));

  // 每段逐次输出，统计交给 Python 侧做（中位数与 p99）
  for (int i = 0; i < reps; ++i)
    std::printf("%.6f %.6f %.6f\n", t_thr[i], t_conv[i], t_red[i]);
  return 0;
}
