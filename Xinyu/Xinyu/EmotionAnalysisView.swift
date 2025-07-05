import SwiftUI
import AVFoundation
import ARKit
import HealthKit

// 情绪趋势数据结构
struct EmotionTrend {
    let time: String
    let emotion: String
}

// 情绪分析页面
struct EmotionAnalysisView: View {
    @EnvironmentObject var tabSelection: TabSelection
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var selectedTab: Int = 0
    @State private var hrvHistory: [Double] = []
    @State private var currentEmotion: String = "加载中..."
    @State private var emotionScore: Int = 0
    @State private var emotionDescription: String = "正在分析您的情绪状态..."
    @State private var showingARGuide = false
    @State private var showCameraPermissionAlert = false
    @State private var isLoading: Bool = true // 添加加载状态
    @State private var emotionLoading: Bool = true // 情绪数据加载状态
    @State private var hrvValue: Double = 0 // HRV值
    @State private var stressLevel: String = "未知" // 压力水平
    @State private var hrvLoading: Bool = true // HRV加载状态
    @State private var hrvError: String? = nil // HRV获取错误信息
    
    private func fetchTodayMoodAndHRV() {
        emotionLoading = true
        
        // 首先尝试获取今天的情绪记录
        let today = Date()
        let todayEntries = profileManager.getMoodEntries(for: today)
        
        if let latest = todayEntries.first {
            currentEmotion = latest.mood
            emotionScore = MoodUtils.getScoreForEmotion(latest.mood)
            emotionDescription = latest.emotion
        } else {
            // 如果今天没有记录，获取最近的情绪记录
            let allEntries = profileManager.getAllMoodEntries()
            if let latest = allEntries.first {
                currentEmotion = latest.mood
                emotionScore = MoodUtils.getScoreForEmotion(latest.mood)
                emotionDescription = latest.emotion
            } else {
                // 如果完全没有记录，显示暂无数据
                currentEmotion = "暂无记录"
                emotionScore = 0
                emotionDescription = "今日暂无情绪记录，请先记录您的情绪状态。"
            }
        }
        
        emotionLoading = false
        isLoading = false
    }
    
