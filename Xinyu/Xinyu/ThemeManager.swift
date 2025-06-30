import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("followSystem") private var followSystem = true
    
    @Published var globalBackgroundColor: Color = Color.orange.opacity(0.1)
    @Published var currentEmotion: String = "平静"
    
    var textColor: Color {
        if followSystem {
            return .primary
        }
        return isDarkMode ? .white : .black
    }
    
    private init() {}
    
    var colorScheme: ColorScheme? {
        if followSystem {
            return nil
        }
        return isDarkMode ? .dark : .light
    }
    
    func setDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
    }
    
    func setFollowSystem(_ enabled: Bool) {
        followSystem = enabled
    }
    
    func getCurrentTheme() -> (isDark: Bool, followSystem: Bool) {
        return (isDarkMode, followSystem)
    }
    
    // 为情绪设置全局背景颜色
    func setGlobalBackgroundColorForEmotion(_ emotion: String) {
        currentEmotion = emotion
        
        switch emotion {
        case "平静":
            globalBackgroundColor = Color.blue.opacity(0.2)
        case "开心":
            globalBackgroundColor = Color.yellow.opacity(0.3)
        case "悲伤":
            globalBackgroundColor = Color.indigo.opacity(0.2)
        case "生气":
            globalBackgroundColor = Color.red.opacity(0.2)
        case "焦虑":
            globalBackgroundColor = Color.purple.opacity(0.2)
        default:
            globalBackgroundColor = Color.orange.opacity(0.1)
        }
    }
} 