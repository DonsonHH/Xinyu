import SwiftUI

struct MainTabView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor(white: 0.85, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
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
                RelaxRoomView()
                    .tabItem {
                        Image(systemName: "face.smiling")
                        Text("放松室")
                    }
                    .tag(2)
                MoodAnalysisView()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("我的")
                    }
                    .tag(3)
            }
            .accentColor(Color(red: 255/255, green: 159/255, blue: 10/255))
            .background(themeManager.globalBackgroundColor.ignoresSafeArea())

        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 