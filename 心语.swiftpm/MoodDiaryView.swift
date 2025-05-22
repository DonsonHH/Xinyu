import SwiftUI
import Charts

// 情绪工具类
struct MoodUtils {
    // 获取情绪对应的颜色
    static func getMoodColor(_ mood: String) -> Color {
        switch mood {
        case "开心":
            return Color(red: 255/255, green: 204/255, blue: 0/255) // 黄色
        case "平静":
            return Color(red: 90/255, green: 200/255, blue: 250/255) // 蓝色
        case "疲惫":
            return Color(red: 142/255, green: 142/255, blue: 147/255) // 灰色
        case "焦虑":
            return Color(red: 255/255, green: 149/255, blue: 0/255) // 橙色
        case "生气":
            return Color(red: 255/255, green: 59/255, blue: 48/255) // 红色
        case "悲伤":
            return Color(red: 175/255, green: 82/255, blue: 222/255) // 紫色
        default:
            return Color(red: 255/255, green: 159/255, blue: 10/255) // 默认橙色
        }
    }
    
    // 获取HRV值对应的颜色
    static func getHRVColor(_ value: Double) -> Color {
        if value >= 50 {
            return Color(red: 255/255, green: 59/255, blue: 48/255) // 红色
        } else if value >= 30 {
            return Color(red: 255/255, green: 204/255, blue: 0/255) // 黄色
        } else {
            return Color(red: 52/255, green: 199/255, blue: 89/255) // 绿色
        }
    }
    
    // 根据情绪返回相应的分数
    static func getScoreForEmotion(_ emotion: String) -> Int {
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
    static func getDescriptionForEmotion(_ emotion: String) -> String {
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
    
    // 计算单次记录的综合值
    static func calculateComprehensiveValue(mood: String, hrvValue: Double) -> Double {
        let moodScore = Double(getScoreForEmotion(mood))
        // 心情分数权重0.6，HRV权重0.4（HRV值越高压力越大，所以用100减去HRV值）
        return (moodScore * 0.6 + (100 - hrvValue) * 0.4)
    }
    
    // 获取综合值对应的状态描述
    static func getComprehensiveStatus(_ value: Double) -> String {
        switch value {
        case 80...100:
            return "今天的心情非常愉悦，状态极佳"
        case 60..<80:
            return "今天的心情不错，状态良好"
        case 40..<60:
            return "今天的心情一般，状态平稳"
        case 20..<40:
            return "今天的心情有些低落，需要调节"
        default:
            return "今天的心情较差，建议及时调整"
        }
    }
}

struct MoodDiaryView: View {
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var selectedDate = Date()
    @State private var showingNewEntry = false
    @State private var selectedTimeView: TimeView = .day
    
    enum TimeView {
        case day, week, month, year
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // 生成随机情绪
    private func generateRandomMood() -> String {
        let moods = ["开心", "平静", "疲惫", "焦虑", "生气", "悲伤"]
        return moods.randomElement() ?? "平静"
    }
    
    // 生成随机HRV值
    private func generateRandomHRV() -> Double {
        return Double.random(in: 20...80)
    }
    
    // 生成随机情绪记录
    private func generateRandomMoodEntry(for date: Date) -> MoodEntry {
        let mood = generateRandomMood()
        let hrvValue = generateRandomHRV()
        return MoodEntry(
            date: date,
            mood: mood,
            emotion: MoodUtils.getDescriptionForEmotion(mood),
            hrvValue: hrvValue,
            note: ""
        )
    }
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1),
                    Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 时间视图选择器
                Picker("时间视图", selection: $selectedTimeView) {
                    Text("日").tag(TimeView.day)
                    Text("周").tag(TimeView.week)
                    Text("月").tag(TimeView.month)
                    Text("年").tag(TimeView.year)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 根据选择的时间视图显示不同的内容
                switch selectedTimeView {
                case .day:
                    DayView(selectedDate: $selectedDate, showingNewEntry: $showingNewEntry)
                case .week:
                    WeekView(selectedDate: $selectedDate)
                case .month:
                    MonthView(selectedDate: $selectedDate)
                case .year:
                    YearView(selectedDate: $selectedDate)
                }
            }
        }
        .navigationTitle("心情手帐")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewEntry = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            NewMoodEntryView(date: selectedDate)
        }
    }
}

// 日视图
struct DayView: View {
    @Binding var selectedDate: Date
    @Binding var showingNewEntry: Bool
    @ObservedObject private var profileManager = UserProfileManager.shared
    
    private var entries: [MoodEntry] {
        profileManager.getMoodEntries(for: selectedDate).sorted { $0.date > $1.date }
    }
    
