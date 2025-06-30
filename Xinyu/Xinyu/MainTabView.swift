import SwiftUI
import Combine

struct MainTabView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var tabSelection = TabSelection()
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        if #available(iOS 15.0, *) {
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
        // 主题色融合，提升 liquid glass 质感
        let uiColor = UIColor(themeManager.globalBackgroundColor)
        appearance.backgroundColor = uiColor.withAlphaComponent(0.4)
        appearance.shadowColor = UIColor(white: 0.85, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
            TabView(selection: $tabSelection.selectedTab) {
                ContentView()
                    .tabItem {
                        Image(systemName: "sun.max.fill")
                        Text("今天")
                    }
                    .tag(0)
                VoiceInteractionView()
                    .tabItem {
                        Image(systemName: "waveform")
                        Text("倾听")
                    }
                    .tag(1)
                NavigationView {
                    RelaxRoomView()
                }
                .tabItem {
                    Image(systemName: "face.smiling")
                    Text("放松室")
                }
                .tag(2)
                NavigationView {
                    MoodAnalysisView()
                }
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("心迹")
                }
                .tag(3)
            }
        .accentColor(Color.orange)
            .background(themeManager.globalBackgroundColor.ignoresSafeArea())
        .environmentObject(tabSelection)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

class TabSelection: ObservableObject {
    @Published var selectedTab: Int = 0
} 