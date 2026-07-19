// 装甲板检测最小流水线，逻辑与模型改编自开源框架 rm_vision
// （chenjunnn/rm_auto_aim，MIT License）：
// 亮度二值化 -> 找灯条(几何筛选+颜色投票) -> 同色配对(几何验证) -> 数字分类器定生死
// 编译：g++ -O2 lightbar_pipeline.cpp -o lightbar_pipeline $(pkg-config --cflags --libs opencv4)
#include <opencv2/opencv.hpp>
#include <opencv2/dnn.hpp>

// 从比赛视频中取出 7 秒处的一帧
static cv::Mat grab_frame() {
    cv::VideoCapture cap("../test.mp4");   // 以 examples/cpp/ 为工作目录
    CV_Assert(cap.isOpened());
    cap.set(cv::CAP_PROP_POS_MSEC, 7000);   // 定位到 7.0 s
    cv::Mat frame;
    CV_Assert(cap.read(frame));
    return frame;
}

enum Color { RED, BLUE };
enum class ArmorType { SMALL, LARGE };

// 灯条：在旋转矩形基础上补充 top/bottom 端点、长宽和倾角
struct Light : cv::RotatedRect {
    explicit Light(cv::RotatedRect box) : cv::RotatedRect(box) {
        cv::Point2f p[4];
        box.points(p);
        std::sort(p, p + 4, [](auto& a, auto& b) { return a.y < b.y; });
        top = (p[0] + p[1]) / 2;
        bottom = (p[2] + p[3]) / 2;
        length = cv::norm(top - bottom);
        width = cv::norm(p[0] - p[1]);
        // 相对竖直方向的倾角：正立的灯条接近 0 度
        tilt_angle = std::atan2(std::abs(top.x - bottom.x),
                                std::abs(top.y - bottom.y)) / CV_PI * 180;
    }
    int color;
    cv::Point2f top, bottom;
    double length, width;
    float tilt_angle;
};

// 装甲板候选：一对灯条，按左右排好
struct Armor {
    Armor(const Light& l1, const Light& l2, ArmorType t) : type(t) {
        left = l1.center.x < l2.center.x ? l1 : l2;
        right = l1.center.x < l2.center.x ? l2 : l1;
        center = (left.center + right.center) / 2;
    }
    Light left{{}}, right{{}};
    cv::Point2f center;
    ArmorType type;
    std::string number;
    float confidence = 0.f;
};

// 灯条几何判据：细长（宽长比 0.1~0.4）且基本竖直（倾角 < 40 度）
static bool is_light(const Light& l) {
    float ratio = l.width / l.length;
    return 0.1f < ratio && ratio < 0.4f && l.tilt_angle < 40.f;
}

// 两根灯条围成的矩形里若夹着第三根灯条，这一对不可能是装甲板
static bool contain_light(const Light& a, const Light& b,
                          const std::vector<Light>& lights) {
    auto rect = cv::boundingRect(
        std::vector<cv::Point2f>{a.top, a.bottom, b.top, b.bottom});
    for (const auto& t : lights) {
        if (t.center == a.center || t.center == b.center) continue;
        if (rect.contains(t.top) || rect.contains(t.bottom) ||
            rect.contains(t.center))
            return true;
    }
    return false;
}

// 装甲板几何判据：灯条等长、间距合理（以灯条长度为尺子）、连线近水平；
// 间距还顺便区分出大小装甲板
static bool is_armor(const Light& a, const Light& b, ArmorType& type) {
    float length_ratio = std::min(a.length, b.length) /
                         std::max(a.length, b.length);
    if (length_ratio < 0.7f) return false;
    float avg_len = (a.length + b.length) / 2;
    float dist = cv::norm(a.center - b.center) / avg_len;   // 单位：灯条长
    bool small_ok = 0.8f <= dist && dist < 3.2f;
    bool large_ok = 3.2f <= dist && dist < 5.5f;
    if (!small_ok && !large_ok) return false;
    cv::Point2f d = a.center - b.center;
    float angle = std::abs(std::atan(d.y / d.x)) / CV_PI * 180;
    if (angle >= 35.f) return false;
    type = small_ok ? ArmorType::SMALL : ArmorType::LARGE;
    return true;
}

// 数字分类：把两灯条之间的区域透视矫正成 20x28 小图，交给 MLP
static void classify(const cv::Mat& src, Armor& armor,
                     cv::dnn::Net& net, const std::vector<std::string>& names) {
    const int light_len = 12, warp_h = 28;
    const int warp_w = armor.type == ArmorType::SMALL ? 32 : 54;
    const int top_y = (warp_h - light_len) / 2 - 1, bottom_y = top_y + light_len;
    cv::Point2f from[4] = {armor.left.bottom, armor.left.top,
                           armor.right.top, armor.right.bottom};
    cv::Point2f to[4] = {{0, (float)bottom_y}, {0, (float)top_y},
                         {(float)warp_w - 1, (float)top_y},
                         {(float)warp_w - 1, (float)bottom_y}};
    cv::Mat num;
    cv::warpPerspective(src, num, cv::getPerspectiveTransform(from, to),
                        {warp_w, warp_h});
    num = num(cv::Rect((warp_w - 20) / 2, 0, 20, 28));
    cv::cvtColor(num, num, cv::COLOR_BGR2GRAY);
    cv::threshold(num, num, 0, 255, cv::THRESH_BINARY | cv::THRESH_OTSU);

    cv::Mat blob;
    cv::dnn::blobFromImage(num / 255.0, blob);
    net.setInput(blob);
    cv::Mat out = net.forward();
    // softmax 后取最大概率的类别
    cv::Mat prob;
    cv::exp(out - *std::max_element(out.begin<float>(), out.end<float>()), prob);
    prob /= cv::sum(prob)[0];
    cv::Point id;
    double conf;
    cv::minMaxLoc(prob.reshape(1, 1), nullptr, &conf, nullptr, &id);
    armor.number = names[id.x];
    armor.confidence = float(conf);
}