    private var dailyAverage: Double {
        if entries.isEmpty { return 0.0 }
        let total = entries.map { MoodUtils.calculateComprehensiveValue(mood: $0.mood, hrvValue: $0.hrvValue) }.reduce(0, +)
        return total / Double(entries.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if entries.isEmpty {
                    EmptyDayView(showingNewEntry: $showingNewEntry)
                } else {
                    // 今日情绪概况
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今日情绪概况")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        
                        Text(MoodUtils.getComprehensiveStatus(dailyAverage))
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.black)
                        
                        Text("综合值: \(String(format: "%.1f", dailyAverage))")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // 显示当天的所有记录
                    ForEach(entries) { entry in
                        VStack(spacing: 15) {
                            HStack {
                                Text("情绪状态")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                
                                Spacer()
                                
                                Text(formatTime(entry.date))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(entry.mood)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(MoodUtils.getMoodColor(entry.mood))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(MoodUtils.getHRVColor(entry.hrvValue))
                                        Text("\(String(format: "%.1f", entry.hrvValue))")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(MoodUtils.getHRVColor(entry.hrvValue))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(MoodUtils.getHRVColor(entry.hrvValue).opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                Text(entry.emotion)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(.black)
                                
                                if !entry.note.isEmpty {
                                    Text(entry.note)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.gray)
                                        .padding(.top, 5)
                                }
                                
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                        .frame(width: 100, height: 100)
                                    
                                    Circle()
                                        .trim(from: 0, to: CGFloat(MoodUtils.getScoreForEmotion(entry.mood)) / 100)
                                        .stroke(
                                            Color(red: 255/255, green: 159/255, blue: 10/255),
                                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                        )
                                        .frame(width: 100, height: 100)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text("\(MoodUtils.getScoreForEmotion(entry.mood))")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                }
                                .padding(.top, 10)
                            }
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .contextMenu {
                            Button(role: .destructive) {
                                profileManager.deleteMoodEntry(entry)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 周视图
struct WeekView: View {
    @Binding var selectedDate: Date
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var showAllEntries = false
    
    private var weekData: [(date: Date, score: Double, hasData: Bool)] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        let monday = calendar.date(byAdding: .day, value: 1, to: weekStart)!
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: monday)!
            let entries = profileManager.getMoodEntries(for: date)
            let averageScore = entries.isEmpty ? 0.0 : Double(entries.map { MoodUtils.calculateComprehensiveValue(mood: $0.mood, hrvValue: $0.hrvValue) }.reduce(0, +)) / Double(entries.count)
            return (date: date, score: averageScore, hasData: !entries.isEmpty)
        }
    }
    
    private var thirtyDayAverage: [(date: Date, score: Double)] {
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        
        return (0..<7).map { dayOffset in
            let weekday = dayOffset + 1 // 1-7 代表周一到周日
            let dates = (0..<30).compactMap { day -> Date? in
                let date = calendar.date(byAdding: .day, value: day, to: thirtyDaysAgo)!
                let components = calendar.dateComponents([.weekday], from: date)
                return components.weekday == weekday ? date : nil
            }
            
            let scores = dates.compactMap { date -> Double? in
                let entries = profileManager.getMoodEntries(for: date)
                if entries.isEmpty { return nil }
                return Double(entries.map { MoodUtils.calculateComprehensiveValue(mood: $0.mood, hrvValue: $0.hrvValue) }.reduce(0, +)) / Double(entries.count)
            }
            
            let average = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
            let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let date = calendar.date(byAdding: .day, value: dayOffset, to: monday)!
            return (date: date, score: average)
        }
    }
    
    private var weekAverage: Double {
        let scores = weekData.map { $0.score }
        return scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        let start = weekData.first?.date ?? selectedDate
        let end = weekData.last?.date ?? selectedDate
        return "\(formatter.string(from: start))-\(formatter.string(from: end))"
    }
    
    private var recentEntries: [MoodEntry] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        let monday = calendar.date(byAdding: .day, value: 1, to: weekStart)!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: monday)!
        
        return profileManager.moodEntries
            .filter { $0.date >= monday && $0.date < weekEnd }
            .sorted { $0.date > $1.date }
            .prefix(showAllEntries ? .max : 5)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 周情绪趋势图
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                        
                        Text(weekRange)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                        
                        Spacer()
                        
                        Text("周度情绪趋势")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    }
                    
                    Chart {
                        // 30天平均值折线
                        ForEach(thirtyDayAverage, id: \.date) { data in
                            LineMark(
                                x: .value("日期", data.date),
                                y: .value("平均值", data.score)
                            )
                            .foregroundStyle(Color.gray.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                        
                        // 本周数据柱状图
                        ForEach(weekData, id: \.date) { data in
                            BarMark(
                                x: .value("日期", data.date),
                                y: .value("情绪分数", data.score)
                            )
                            .foregroundStyle(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(formatWeekDate(date))
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 周情绪概况
                VStack(alignment: .leading, spacing: 12) {
                    Text("本周情绪概况")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    
                    Text(MoodUtils.getComprehensiveStatus(weekAverage))
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.black)
                    
                    Text("综合值: \(String(format: "%.1f", weekAverage))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 周记录列表
                ForEach(recentEntries) { entry in
                    MoodEntryCard(
                        entry: entry,
                        moodColor: MoodUtils.getMoodColor(entry.mood),
                        hrvColor: MoodUtils.getHRVColor(entry.hrvValue)
                    ) {
                        profileManager.deleteMoodEntry(entry)
                    }
                }
                
                if !recentEntries.isEmpty {
                    Button(action: {
                        withAnimation {
                            showAllEntries.toggle()
                        }
                    }) {
                        Text(showAllEntries ? "收起" : "查看更多")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatWeekDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// 月视图
struct MonthView: View {
    @Binding var selectedDate: Date
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var showAllEntries = false
    
    private var monthData: [(date: Date, score: Double)] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
        
        return (0..<daysInMonth).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!
            let entries = profileManager.getMoodEntries(for: date)
            let averageScore = entries.isEmpty ? 0.0 : Double(entries.map { MoodUtils.calculateComprehensiveValue(mood: $0.mood, hrvValue: $0.hrvValue) }.reduce(0, +)) / Double(entries.count)
            return (date: date, score: averageScore)
        }
    }
    
    private var monthRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }
    
    private var recentEntries: [MoodEntry] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        return profileManager.moodEntries
            .filter { $0.date >= monthStart && $0.date < monthEnd }
            .sorted { $0.date > $1.date }
            .prefix(showAllEntries ? .max : 5)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 月情绪趋势图
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                        
                        Text(monthRange)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                        
                        Spacer()
                        
                        Text("月度情绪趋势")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    }
                    
                    Chart {
                        ForEach(monthData, id: \.date) { data in
                            LineMark(
                                x: .value("日期", data.date),
                                y: .value("情绪分数", data.score)
                            )
                            .foregroundStyle(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            
                            PointMark(
                                x: .value("日期", data.date),
                                y: .value("情绪分数", data.score)
                            )
                            .foregroundStyle(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .symbolSize(8)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(formatMonthDate(date))
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 月记录列表
                ForEach(recentEntries) { entry in
                    MoodEntryCard(
                        entry: entry,
                        moodColor: MoodUtils.getMoodColor(entry.mood),
                        hrvColor: MoodUtils.getHRVColor(entry.hrvValue)
                    ) {
                        profileManager.deleteMoodEntry(entry)
                    }
                }
                
                if !recentEntries.isEmpty {
                    Button(action: {
                        withAnimation {
                            showAllEntries.toggle()
                        }
                    }) {
                        Text(showAllEntries ? "收起" : "查看更多")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatMonthDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// 年视图
struct YearView: View {
    @Binding var selectedDate: Date
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var showAllEntries = false
    
    private var yearData: [(date: Date, score: Double)] {
        let calendar = Calendar.current
        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: selectedDate))!
        
        return (0..<12).map { monthOffset in
            let monthStart = calendar.date(byAdding: .month, value: monthOffset, to: yearStart)!
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
            
            let monthScores = (0..<daysInMonth).compactMap { dayOffset -> Double? in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!
                let entries = profileManager.getMoodEntries(for: date)
                if entries.isEmpty { return nil }
                
                let dailyAverage = entries.map { MoodUtils.calculateComprehensiveValue(mood: $0.mood, hrvValue: $0.hrvValue) }.reduce(0, +) / Double(entries.count)
                return dailyAverage
            }
            
            let monthAverage = monthScores.isEmpty ? 0.0 : monthScores.reduce(0, +) / Double(monthScores.count)
            return (date: monthStart, score: monthAverage)
        }
    }
    
    private var yearRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年"
        return formatter.string(from: selectedDate)
    }
    
    private var yearAverage: Double {
        let scores = yearData.map { $0.score }
        return scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private var recentEntries: [MoodEntry] {
        let calendar = Calendar.current
        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: selectedDate))!
        let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)!
        
        return profileManager.moodEntries
            .filter { $0.date >= yearStart && $0.date < yearEnd }
            .sorted { $0.date > $1.date }
            .prefix(showAllEntries ? .max : 5)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 年情绪趋势图
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                        
                        Text(yearRange)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                        
                        Spacer()
                        
                        Text("年度情绪趋势")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    }
                    
                    Chart {
                        ForEach(yearData, id: \.date) { data in
                            LineMark(
                                x: .value("月份", data.date),
                                y: .value("情绪分数", data.score)
                            )
                            .foregroundStyle(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            
                            if data.score > 0 {
                                PointMark(
                                    x: .value("月份", data.date),
                                    y: .value("情绪分数", data.score)
                                )
                                .foregroundStyle(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .symbolSize(8)
                            }
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(formatYearDate(date))
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 年情绪概况
                VStack(alignment: .leading, spacing: 12) {
                    Text("年度情绪概况")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    
                    Text(MoodUtils.getComprehensiveStatus(yearAverage))
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.black)
                    
                    Text("综合值: \(String(format: "%.1f", yearAverage))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 年记录列表
                ForEach(recentEntries) { entry in
                    MoodEntryCard(
                        entry: entry,
                        moodColor: MoodUtils.getMoodColor(entry.mood),
                        hrvColor: MoodUtils.getHRVColor(entry.hrvValue)
                    ) {
                        profileManager.deleteMoodEntry(entry)
                    }
                }
                
                if !recentEntries.isEmpty {
                    Button(action: {
                        withAnimation {
                            showAllEntries.toggle()
                        }
                    }) {
                        Text(showAllEntries ? "收起" : "查看更多")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatYearDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }
}

// 空日视图
struct EmptyDayView: View {
    @Binding var showingNewEntry: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Text("今日暂无情绪记录")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            Button(action: {
                showingNewEntry = true
            }) {
                Text("添加今日心情")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color(red: 255/255, green: 159/255, blue: 10/255))
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 日情绪卡片
struct DayMoodCard: View {
    let entries: [MoodEntry]
    @Binding var showingNewEntry: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("今日情绪状态")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                
                Spacer()
                
                Button(action: {
                    showingNewEntry = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        .font(.system(size: 24))
                }
            }
            
            if let latestEntry = entries.first {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(latestEntry.mood)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(MoodUtils.getMoodColor(latestEntry.mood))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(MoodUtils.getHRVColor(latestEntry.hrvValue))
                            Text("\(String(format: "%.1f", latestEntry.hrvValue))")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(MoodUtils.getHRVColor(latestEntry.hrvValue))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(MoodUtils.getHRVColor(latestEntry.hrvValue).opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Text(latestEntry.emotion)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.black)
                    
                    if !latestEntry.note.isEmpty {
                        Text(latestEntry.note)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    }
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(MoodUtils.getScoreForEmotion(latestEntry.mood)) / 100)
                            .stroke(
                                Color(red: 255/255, green: 159/255, blue: 10/255),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(MoodUtils.getScoreForEmotion(latestEntry.mood))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MoodEntryCard: View {
    let entry: MoodEntry
    let moodColor: Color
    let hrvColor: Color
    let onDelete: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateFormatter.string(from: entry.date))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Text(entry.mood)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(moodColor)
                    
                    Text(entry.emotion)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.black)
                    
                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(hrvColor)
                    Text("\(String(format: "%.1f", entry.hrvValue))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(hrvColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(hrvColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

struct NewMoodEntryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var profileManager = UserProfileManager.shared
    
    let date: Date
    @State private var selectedDate: Date
    @State private var mood = ""
    @State private var emotion = ""
    @State private var note = ""
    @State private var hrvValue: Double = 50.0
    
    private let moods = ["开心", "平静", "疲惫", "焦虑", "生气", "悲伤"]
    
    init(date: Date) {
        self.date = date
        _selectedDate = State(initialValue: date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("日期")) {
                    DatePicker("选择日期", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                Section(header: Text("心情")) {
                    Picker("选择心情", selection: $mood) {
                        Text("请选择...").tag("")
                        ForEach(moods, id: \.self) { mood in
                            Text(mood).tag(mood)
                        }
                    }
                }
                
                Section(header: Text("情绪描述")) {
                    TextField("描述一下你的情绪...", text: $emotion)
                }
                
                Section(header: Text("HRV值")) {
                    HStack {
                        Text("\(Int(hrvValue))")
                        Slider(value: $hrvValue, in: 0...100, step: 1)
                    }
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
            }
            .navigationTitle("添加心情记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        profileManager.addMoodEntry(
                            date: selectedDate,
                            mood: mood,
                            emotion: emotion,
                            hrvValue: hrvValue,
                            note: note
                        )
                        dismiss()
                    }
                    .disabled(mood.isEmpty || emotion.isEmpty)
                }
            }
        }
    }
}

struct MoodDiaryView_Previews: PreviewProvider {
    static var previews: some View {
        MoodDiaryView()
    }
}

// 在 UserProfileManager 中添加删除方法和获取最近记录的方法
extension UserProfileManager {
    func deleteMoodEntry(_ entry: MoodEntry) {
        moodEntries.removeAll { $0.id == entry.id }
        saveMoodEntries()
    }
    
    func getRecentMoodEntries(days: Int) -> [MoodEntry] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        return moodEntries
            .filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
    }
} 