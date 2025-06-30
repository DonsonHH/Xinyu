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
    @State private var showingProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            themeManager.globalBackgroundColor
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 0.5), value: themeManager.globalBackgroundColor)
            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .background(themeManager.globalBackgroundColor.opacity(0.15))
                            )
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                    Text("心迹")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .background(themeManager.globalBackgroundColor.opacity(0.15))
                            )
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.95))
                .shadow(color: Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.05), radius: 8, x: 0, y: 4)
                // 主体内容
                ScrollView {
                    Spacer(minLength: 40)
                    VStack(spacing: 25) {
                        // 今日情绪卡片
                        emotionCard
                        Spacer(minLength: 30)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
            }
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
        VStack(spacing: 18) {
            NavigationLink(destination: MoodDiaryView()) {
                VStack(spacing: 15) {
                    Text("今日情绪")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                    Text(todayMood.mood)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
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
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            // 日历视图区块
            EmotionCalendarView()
        }
        .padding(.horizontal, 16)
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

// 在文件末尾添加EmotionCalendarView组件
struct EmotionCalendarView: View {
    // 示例数据：日期-emoji
    let emotionMap: [Int: String] = [
        17: "😊", 18: "😊", 19: "😊", 20: "😊", 21: "😊",
        22: "🐱", 23: "😊", 24: "😊"
    ]
    let today = Calendar.current.component(.day, from: Date())
    let weekSymbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
    let daysInMonth: Int
    let firstWeekday: Int
    init() {
        let calendar = Calendar.current
        let date = Date()
        let range = calendar.range(of: .day, in: .month, for: date) ?? 1..<31
        daysInMonth = range.count
        let comps = calendar.dateComponents([.year, .month], from: date)
        let firstDay = calendar.date(from: comps) ?? date
        firstWeekday = calendar.component(.weekday, from: firstDay) - 1 // 0=周日
    }
    @State private var selectedDay: Int? = Calendar.current.component(.day, from: Date())
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("日历视图")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 30/255, green: 40/255, blue: 90/255))
                Spacer()
            }
            .padding(.horizontal, 6)
            // 星期标题
            HStack(spacing: 0) {
                ForEach(weekSymbols, id: \ .self) { w in
                    Text(w)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 30/255, green: 40/255, blue: 90/255))
                        .frame(maxWidth: .infinity)
                }
            }
            // 日历主体
            let total = daysInMonth + firstWeekday
            let rows = Int(ceil(Double(total) / 7.0))
            VStack(spacing: 6) {
                ForEach(0..<rows, id: \ .self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \ .self) { col in
                            let day = row * 7 + col - firstWeekday + 1
                            Group {
                                if row == 0 && col < firstWeekday || day < 1 || day > daysInMonth {
                                    // 空白
                                    Circle()
                                        .fill(Color.gray.opacity(0.08))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text("")
                                        )
                                        .frame(maxWidth: .infinity)
                                } else {
                                    let emoji = emotionMap[day] ?? ""
                                    Button(action: {
                                        selectedDay = day
                                    }) {
                                        ZStack {
                                            if selectedDay == day {
                                                Circle()
                                                    .fill(Color(red: 60/255, green: 120/255, blue: 255/255))
                                                    .frame(width: 32, height: 32)
                                            } else {
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 32, height: 32)
                                            }
                                            if emoji.isEmpty {
                                                Text("\(day)")
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(selectedDay == day ? .white : Color(red: 30/255, green: 40/255, blue: 90/255))
                                            } else {
                                                Text(emoji)
                                                    .font(.system(size: 24))
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
} 