int main() {
    cv::Mat frame = grab_frame();

    // 1) 只做亮度二值化：灯条无论红蓝，共同特征都是“亮”
    cv::Mat gray, binary;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    cv::threshold(gray, binary, 160, 255, cv::THRESH_BINARY);

    // 2) 找轮廓 -> 旋转矩形 -> 几何筛选出灯条
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(binary, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    std::vector<Light> lights;
    for (const auto& contour : contours) {
        if (contour.size() < 5) continue;
        Light light(cv::minAreaRect(contour));
        if (!is_light(light)) continue;

        // 3) 颜色投票：统计轮廓内 B、R 通道像素值之和，谁大就是谁。
        //    实车低曝光域中过曝白芯 B≈R 互相抵消，胜负由斑块内带色像素决定
        cv::Rect roi = light.boundingRect() & cv::Rect{0, 0, frame.cols, frame.rows};
        long sum_b = 0, sum_r = 0;
        for (int y = roi.y; y < roi.y + roi.height; ++y)
            for (int x = roi.x; x < roi.x + roi.width; ++x)
                if (cv::pointPolygonTest(contour, cv::Point2f(x, y), false) >= 0) {
                    auto px = frame.at<cv::Vec3b>(y, x);   // BGR 顺序
                    sum_b += px[0];
                    sum_r += px[2];
                }
        light.color = sum_b > sum_r ? BLUE : RED;
        lights.push_back(light);
    }

    // 灯条可视化：品红 = 判为蓝方，青色 = 判为红方
    cv::Mat vis = frame.clone();
    for (const auto& l : lights) {
        auto c = l.color == BLUE ? cv::Scalar(255, 0, 255) : cv::Scalar(255, 255, 0);
        cv::line(vis, l.top, l.bottom, c, 2, cv::LINE_AA);
    }
    std::printf("lights: %zu\n", lights.size());

    // 4) 配对：只在同色灯条间进行，先排除夹灯情形，再过几何判据
    const int detect_color = BLUE;                  // 我方为红方，打蓝色装甲板
    std::vector<Armor> candidates;
    for (size_t i = 0; i < lights.size(); ++i)
        for (size_t j = i + 1; j < lights.size(); ++j) {
            const Light &a = lights[i], &b = lights[j];
            if (a.color != detect_color || b.color != detect_color) continue;
            if (contain_light(a, b, lights)) continue;
            ArmorType type;
            if (!is_armor(a, b, type)) continue;
            candidates.emplace_back(a, b, type);
            // 候选先画细黄框
            cv::line(vis, a.top, b.bottom, {0, 255, 255}, 1, cv::LINE_AA);
            cv::line(vis, a.bottom, b.top, {0, 255, 255}, 1, cv::LINE_AA);
        }
    std::printf("geometry candidates: %zu\n", candidates.size());

    // 5) 数字分类器定生死：置信度不足或判为负样本的候选全部淘汰
    auto net = cv::dnn::readNetFromONNX("model/mlp.onnx");
    std::vector<std::string> names = {"1", "2", "3", "4", "5",
                                      "outpost", "guard", "base", "negative"};
    for (auto& c : candidates) {
        classify(frame, c, net, names);
        std::printf("candidate center=(%.0f, %.0f) -> %s %.1f%%\n",
                    c.center.x, c.center.y, c.number.c_str(),
                    c.confidence * 100);
        if (c.number == "negative" || c.confidence < 0.7f) continue;
        // 幸存者：画粗绿交叉线 + 红心 + 编号
        cv::line(vis, c.left.top, c.right.bottom, {0, 255, 0}, 2, cv::LINE_AA);
        cv::line(vis, c.left.bottom, c.right.top, {0, 255, 0}, 2, cv::LINE_AA);
        cv::circle(vis, c.center, 4, {0, 0, 255}, -1, cv::LINE_AA);
        cv::putText(vis, c.number + cv::format(": %.1f%%", c.confidence * 100),
                    c.left.top + cv::Point2f(-10, -8), cv::FONT_HERSHEY_SIMPLEX,
                    0.6, {0, 255, 255}, 2, cv::LINE_AA);
    }

    // 输出面板与特写
    auto label = [](cv::Mat& m, const std::string& text) {
        cv::rectangle(m, {0, 0, 700, 44}, cv::Scalar(0, 0, 0), -1);
        cv::putText(m, text, {10, 32}, cv::FONT_HERSHEY_SIMPLEX, 1.0,
                    cv::Scalar(255, 255, 255), 2, cv::LINE_AA);
    };
    cv::Mat b3, zoom;
    cv::cvtColor(binary, b3, cv::COLOR_GRAY2BGR);
    cv::Mat a1 = frame.clone();
    cv::resize(vis(cv::Rect(560, 400, 400, 320)), zoom, {1280, 1024}, 0, 0,
               cv::INTER_NEAREST);
    label(a1, "1. input frame (t=7.0s)");
    label(b3, "2. binary (gray>160)");
    label(vis, "3. light candidates + color vote");
    label(zoom, "4. zoom: cascade verdict");
    cv::Mat top, bottom, panel;
    cv::hconcat(a1, b3, top);
    cv::hconcat(vis, zoom, bottom);
    cv::vconcat(top, bottom, panel);
    cv::imwrite("cpp-opencv-lightbar.png", panel);
    cv::imwrite("cpp-opencv-armor-zoom.png", zoom);
    return 0;
}
