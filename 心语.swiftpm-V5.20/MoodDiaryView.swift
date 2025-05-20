import SwiftUI

struct MoodDiaryView: View {
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var selectedDate = Date()
    @State private var showingNewEntry = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // 获取情绪对应的颜色
    private func getMoodColor(_ mood: String) -> Color {
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
    private func getHRVColor(_ value: Double) -> Color {
        if value >= 50 {
            return Color(red: 52/255, green: 199/255, blue: 89/255) // 绿色
        } else if value >= 30 {
            return Color(red: 255/255, green: 204/255, blue: 0/255) // 黄色
        } else {
            return Color(red: 255/255, green: 59/255, blue: 48/255) // 红色
        }
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
            emotion: getDescriptionForEmotion(mood),
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // 日期选择器
                    DatePicker(
                        "选择日期",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // 当日情绪状态卡片
                    let entries = profileManager.getMoodEntries(for: selectedDate)
                    if entries.isEmpty {
                        // 生成随机情绪记录
                        let randomEntry = generateRandomMoodEntry(for: selectedDate)
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
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    // 情绪标签
                                    Text(randomEntry.mood)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(getMoodColor(randomEntry.mood))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    // HRV值标签
                                    HStack(spacing: 4) {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(getHRVColor(randomEntry.hrvValue))
                                        Text("\(String(format: "%.1f", randomEntry.hrvValue))")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(getHRVColor(randomEntry.hrvValue))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(getHRVColor(randomEntry.hrvValue).opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                Text(randomEntry.emotion)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(.black)
                                
                                // 情绪分数环形进度条
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                        .frame(width: 100, height: 100)
                                    
                                    Circle()
                                        .trim(from: 0, to: CGFloat(getScoreForEmotion(randomEntry.mood)) / 100)
                                        .stroke(
                                            Color(red: 255/255, green: 159/255, blue: 10/255),
                                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                        )
                                        .frame(width: 100, height: 100)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text("\(getScoreForEmotion(randomEntry.mood))")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                }
                                .padding(.top, 10)
                            }
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(10)
                            
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
                            .padding(.top, 10)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    } else {
                        // 显示当日情绪状态
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
                            
                            // 显示最新的情绪记录
                            if let latestEntry = entries.first {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        // 情绪标签
                                        Text(latestEntry.mood)
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(getMoodColor(latestEntry.mood))
                                            .cornerRadius(8)
                                        
                                        Spacer()
                                        
                                        // HRV值标签
                                        HStack(spacing: 4) {
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(getHRVColor(latestEntry.hrvValue))
                                            Text("\(String(format: "%.1f", latestEntry.hrvValue))")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(getHRVColor(latestEntry.hrvValue))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(getHRVColor(latestEntry.hrvValue).opacity(0.1))
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
                                    
                                    // 情绪分数环形进度条
                                    ZStack {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                            .frame(width: 100, height: 100)
                                        
                                        Circle()
                                            .trim(from: 0, to: CGFloat(getScoreForEmotion(latestEntry.mood)) / 100)
                                            .stroke(
                                                Color(red: 255/255, green: 159/255, blue: 10/255),
                                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                            )
                                            .frame(width: 100, height: 100)
                                            .rotationEffect(.degrees(-90))
                                        
                                        Text("\(getScoreForEmotion(latestEntry.mood))")
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
                        
                        // 显示当日所有记录
                        ForEach(entries) { entry in
                            MoodEntryCard(entry: entry, moodColor: getMoodColor(entry.mood), hrvColor: getHRVColor(entry.hrvValue))
                        }
                    }
                    
                    // 历史记录
                    VStack(alignment: .leading, spacing: 15) {
                        Text("历史记录")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(.horizontal)
                        
                        ForEach(profileManager.getAllMoodEntries().prefix(5)) { entry in
                            if !Calendar.current.isDate(entry.date, inSameDayAs: selectedDate) {
                                MoodEntryCard(entry: entry, moodColor: getMoodColor(entry.mood), hrvColor: getHRVColor(entry.hrvValue))
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding()
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

struct MoodEntryCard: View {
    let entry: MoodEntry
    let moodColor: Color
    let hrvColor: Color
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dateFormatter.string(from: entry.date))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 情绪标签
                Text(entry.mood)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(moodColor)
                    .cornerRadius(8)
            }
            
            Text(entry.emotion)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
            
            // HRV值标签
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundColor(hrvColor)
                Text("HRV: \(String(format: "%.1f", entry.hrvValue))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(hrvColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(hrvColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct NewMoodEntryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var profileManager = UserProfileManager.shared
    
    let date: Date
    @State private var mood = ""
    @State private var emotion = ""
    @State private var note = ""
    @State private var hrvValue: Double = 50.0
    
    private let moods = ["开心", "平静", "疲惫", "焦虑", "生气", "悲伤"]
    
    var body: some View {
        NavigationView {
            Form {
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