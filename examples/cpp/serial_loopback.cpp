// 串口帧协议最小实现 + pty 回环自测
// 编译：g++ -O2 serial_loopback.cpp -o serial_loopback -lutil
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <pty.h>
#include <termios.h>
#include <unistd.h>

// ---- 协议定义：视觉 -> 电控 的云台指令帧 ----
#pragma pack(push, 1)             // 关闭结构体填充，保证帧布局与字节流一一对应
struct GimbalCmd {
    uint8_t head;                 // 帧头，固定 0xA5
    float   yaw;                  // 目标偏航角，单位度
    float   pitch;                // 目标俯仰角，单位度
    uint8_t fire;                 // 开火建议：0/1
    uint8_t crc;                  // 前 10 字节的 CRC8 校验
};
#pragma pack(pop)
static_assert(sizeof(GimbalCmd) == 11, "帧长必须是 11 字节");

// CRC8（多项式 0x31），逐位实现，够小够清楚
uint8_t crc8(const uint8_t* data, size_t len) {
    uint8_t crc = 0xFF;
    for (size_t i = 0; i < len; ++i) {
        crc ^= data[i];
        for (int b = 0; b < 8; ++b)
            crc = (crc & 0x80) ? uint8_t((crc << 1) ^ 0x31) : uint8_t(crc << 1);
    }
    return crc;
}

// ---- 配置串口为 raw 模式：115200, 8N1, 无流控 ----
bool configure_serial(int fd, speed_t baud = B115200) {
    termios tio{};
    if (tcgetattr(fd, &tio) != 0) return false;
    cfmakeraw(&tio);              // 关闭回显、行缓冲、特殊字符处理
    cfsetispeed(&tio, baud);
    cfsetospeed(&tio, baud);
    tio.c_cflag |= CLOCAL | CREAD;  // 忽略调制解调器信号，使能接收
    tio.c_cc[VMIN] = 1;           // 阻塞直到至少 1 字节到达
    tio.c_cc[VTIME] = 1;          // 字节间计时器（VMIN=1 时不生效，见正文）
    return tcsetattr(fd, TCSANOW, &tio) == 0;
}

// ---- 接收状态机：在字节流里找帧头、收满一帧、验 CRC ----
class FrameParser {
public:
    // 喂入一个字节；集齐合法帧时返回 true 并输出到 out
    bool feed(uint8_t byte, GimbalCmd& out) {
        if (pos_ == 0 && byte != 0xA5) return false;  // 还没同步上，丢弃
        buf_[pos_++] = byte;
        if (pos_ < sizeof(GimbalCmd)) return false;
        pos_ = 0;                                     // 收满 11 字节
        GimbalCmd frame;
        std::memcpy(&frame, buf_, sizeof(frame));
        if (crc8(buf_, sizeof(frame) - 1) != frame.crc) {
            std::printf("[parser] CRC mismatch, frame dropped\n");
            return false;                             // 整帧丢弃，重新找帧头
        }
        out = frame;
        return true;
    }
private:
    uint8_t buf_[sizeof(GimbalCmd)];
    size_t  pos_ = 0;
};

int main() {
    // openpty 创建一对互连的虚拟终端：写进 master 的字节从 slave 读出，
    // 行为等价于一根回环的串口线，让我们在没有硬件时也能测通整条链路
    int master, slave;
    if (openpty(&master, &slave, nullptr, nullptr, nullptr) != 0) {
        perror("openpty");
        return 1;
    }
    configure_serial(slave);

    // 发送端：打包一帧并写入
    GimbalCmd tx{};
    tx.head = 0xA5;
    tx.yaw = -12.5f;
    tx.pitch = 3.75f;
    tx.fire = 1;
    tx.crc = crc8(reinterpret_cast<uint8_t*>(&tx), sizeof(tx) - 1);
    auto send = [&](const void* data, size_t len) {
        if (write(master, data, len) != ssize_t(len)) perror("write");
    };
    send(&tx, sizeof(tx));
    // 模拟线路噪声：帧后混入两个垃圾字节，再发一条 CRC 损坏的帧
    uint8_t junk[2] = {0x00, 0xFF};
    send(junk, sizeof(junk));
    GimbalCmd bad = tx;
    bad.yaw = 99.0f;              // 改了数据但没有重算 CRC
    send(&bad, sizeof(bad));

    // 接收端：逐字节读取并喂给状态机
    FrameParser parser;
    GimbalCmd rx;
    int frames = 0, bytes = 0;
    uint8_t byte;
    while (bytes < int(sizeof(tx) + sizeof(junk) + sizeof(bad)) &&
           read(slave, &byte, 1) == 1) {
        ++bytes;
        if (parser.feed(byte, rx)) {
            ++frames;
            std::printf("[recv] yaw=%.2f pitch=%.2f fire=%d (crc ok)\n",
                        rx.yaw, rx.pitch, rx.fire);
        }
    }
    std::printf("bytes=%d, valid frames=%d\n", bytes, frames);
    return 0;
}
