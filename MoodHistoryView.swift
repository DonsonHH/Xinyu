import SwiftUI
import Charts

struct MoodHistoryView: View {
    // 示例数据
    let moodHistory: [MoodData] = [
        MoodData(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, mood: "开心", score: 85, description: "今天心情很好"),
        MoodData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, mood: "平静", score: 75, description: "心情平稳"),
        MoodData(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, mood: "疲惫", score: 60, description: "有点累"),
        MoodData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, mood: "兴奋", score: 90, description: "充满活力"),
        MoodData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, mood: "焦虑", score: 45, description: "有些担心"),
        MoodData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, mood: "平静", score: 70, description: "心情稳定"),
        MoodData(date: Date(), mood: "平静", score: 75, description: "保持积极")
    ]
    
    // 日期格式化器
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
    
    // 具体时间格式化器
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
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
            
            VStack(spacing: 20) {
                // 标题
                Text("情绪历史")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                
                // 情绪曲线图
                Chart {
                    ForEach(moodHistory, id: \.date) { mood in
                        LineMark(
                            x: .value("日期", mood.date),
                            y: .value("情绪分数", mood.score)
                        )
                        .foregroundStyle(Color(red: 255/255, green: 159/255, blue: 10/255))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("日期", mood.date),
                            y: .value("情绪分数", mood.score)
                        )
                        .foregroundStyle(Color(red: 255/255, green: 159/255, blue: 10/255))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // 历史记录列表
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(moodHistory, id: \.date) { mood in
                            HStack(alignment: .top) {
                                // 左侧日期和情绪信息
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(dateFormatter.string(from: mood.date))
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.gray)
                                        
                                        Text(timeFormatter.string(from: mood.date))
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                    
                                    Text(mood.mood)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                    
                                    Text(mood.description)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // 右侧分数
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                        .frame(width: 45, height: 45)
                                    
                                    Circle()
                                        .trim(from: 0, to: CGFloat(mood.score) / 100)
                                        .stroke(
                                            Color(red: 255/255, green: 159/255, blue: 10/255),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                        )
                                        .frame(width: 45, height: 45)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text("\(mood.score)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MoodHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MoodHistoryView()
    }
} 