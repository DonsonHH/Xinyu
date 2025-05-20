import SwiftUI

@main
struct MyApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    // 在应用启动时加载数据
                    Task {
                        await ChatHistoryManager.shared.loadChatSessions()
                    }
                }
        }
    }
}