    // 获取真实的 HRV 数据（参考 EmotionFeedbackView 的逻辑）
    private func fetchRealHRVData() {
        let healthStore = HKHealthStore()
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, result, error in
            DispatchQueue.main.async {
                self.hrvLoading = false
                if let result = result, let average = result.averageQuantity() {
                    let hrvValue = average.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    self.hrvValue = hrvValue
                    self.hrvError = nil
                    self.updateStressLevel(hrv: hrvValue)
                } else if let error = error {
                    self.hrvValue = 0
                    self.hrvError = "HRV获取失败：\(error.localizedDescription)"
                    self.stressLevel = "未知"
                } else {
                    self.hrvValue = 0
                    self.hrvError = "未获取到HRV数据"
                    self.stressLevel = "未知"
                }
            }
        }
        healthStore.execute(query)
    }
    
    // 根据 HRV 值更新压力水平
    private func updateStressLevel(hrv: Double) {
        if hrv > 50 {
            stressLevel = "低"
        } else if hrv > 30 {
            stressLevel = "中"
        } else {
            stressLevel = "高"
        }
    }
    
    // 请求 HealthKit 授权
    private func requestHealthKitAuthorization() {
        let healthStore = HKHealthStore()
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        healthStore.requestAuthorization(toShare: [], read: [hrvType]) { success, error in
            if success {
                print("HealthKit authorization granted")
            } else if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    // 根据压力等级返回颜色
    private func hrvColor(for level: String) -> Color {
        switch level {
        case "低": return .green
        case "中": return .yellow
        case "高": return .red
        default: return .gray
        }
    }
    
    // 根据HRV值映射情绪
    private func getEmotionFromHRV(_ hrvValue: Double) -> String {
        if hrvValue <= 0 {
            return "未知"
        } else if hrvValue > 50 {
            // 高HRV，低压力，积极情绪
            return "平静"
        } else if hrvValue > 40 {
            // 中高HRV，轻微压力
            return "开心"
        } else if hrvValue > 30 {
            // 中等HRV，中等压力
            return "疲惫"
        } else if hrvValue > 20 {
            // 低HRV，高压力
            return "焦虑"
        } else {
            // 很低HRV，很高压力
            return "生气"
        }
    }
    
    // 基于真实HRV数据的压力水平分析
    private func getStressLevelAnalysis() -> String {
        if hrvValue > 0 {
            switch stressLevel {
            case "低":
                return "HRV数据显示压力水平较低，身心状态良好"
            case "中":
                return "HRV数据显示压力水平适中，建议适当放松"
            case "高":
                return "HRV数据显示压力水平较高，建议重视放松调节"
            default:
                return "HRV数据无法准确评估，建议多关注身心状态"
            }
        } else {
            return "暂无HRV数据，无法评估当前压力水平"
        }
    }
    
    // 基于用户情绪记录的分析
    private func getEmotionAnalysis() -> String {
        let today = Date()
        let todayEntries = profileManager.getMoodEntries(for: today)
        let recentEntries = profileManager.getAllMoodEntries().prefix(7) // 最近7条记录
        
        if todayEntries.isEmpty {
            if recentEntries.isEmpty {
                return "暂无情绪记录，建议开始记录您的情绪状态"
            } else {
                return "今日暂无情绪记录，可参考历史情绪趋势"
            }
        } else if todayEntries.count == 1 {
            return "今日有1条情绪记录，建议多次记录以了解情绪变化"
        } else {
            let moodCounts = Dictionary(grouping: todayEntries) { $0.mood }
            let dominantMood = moodCounts.max { $0.value.count < $1.value.count }?.key ?? "未知"
            return "今日有\(todayEntries.count)条情绪记录，主要情绪为\(dominantMood)"
        }
    }
    
    // 基于数据给出的建议
    private func getRecommendation() -> String {
        let hasHRV = hrvValue > 0
        let hasEmotionRecords = !profileManager.getMoodEntries(for: Date()).isEmpty
        
        if hasHRV && stressLevel == "高" {
            return "建议进行深呼吸、冥想或轻度运动来降低压力"
        } else if hasHRV && stressLevel == "中" {
            return "保持当前状态，可适当进行放松活动"
        } else if hasHRV && stressLevel == "低" {
            return "状态良好，继续保持健康的生活方式"
        } else if hasEmotionRecords {
            let currentEmotionLower = currentEmotion.lowercased()
            if ["焦虑", "生气", "悲伤"].contains(currentEmotion) {
                return "建议通过放松室的冥想功能来调节情绪"
            } else {
                return "情绪状态不错，继续保持积极心态"
            }
        } else {
            return "建议开始记录情绪并关注心率变异性数据"
        }
    }
    
    // 获取今日情绪趋势
    private func getTodayEmotionTrend() -> [EmotionTrend] {
        let today = Date()
        let todayEntries = profileManager.getMoodEntries(for: today).sorted { $0.date < $1.date }
        
        guard !todayEntries.isEmpty else {
            return []
        }
        
        var trends: [EmotionTrend] = []
        let calendar = Calendar.current
        
        for entry in todayEntries {
            let hour = calendar.component(.hour, from: entry.date)
            let timeText: String
            
            if hour < 12 {
                timeText = "早晨"
            } else if hour < 18 {
                timeText = "下午"
            } else {
                timeText = "晚上"
            }
            
            // 避免重复相同时间段
            if !trends.contains(where: { $0.time == timeText }) {
                trends.append(EmotionTrend(time: timeText, emotion: entry.mood))
            }
        }
        
        // 如果只有一条记录，添加"现在"
        if trends.count == 1 {
            trends.append(EmotionTrend(time: "现在", emotion: currentEmotion))
        }
        
        return trends
    }
    
    private func fetchHRVHistory() {
        // 使用真实的 HealthKit HRV 数据
        fetchRealHRVHistory()
    }
    
    // 从 HealthKit 获取真实的 HRV 历史数据
    private func fetchRealHRVHistory() {
        let healthStore = HKHealthStore()
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)! // 获取一周内的数据
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HRV history fetch error: \(error.localizedDescription)")
                    self.hrvHistory = []
                } else if let samples = samples as? [HKQuantitySample] {
                    // 将 HRV 数据转换为历史数组
                    let values = samples.map { sample in
                        sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    }
                    
                    // 如果数据太多，进行采样（最多20个点）
                    if values.count > 20 {
                        let step = values.count / 20
                        self.hrvHistory = stride(from: 0, to: values.count, by: step).map { values[$0] }
                    } else {
                        self.hrvHistory = values
                    }
                } else {
                    // 如果没有数据，设置为空数组
                    self.hrvHistory = []
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 当前情绪与HRV状态合并卡片
                VStack(spacing: 15) {
                    Text("当前情绪分析")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if emotionLoading || hrvLoading {
                        VStack(spacing: 15) {
                            ProgressView("正在分析情绪和HRV...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                .frame(width: 120, height: 120)
                            Text("正在分析您的情绪状态和心率变异性...")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else if let error = hrvError {
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                                    .frame(width: 120, height: 120)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                            }
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Text("无法获取HRV数据，显示记录的情绪状态")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        // 根据HRV值映射情绪
                        let hrvBasedEmotion = getEmotionFromHRV(hrvValue)
                        let displayEmotion = hrvValue > 0 ? hrvBasedEmotion : currentEmotion
                        
                        Text(displayEmotion)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(hrvValue > 0 ? hrvColor(for: stressLevel) : .orange)
                            .padding(.bottom, 5)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                                .frame(width: 120, height: 120)
                            
                            if hrvValue > 0 {
                                Circle()
                                    .trim(from: 0, to: CGFloat(min(hrvValue / 100, 1)))
                                    .stroke(
                                        hrvColor(for: stressLevel),
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 120, height: 120)
                                
                                VStack(spacing: 2) {
                                    Text(String(format: "%.1f", hrvValue))
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(hrvColor(for: stressLevel))
                                    Text("ms")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Circle()
                                    .trim(from: 0, to: CGFloat(emotionScore) / 100)
                                    .stroke(
                                        Color.orange,
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("\(emotionScore)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.bottom, 5)
                        
                        VStack(spacing: 8) {
                            if hrvValue > 0 {
                                Text("基于HRV数据的情绪分析")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            } else {
                                Text(emotionDescription)
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // 数据来源标注
                            Text("数据来源：Apple Health（健康）")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // HRV历史图表
                VStack(spacing: 15) {
                    Text("HRV 趋势")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    if hrvHistory.isEmpty {
                        VStack {
                            Text("暂无HRV历史数据")
                                .foregroundColor(.gray)
                                .padding()
                        }
                        .frame(height: 200)
                    } else {
                        HStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                Text("平均值")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            HStack(spacing: 4) {
                                Text("最高: \(String(format: "%.1f", hrvHistory.max() ?? 0))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            HStack(spacing: 4) {
                                Text("最低: \(String(format: "%.1f", hrvHistory.min() ?? 0))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 5)
                        LineChartView(
                            data: hrvHistory,
                            average: hrvHistory.reduce(0, +) / Double(hrvHistory.count == 0 ? 1 : hrvHistory.count),
                            max: hrvHistory.max() ?? 0,
                            min: hrvHistory.min() ?? 0
                        )
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // 今日总结
                VStack(spacing: 15) {
                    Text("今日总结")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    VStack(alignment: .leading, spacing: 12) {
                        // 情绪分析卡片
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.orange)
                                Text("情绪分析")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("根据您的HRV数据和情绪记录分析：")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                // 基于真实HRV数据的分析
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(hrvValue > 0 ? hrvColor(for: stressLevel) : Color.gray)
                                        .frame(width: 6, height: 6)
                                    Text(getStressLevelAnalysis())
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                // 基于情绪记录的分析
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                    Text(getEmotionAnalysis())
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                // 基于数据给出的建议
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text(getRecommendation())
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
 
                        // 情绪趋势卡片
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.blue)
                                Text("情绪趋势")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("今日情绪变化轨迹：")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            // 基于真实数据的情绪趋势
                            let todayTrend = getTodayEmotionTrend()
                            
                            if todayTrend.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 6, height: 6)
                                        Text("暂无情绪记录，建议开始记录您的情绪状态")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            } else {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 15) {
                                        ForEach(Array(todayTrend.enumerated()), id: \.offset) { index, trend in
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(trend.time)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                                Text(trend.emotion)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(MoodUtils.getMoodColor(trend.emotion))
                                            }
                                            
                                            if index < todayTrend.count - 1 {
                                                Image(systemName: "arrow.right")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    
                                    // 添加趋势分析
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.green.opacity(0.7))
                                            .frame(width: 6, height: 6)
                                        Text("情绪记录已更新，继续保持记录习惯")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // 跳转到放松室tab的卡片
                        Button(action: { tabSelection.selectedTab = 2 }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                        Text("前往放松室")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    Text("呼吸冥想 · 音乐放松 · 情绪舒缓")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 52/255, green: 199/255, blue: 89/255),
                                        Color(red: 32/255, green: 179/255, blue: 69/255)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("情绪分析")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showCameraPermissionAlert) {
            Alert(
                title: Text("需要相机权限"),
                message: Text("请在设置中允许访问相机以使用AR正念投影功能"),
                primaryButton: .default(Text("去设置"), action: openSettings),
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .onAppear {
            // 初始化加载状态
            isLoading = true
            emotionLoading = true
            hrvLoading = true
            hrvError = nil
            
            // 请求 HealthKit 授权并获取真实数据
            requestHealthKitAuthorization()
            
            // 获取真实的情绪和 HRV 数据
            fetchTodayMoodAndHRV()
            fetchRealHRVData()
            fetchHRVHistory()
        }
    }
    
    // 添加正念投影相关方法
    private func startMindfulnessProjection() {
        // 检查相机权限
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // 已授权，启动 AR 正念投影
            showingARGuide = true
        case .notDetermined:
            // 请求权限
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingARGuide = true
                    } else {
                        self.showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // 显示权限提示
            showCameraPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// 折线图视图
struct LineChartView: View {
    let data: [Double]
    let average: Double
    let max: Double
    let min: Double
    
    var body: some View {
        if data.isEmpty {
            Text("暂无数据")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            GeometryReader { geometry in
                ZStack {
                    // 背景网格
                    VStack(spacing: 0) {
                        ForEach(0..<5) { i in
                            Divider()
                                .background(Color.gray.opacity(0.2))
                            Spacer()
                        }
                        Divider()
                            .background(Color.gray.opacity(0.2))
                    }
                    
                    // 渐变背景
                    Path { path in
                        let width = geometry.size.width / CGFloat(data.count - 1)
                        let height = geometry.size.height
                        
                        path.move(to: CGPoint(x: 0, y: height))
                        
                        for index in 0..<data.count {
                            let x = width * CGFloat(index)
                            let y = height * (1 - CGFloat(data[index] / 100))
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        
                        // 闭合路径到底部
                        path.addLine(to: CGPoint(x: geometry.size.width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.1),
                                Color.blue.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // 平均值线
                    Path { path in
                        let y = geometry.size.height * (1 - CGFloat(average / 100))
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    
                    // 折线图
                    Path { path in
                        let width = geometry.size.width / CGFloat(data.count - 1)
                        let height = geometry.size.height
                        
                        path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(data[0] / 100))))
                        
                        for index in 1..<data.count {
                            let x = width * CGFloat(index)
                            let y = height * (1 - CGFloat(data[index] / 100))
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    
                    // 数据点
                    ForEach(0..<data.count, id: \.self) { index in
                        let width = geometry.size.width / CGFloat(data.count - 1)
                        let height = geometry.size.height
                        let x = width * CGFloat(index)
                        let y = height * (1 - CGFloat(data[index] / 100))
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}

// AR冥想导师视图
struct ARMeditationGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isBreathing = false
    @State private var breathingPhase = 0 // 0: 吸气, 1: 保持, 2: 呼气
    @State private var breathingScale: CGFloat = 1.0
    @State private var showingGuide = true
    @State private var timer: Timer? = nil
    
    let breathingTexts = [
        "慢慢吸气，感受空气流入身体，带来新的能量……",
        "保持呼吸，感受身体的平静与安定……",
        "缓缓呼气，释放压力与疲惫，让心灵更加轻盈……"
    ]
    
    var body: some View {
        ZStack {
            // AR相机预览
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
            
            // 冥想导师3D模型和动画
            if showingGuide {
                VStack {
                    Spacer()
                    
                    // 呼吸动画
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .scaleEffect(breathingScale)
                        .animation(
                            Animation.easeInOut(duration: 4)
                                .repeatForever(autoreverses: true),
                            value: breathingScale
                        )
                        .onAppear {
                            breathingScale = 1.5
                            startBreathingCycle()
                        }
                        .onDisappear {
                            timer?.invalidate()
                        }
                    
                    // 呼吸指导文本，字体大小随圆形缩放
                    Text(breathingText)
                        .font(.system(size: 22 * breathingScale, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                        .animation(.easeInOut(duration: 0.3), value: breathingScale)
                }
            }
            
            // 顶部控制栏
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingGuide.toggle()
                    }) {
                        Image(systemName: showingGuide ? "eye.slash.fill" : "eye.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    private var breathingText: String {
        breathingTexts[breathingPhase]
    }
    
    private func startBreathingCycle() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1.0)) {
                    breathingPhase = (breathingPhase + 1) % 3
                    // 让圆和文字同步缩放
                    switch breathingPhase {
                    case 0: // 吸气
                        breathingScale = 1.5
                    case 1: // 保持
                        breathingScale = 1.2
                    case 2: // 呼气
                        breathingScale = 0.9
                    default:
                        breathingScale = 1.0
                    }
                }
            }
        }
    }
}

// AR视图容器
struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

// 预览提供者
struct EmotionAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionAnalysisView()
    }
} 