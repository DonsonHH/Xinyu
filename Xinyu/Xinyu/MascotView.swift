import SwiftUI
import SDWebImageSwiftUI
import UIKit

struct MascotView: View {
    @Binding var showGetEmotionButton: Bool
    @Binding var navigateToEmotionFeedback: Bool
    @State private var isSpeaking: Bool = false
    @State private var currentGif: String? = nil
    @State private var showGreetingBubble: Bool = false
    @State private var showGetEmotionBubble: Bool = false
    @State private var showMultiActionBubble: Bool = false
    @State private var hasGotEmotion: Bool = false
    @State private var showIdleBubble: Bool = false
    @State private var idleBubbleText: String = ""
    private let imageName = "cat_avatar"
    private let idleGifs = ["cathello", "catyaotouzhayan", "cathaqian"]
    private let speakingGifs = ["catspeaking1", "catspeaking2"]
    private let idleDuration: TimeInterval = 8 // 闲置多久后自动卖萌
    private let gifDuration: TimeInterval = 5 // 动画时长（秒），请根据实际调整
    @State private var idleTimer: Timer? = nil
    @State private var hasShownHello: Bool = false
    var onTabSwitch: ((Int) -> Void)? = nil
    private let multiActionTips = [
        "接下来想和我一起做什么呢？",
        "让我陪你一起选择吧～",
        "你想体验哪种陪伴？",
        "需要我帮你做点什么吗？",
        "来吧，选一个你喜欢的方式吧！",
        "今天我们一起做点什么？"
    ]
    private let idleBubbleTexts = [
        "记得多喝水哦～",
        "休息一下，放松心情！",
        "今天也要加油鸭！",
        "保持微笑，世界会更美好！",
        "累了就眨眨眼，伸个懒腰吧！",
        "你是最棒的！"
    ]

    // 获取用户名
    private var userName: String {
        let name = UserProfileManager.shared.userProfile.nickname
        return name.isEmpty ? "朋友" : name
    }
    // 多样化打招呼
    private var greetings: [String] {
        [
            "\(userName)，你好！",
            "欢迎回来，\(userName)！",
            "早上好，\(userName)！",
            "很高兴见到你，\(userName)！",
            "\(userName)，今天心情怎么样？",
            "Hi，\(userName)！准备好开启新的一天了吗？"
        ]
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 打招呼气泡
            if showGreetingBubble {
                ChatBubbleView(text: greetings.randomElement() ?? "\(userName)，你好！")
                    .padding(.bottom, 110)
                    .padding(.leading, 80)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: showGreetingBubble)
            }
            // 获取今日情绪气泡
            if showGetEmotionBubble {
                VStack(alignment: .leading, spacing: 8) {
                    Text("要获取今日情绪状态吗？")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                    Button(action: {
                        showGetEmotionBubble = false
                        showGetEmotionButton = true
                        navigateToEmotionFeedback = true
                        hasGotEmotion = true
                    }) {
                        Text("点击获取今日情绪")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(16)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(ChatBubbleBackground())
                .padding(.bottom, 110)
                .padding(.leading, 80)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: showGetEmotionBubble)
            }
            // 多选气泡
            if showMultiActionBubble {
                VStack(alignment: .leading, spacing: 12) {
                    Text(multiActionTips.randomElement() ?? "接下来想和我一起做什么呢？")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    Button(action: {
                        showMultiActionBubble = false
                        showGetEmotionBubble = false
                        showGetEmotionButton = true
                        navigateToEmotionFeedback = true
                    }) {
                        Text("再次获取今日情绪状态")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(16)
                    }
                    Button(action: {
                        showMultiActionBubble = false
                        onTabSwitch?(1) // 切换到倾听界面Tab
                    }) {
                        Text("进入倾听界面和我聊天吧")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    Button(action: {
                        showMultiActionBubble = false
                        onTabSwitch?(2) // 切换到放松室Tab
                    }) {
                        Text("进入放松室放松身心吧")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(16)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(ChatBubbleBackground())
                .padding(.bottom, 110)
                .padding(.leading, 80)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: showMultiActionBubble)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showMultiActionBubble = false
                    }
                }
            }
            // 猫咪本体
            ZStack {
                Image(imageName)
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .opacity(isSpeaking ? 0 : 1)
                if let gif = currentGif, isSpeaking {
                    AnimatedImage(name: gif + ".gif")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + gifDuration) {
                                isSpeaking = false
                                currentGif = nil
                            }
                        }
                }
            }
            .onTapGesture {
                showIdleBubble = false
                if hasGotEmotion {
                    showMultiActionBubble = true
                    playSpeakingGif()
                } else {
                    showGetEmotionBubble = true
                    playSpeakingGif()
                }
            }
            // 闲置气泡
            if showIdleBubble {
                ChatBubbleView(text: idleBubbleText)
                    .padding(.bottom, 80)
                    .padding(.leading, 120)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: showIdleBubble)
            }
        }
        .onAppear {
            if !hasShownHello {
                playHelloGif()
                hasShownHello = true
            }
            startIdleTimer()
        }
        .onDisappear {
            idleTimer?.invalidate()
        }
    }

    private func playSpeakingGif() {
        if !isSpeaking {
            let gif = speakingGifs.randomElement() ?? speakingGifs[0]
            currentGif = gif
            isSpeaking = true
            resetIdleTimer()
        }
    }

    private func playIdleGif() {
        if !isSpeaking {
            let gif = idleGifs.randomElement() ?? idleGifs[0]
            currentGif = gif
            isSpeaking = true
            resetIdleTimer()
            // 每次都弹出闲置气泡
            idleBubbleText = idleBubbleTexts.randomElement() ?? ""
            showIdleBubble = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showIdleBubble = false
            }
        }
    }

    private func playHelloGif() {
        if !isSpeaking {
            currentGif = "cathello"
            isSpeaking = true
            showGreetingBubble = true
            resetIdleTimer()
            // hello动画和气泡一起消失
            DispatchQueue.main.asyncAfter(deadline: .now() + gifDuration) {
                isSpeaking = false
                currentGif = nil
                showGreetingBubble = false
                // 0.2秒后弹出"获取今日情绪状态"气泡
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showGetEmotionBubble = true
                }
            }
        }
    }

    private func startIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleDuration, repeats: true) { _ in
            playIdleGif()
        }
    }

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        startIdleTimer()
    }
}

// 聊天气泡View
struct ChatBubbleView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ChatBubbleBackground())
    }
}

// 聊天气泡背景，带毛玻璃和"小三角"吮吸效果
struct ChatBubbleBackground: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 毛玻璃
            VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            // 半透明白色叠加，提升对比度
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.82))
            // 边框
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            // 阴影
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
            // 小三角
            Triangle()
                .fill(Color.white.opacity(0.82))
                .frame(width: 22, height: 14)
                .offset(x: 24, y: 16)
                .shadow(color: Color.black.opacity(0.10), radius: 2, x: 0, y: 1)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
} 
