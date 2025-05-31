import SwiftUI
import AVFoundation

struct MoodAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var todayMood: MoodData = MoodData(
        date: Date(),
        mood: "平静",
        score: 75,
        description: "今天的心情比较平稳，保持积极向上的态度。"
    )
    
    // 使用主题管理器
    @ObservedObject private var themeManager = ThemeManager.shared
    // 添加用户资料管理器
    @ObservedObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // 使用全局背景颜色
                themeManager.globalBackgroundColor
                .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut(duration: 0.5), value: themeManager.globalBackgroundColor)
                
                ScrollView {
                    // 添加顶部空间
                    Spacer(minLength: 40)
                    
                    VStack(spacing: 25) {
                        // 今日情绪卡片
                        emotionCard
                        
                        // 新增的三个卡片
                        
                        // 开始交流卡片
                        NavigationLink(destination: VoiceInteractionView()) {
                            FunctionCard(
                                title: "开始交流",
                                description: "与心语AI助手开始对话，分享你的想法和感受",
                                iconName: "bubble.left.and.bubble.right.fill",
                                color: Color(red: 255/255, green: 159/255, blue: 10/255)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 个人信息卡片
                        NavigationLink(destination: ProfileView()) {
                            FunctionCard(
                                title: "个人信息",
                                description: "查看和编辑你的个人资料，管理你的账户信息",
                                iconName: "person.fill",
                                color: Color(red: 64/255, green: 156/255, blue: 255/255)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 设置卡片
                        NavigationLink(destination: SettingsView()) {
                            FunctionCard(
                                title: "设置",
                                description: "调整应用的外观和行为，管理隐私和通知设置",
                                iconName: "gear",
                                color: Color(red: 142/255, green: 142/255, blue: 147/255)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.top, 10)  // 调整整体 VStack 的顶部间距
                    .padding(.bottom, 20)
                }
                .edgesIgnoringSafeArea(.top)  // 确保滚动区域扩展到顶部安全区域外
            }
            .navigationBarHidden(true)
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            // 同步当前情绪状态
            if themeManager.currentEmotion != todayMood.mood {
                todayMood = MoodData(
                    date: Date(),
                    mood: themeManager.currentEmotion,
                    score: getScoreForEmotion(themeManager.currentEmotion),
                    description: getDescriptionForEmotion(themeManager.currentEmotion)
                )
            }
        }
    }
    
    // 今日情绪卡片
    private var emotionCard: some View {
        NavigationLink(destination: MoodDiaryView()) {
            VStack(spacing: 15) {
                Text("今日情绪")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(todayMood.mood)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                
                // 情绪分数环形进度条
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(todayMood.score) / 100)
                        .stroke(
                            Color(red: 255/255, green: 159/255, blue: 10/255),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(todayMood.score)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                }
                
                Text(todayMood.description)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 添加一个查看历史的小提示
                HStack {
                    Text("查看心情手帐")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                }
                .padding(.top, 5)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 根据情绪返回相应的分数
    private func getScoreForEmotion(_ emotion: String) -> Int {
        switch emotion {
        case "平静": return 75
        case "开心": return 90
        case "悲伤": return 40
        case "生气": return 30
        case "焦虑": return 50
        default: return 65
        }
    }
    
    // 根据情绪返回相应的描述
    private func getDescriptionForEmotion(_ emotion: String) -> String {
        switch emotion {
        case "平静": 
            return "今天的心情比较平稳，保持积极向上的态度。"
        case "开心": 
            return "今天心情非常愉快，充满活力与期待。"
        case "悲伤": 
            return "今天情绪有些低落，需要给自己一些关爱。"
        case "生气": 
            return "今天感到有些烦躁，需要找到平静的方式。"
        case "焦虑": 
            return "今天有些担忧，可以通过放松来缓解压力。"
        default: 
            return "今天的心情比较复杂，可以尝试整理思绪。"
        }
    }
}

// 功能卡片组件
struct FunctionCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            // 文本内容
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 右箭头
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .bold))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// 情绪数据模型
struct MoodData {
    let date: Date
    let mood: String
    let score: Int
    let description: String
}

struct MoodAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        MoodAnalysisView()
    }
} 
