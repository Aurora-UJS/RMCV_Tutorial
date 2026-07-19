// 颜色空间对比：同一场景的 BGR / 灰度 / HSV-H / HSV-V 四视图
#include <opencv2/opencv.hpp>

// 从比赛视频中取出 7 秒处的一帧
static cv::Mat grab_frame() {
    cv::VideoCapture cap("../test.mp4");   // 以 examples/cpp/ 为工作目录
    CV_Assert(cap.isOpened());
    cap.set(cv::CAP_PROP_POS_MSEC, 7000);   // 定位到 7.0 s
    cv::Mat frame;
    CV_Assert(cap.read(frame));
    return frame;
}

static void label(cv::Mat& m, const std::string& text) {
    cv::rectangle(m, {0, 0, 250, 34}, cv::Scalar(0, 0, 0), -1);
    cv::putText(m, text, {8, 24}, cv::FONT_HERSHEY_SIMPLEX, 0.7,
                cv::Scalar(255, 255, 255), 2, cv::LINE_AA);
}

int main() {
    // 取蓝方步兵所在区域并放大一倍，方便观察细节
    cv::Mat bgr;
    cv::resize(grab_frame()(cv::Rect(560, 400, 340, 260)), bgr, {}, 2, 2,
               cv::INTER_NEAREST);

    cv::Mat gray, hsv;
    cv::cvtColor(bgr, gray, cv::COLOR_BGR2GRAY);
    cv::cvtColor(bgr, hsv, cv::COLOR_BGR2HSV);
    std::vector<cv::Mat> ch;
    cv::split(hsv, ch);  // ch[0]=H 色相, ch[1]=S 饱和度, ch[2]=V 明度

    // 拼成 2x2 面板（单通道图转回三通道以便拼接）
    cv::Mat g3, h3, v3;
    cv::cvtColor(gray, g3, cv::COLOR_GRAY2BGR);
    cv::cvtColor(ch[0], h3, cv::COLOR_GRAY2BGR);
    cv::cvtColor(ch[2], v3, cv::COLOR_GRAY2BGR);
    cv::Mat a = bgr.clone();
    label(a, "1. BGR (original)");
    label(g3, "2. grayscale");
    label(h3, "3. HSV: H channel");
    label(v3, "4. HSV: V channel");
    cv::Mat top, bottom, panel;
    cv::hconcat(a, g3, top);
    cv::hconcat(h3, v3, bottom);
    cv::vconcat(top, bottom, panel);

    cv::imwrite("cpp-opencv-colorspaces.png", panel);
    std::printf("panel: %dx%d, channels=%d\n", panel.cols, panel.rows, panel.channels());
    return 0;
}
