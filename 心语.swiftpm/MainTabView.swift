import SwiftUI

struct MainTabView: View {
    @State private var currentPage = 0
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @StateObject private var profileManager = UserProfileManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            // 主内容区域
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // 主界面
                    ContentView()
                        .frame(width: geometry.size.width)
                        .edgesIgnoringSafeArea(.all)
                    
                    // 情绪分析界面
                    MoodAnalysisView()
                        .frame(width: geometry.size.width)
                        .edgesIgnoringSafeArea(.all)
                }
                .offset(x: -CGFloat(currentPage) * geometry.size.width + offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            offset = gesture.translation.width
                        }
                        .onEnded { gesture in
                            isDragging = false
                            let threshold = geometry.size.width * 0.3
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if gesture.translation.width > threshold && currentPage > 0 {
                                    currentPage -= 1
                                } else if gesture.translation.width < -threshold && currentPage < 1 {
                                    currentPage += 1
                                }
                                offset = 0
                            }
                        }
                )
            }
            
            // 页面指示器
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    ForEach(0..<2) { index in
                        Circle()
                            .fill(currentPage == index ? 
                                Color(red: 255/255, green: 159/255, blue: 10/255) : 
                                Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                )
                .padding(.bottom, 8)
            }
            
            // 强制引导界面
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .background(themeManager.globalBackgroundColor)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            showOnboarding = !profileManager.isOnboardingCompleted()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 