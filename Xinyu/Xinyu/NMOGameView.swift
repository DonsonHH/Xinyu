import SwiftUI
import Combine

struct NMOGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showGame = false
    @State private var showRules = false
    @State private var showRelax = false
    @State private var animateTitle = false
    @State private var animateCards = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                if !showGame && !showRules {
                    mainContentView
                        .toolbar(.hidden, for: .tabBar)
                } else {
                    mainContentView
                }
            }
            .fullScreenCover(isPresented: $showGame) {
                GameView() // 不隐藏TabBar
            }
            .sheet(isPresented: $showRules) {
                RulesView()
            }
        }
    }

    // 背景部分单独函数
    private var backgroundView: some View {
        let backgroundColor1 = Color(red: 1.0, green: 0.8, blue: 0.4)
        let backgroundColor2 = Color(red: 1.0, green: 0.7, blue: 0.3)
        let backgroundColor3 = Color(red: 0.95, green: 0.65, blue: 0.25)
        let backgroundColors: [Color] = [backgroundColor1, backgroundColor2, backgroundColor3]
        let backgroundGradient = Gradient(colors: backgroundColors)
        let backgroundLinearGradient = LinearGradient(gradient: backgroundGradient, startPoint: .top, endPoint: .bottom)
        let decoCircle1 = Circle()
            .fill(Color(red: 255/255, green: 220/255, blue: 180/255).opacity(0.18))
            .frame(width: 180, height: 180)
            .offset(x: -70, y: -90)
        let decoCircle2 = Circle()
            .fill(Color(red: 180/255, green: 220/255, blue: 255/255).opacity(0.13))
            .frame(width: 120, height: 120)
            .offset(x: 110, y: 80)
        let decoRect = RoundedRectangle(cornerRadius: 40)
            .fill(Color.white.opacity(0.08))
            .frame(width: 180, height: 80)
            .rotationEffect(.degrees(-12))
            .offset(x: 60, y: -60)
        return ZStack {
            backgroundLinearGradient
                .edgesIgnoringSafeArea(.all)
            decoCircle1
            decoCircle2
            decoRect
        }
    }

    // 主内容部分单独函数
    private var mainContentView: some View {
        let titleText = Text("NMO")
            .font(.system(size: 80, weight: .bold))
            .foregroundColor(.white)
            .shadow(color: .red, radius: 5, x: 0, y: 0)
            .scaleEffect(animateTitle ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.3)
                    .repeatForever(autoreverses: true),
                value: animateTitle
            )
            .onAppear {
                animateTitle = true
            }
        let cardRow = HStack(spacing: -30) {
            ForEach(0..<4) { index in
                CardView(
                    card: Card(
                        color: [.red, .blue, .green, .yellow][index],
                        type: .number,
                        value: index + 1
                    ),
                    width: 80,
                    height: 120,
                    isPlayable: true
                )
                .rotationEffect(.degrees(Double(index * 5 - 7)))
                .offset(y: animateCards ? -20 : 0)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                    value: animateCards
                )
            }
        }
        .onAppear {
            animateCards = true
        }
        let startButton = Button(action: {
            showGame = true
        }) {
            Text("开始游戏")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 15)
                .padding(.horizontal, 50)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.red)
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
                )
        }
        .buttonStyle(PlainButtonStyle())
        let rulesButton = Button(action: {
            showRules = true
        }) {
            Text("游戏规则")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 30)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 20)
        let copyrightText = Text("© 2025 心语 游戏")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
            .padding(.bottom, 20)
        let spacer1 = Spacer()
        let spacer2 = Spacer()
        let spacer3 = Spacer()
        return VStack(spacing: 30) {
            titleText
            spacer1
            cardRow
            spacer2
            startButton
            rulesButton
            spacer3
            copyrightText
        }
        .padding()
        .padding(.top, 100)
    }
} 