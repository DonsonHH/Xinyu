import SwiftUI

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