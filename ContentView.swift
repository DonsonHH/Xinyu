import SwiftUI

struct ContentView: View {
    // 第一阶段动画状态（开屏效果）
    @State private var splashPhase = true
    @State private var splashOpacity = 0.0
    @State private var splashLogoScale = 0.5
    @State private var splashLogoRotation = 0.0
    @State private var splashTextOffset = 30.0
    
    // 第二阶段动画状态（主界面效果）
    @State private var isAnimating = false
    @State private var backgroundOpacity = 0.0
    @State private var logoScale = 1.0
    @State private var buttonOpacity = 0.0
    
    // 添加圆圈交互状态
    @State private var circleStates: [Bool] = [false, false, false]
    @State private var circleScales: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var circleSpeeds: [Double] = [1.0, 1.0, 1.0]
    
    // 使用主题管理器
    @ObservedObject private var themeManager = ThemeManager.shared
    // 添加用户资料管理器
    @ObservedObject private var profileManager = UserProfileManager.shared
    
    // 定义主题色
    private let mainColor = Color(red: 255/255, green: 159/255, blue: 10/255) // 橙色
    private let accentColor = Color(red: 255/255, green: 255/255, blue: 255/255) // 白色
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景层
                ZStack {
                    // 判断是否在开屏阶段
                    if splashPhase {
                        // 渐变背景 - 开屏阶段
                    LinearGradient(
                        gradient: Gradient(colors: [
                                mainColor,
                                mainColor.opacity(0.8),
                                mainColor.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
                    } else {
                        // 使用全局背景颜色 - 主界面阶段
                        themeManager.globalBackgroundColor
                            .edgesIgnoringSafeArea(.all)
                            .animation(.easeInOut(duration: 0.5), value: themeManager.globalBackgroundColor)
                    }
                    
                    // 动态背景效果
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(splashPhase ? accentColor.opacity(0.1) : mainColor.opacity(0.1))
                            .frame(width: 200)
                            .offset(
                                x: isAnimating ? 
                                    sin(Double(index) * .pi / 2) * 150 + 
                                    cos(Double(index) * .pi / 3) * 50 : 
                                    -sin(Double(index) * .pi / 2) * 150 - 
                                    cos(Double(index) * .pi / 3) * 50,
                                y: isAnimating ? 
                                    cos(Double(index) * .pi / 2) * 100 + 
                                    sin(Double(index) * .pi / 3) * 30 : 
                                    -cos(Double(index) * .pi / 2) * 100 - 
                                    sin(Double(index) * .pi / 3) * 30
                            )
                            .animation(
                                Animation.easeInOut(duration: (4 + Double(index)) / circleSpeeds[index])
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.8)
                                    .speed(0.8),
                                value: isAnimating
                            )
                            .blur(radius: circleStates[index] ? 1 : 3)
                            .scaleEffect(circleScales[index])
                            .animation(
                                Animation.spring(
                                    response: 0.3,
                                    dampingFraction: 0.6,
                                    blendDuration: 0.3
                                ),
                                value: circleScales[index]
                            )
                            .onTapGesture {
                                handleCircleTap(index: index)
                            }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // 顶部导航栏
                    HStack {
                        Spacer()
                        // 移除设置按钮
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Logo 组合
                    ZStack {
                        // 背景光晕 - 增强效果
                        Circle()
                            .fill(splashPhase ? accentColor : mainColor)
                            .frame(width: splashPhase ? 90 : 100) // 增大光晕尺寸
                            .opacity(splashPhase ? 0.2 : 0.3) // 增加不透明度
                            .blur(radius: splashPhase ? 10 : 15) // 增加模糊效果
                            .scaleEffect(splashPhase ? (splashLogoScale * 1.2) : (isAnimating ? 1.4 : 0.7)) // 增大缩放范围
                            .animation(
                                splashPhase ? nil : Animation.easeInOut(duration: 1.5) // 加快动画速度
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        // 第二层光晕 - 添加额外的动态效果
                        if !splashPhase {
                            Circle()
                                .fill(mainColor)
                                .frame(width: 160)
                                .opacity(0.15)
                                .blur(radius: 20)
                                .scaleEffect(isAnimating ? 1.3 : 0.8)
                                .animation(
                                    Animation.easeInOut(duration: 2)
                                        .repeatForever(autoreverses: true)
                                        .delay(0.5),
                                    value: isAnimating
                                )
                        }
                        
                        // 主 Logo
                        Image(systemName: "waveform.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .foregroundColor(splashPhase ? accentColor : mainColor)
                            .rotationEffect(.degrees(splashPhase ? splashLogoRotation : 0))
                            .scaleEffect(splashPhase ? splashLogoScale : logoScale)
                            .opacity(splashPhase ? splashOpacity : 1)
                    }
                    
                    // 标题组
                    VStack(spacing: 8) {
                        Text("心语")
                            .font(.system(size: splashPhase ? 32 : 42, weight: .bold, design: .rounded))
                            .foregroundColor(splashPhase ? accentColor : mainColor)
                            .opacity(splashPhase ? splashOpacity : 1)
                            .offset(y: splashPhase ? splashTextOffset : 0)
                        
                        Text("用声音传递心意")
                            .font(.system(size: splashPhase ? 16 : 18, weight: .medium, design: .rounded))
                            .foregroundColor(splashPhase ? accentColor.opacity(0.8) : .gray)
                            .opacity(splashPhase ? splashOpacity : 1)
                            .offset(y: splashPhase ? splashTextOffset : 0)
                    }
                    
                    Spacer().frame(height: 60)
                    
                    // 开始按钮
                    NavigationLink(destination: EmotionFeedbackView()) {
                        HStack {
                            Image(systemName: "waveform")
                                .font(.title3)
                            Text("获取今日情绪吧～")
                                .font(.headline)
                        }
                        .foregroundColor(mainColor)
                        .frame(width: 200, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(accentColor)
                                .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                        .opacity(splashPhase ? 0 : buttonOpacity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
            .edgesIgnoringSafeArea(.all)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // 第一阶段：开屏动画
            withAnimation(.easeIn(duration: 0.8)) {
                splashOpacity = 1.0
            }
            
            withAnimation(.spring(
                response: 0.8,
                dampingFraction: 0.6,
                blendDuration: 0.6
            ).delay(0.3)) {
                splashLogoScale = 1.0
                splashLogoRotation = 360
                splashTextOffset = 0
            }
            
            // 延迟后进入第二阶段：主界面动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    splashPhase = false
                }
                
                // 启动主界面动画
                withAnimation(.easeIn(duration: 0.8)) {
                    backgroundOpacity = 1.0
                }
                
                withAnimation(.spring(
                    response: 0.8,
                    dampingFraction: 0.6,
                    blendDuration: 0.6
                ).delay(0.3)) {
                    isAnimating = true
                    logoScale = 1.0
                }
                
                // 延迟显示按钮
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        buttonOpacity = 1.0
                    }
                }
            }
        }
    }
    
    // 添加圆圈点击处理函数
    private func handleCircleTap(index: Int) {
        // 重置其他圆圈状态
        for i in 0..<circleStates.count {
            if i != index {
                circleStates[i] = false
                withAnimation {
                    circleScales[i] = 1.0
                    circleSpeeds[i] = 1.0
                }
            }
        }
        
        // 切换当前圆圈状态
        circleStates[index].toggle()
        
        if circleStates[index] {
            // 加速和放大效果
            withAnimation(.spring(
                response: 0.2,  // 加快放大动画
                dampingFraction: 0.6,
                blendDuration: 0.2
            )) {
                circleScales[index] = 1.3
                circleSpeeds[index] = 4.0  // 速度提高到4倍
            }
            
            // 0.4秒后开始缩小
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(
                    response: 0.3,
                    dampingFraction: 0.7,
                    blendDuration: 0.3
                )) {
                    circleScales[index] = 1.0
                }
            }
            
            // 1.5秒后恢复速度
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    circleStates[index] = false
                    circleSpeeds[index] = 1.0
                }
            }
        } else {
            // 直接恢复
            withAnimation {
                circleScales[index] = 1.0
                circleSpeeds[index] = 1.0
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
