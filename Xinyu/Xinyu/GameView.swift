import SwiftUI

struct GameView: View {
    @StateObject private var gameModel = GameModel()
    @State private var showingRules = false
    @Environment(\.dismiss) private var dismiss
    
    // 动画状态
    @State private var isCardDrawn = false
    @State private var isCardPlayed = false
    @State private var animatedCard: Card?
    @State private var animationOffset: CGSize = .zero
    @State private var animationRotation: Double = 0
    @State private var animationScale: CGFloat = 1.0
    @State private var deckShakeAmount: CGFloat = 0
    @State private var deckGlowAmount: CGFloat = 0
    @State private var isComputerDrawing = false
    @State private var messageScale: CGFloat = 1.0
    @State private var messageOpacity: Double = 1.0
    @State private var messageOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                ZStack {
                    // 木桌纹理背景
                    Color(red: 0.4, green: 0.25, blue: 0.15)  // 深棕色木桌
                        .overlay(
                            Image("wood_texture")  // 木纹纹理
                                .resizable()
                                .opacity(0.3)
                        )
                        .edgesIgnoringSafeArea(.all)
                    
                    // 桌布效果
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.98, green: 0.95, blue: 0.9),  // 浅米色
                                    Color(red: 0.95, green: 0.9, blue: 0.85)   // 稍深的米色
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geometry.size.width * 0.95, height: geometry.size.height * 0.95)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // 游戏内容
                VStack {
                    // 顶部信息
                    HStack {
                        Text("电脑手牌: \(gameModel.computerHand.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                    )
                            )
                        
                        Spacer()
                        
                        Button(action: {
                            showingRules = true
                        }) {
                            Image(systemName: "questionmark.circle")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                gameModel.startNewGame()
                            }
                        }) {
                            Text("新游戏")
                                .font(.headline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                dismiss()
                            }
                        }) {
                            Image(systemName: "house.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                    }
                    .padding()
                    
                    // 电脑手牌（背面朝上）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -15) {
                            ForEach(0..<gameModel.computerHand.count, id: \.self) { index in
                                CardBackView(width: 60, height: 90)
                                    .rotationEffect(.degrees(Double.random(in: -2...2)))
                                    .offset(y: index % 2 == 0 ? -2 : 2)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // 中间区域：弃牌堆和牌堆
                    HStack(spacing: 40) {
                        // 牌堆
                        ZStack {
                            // 底层牌堆效果
                            ForEach(0..<3) { i in
                                CardBackView(width: 80, height: 120)
                                    .offset(x: CGFloat(i) * 1, y: CGFloat(i) * 1)
                                    .opacity(0.8 - Double(i) * 0.2)
                            }
                            
                            // 顶层可点击牌堆
                            Button(action: {
                                drawCardWithAnimation(geometry: geometry)
                            }) {
                                CardBackView(width: 80, height: 120)
                                    .overlay(
                                        Text("抽牌")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(5)
                                            .background(Color.black.opacity(0.7))
                                            .cornerRadius(5)
                                            .offset(y: 50)
                                    )
                                    .shadow(color: gameModel.currentPlayer == .human && gameModel.gameStatus == .playing ? 
                                            Color.white.opacity(deckGlowAmount) : Color.clear, 
                                            radius: 10)
                            }
                            .disabled(gameModel.currentPlayer != .human || gameModel.gameStatus != .playing)
                            .offset(x: deckShakeAmount)
                            .animation(
                                Animation.spring(response: 0.2, dampingFraction: 0.2)
                                    .repeatCount(3, autoreverses: true),
                                value: deckShakeAmount
                            )
                            .onAppear {
                                // 添加牌堆呼吸效果
                                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    deckGlowAmount = 0.6
                                }
                            }
                        }
                        
                        // 弃牌堆
                        ZStack {
                            // 底层弃牌堆效果
                            ForEach(0..<min(3, gameModel.discardPile.count - 1), id: \.self) { i in
                                if gameModel.discardPile.count > i + 1 {
                                    let card = gameModel.discardPile[gameModel.discardPile.count - i - 2]
                                    CardView(
                                        card: card,
                                        width: 80,
                                        height: 120,
                                        isPlayable: false
                                    )
                                    .rotationEffect(.degrees(Double.random(in: -5...5)))
                                    .offset(x: CGFloat.random(in: -3...3), y: CGFloat.random(in: -3...3))
                                    .opacity(1.0 - Double(i) * 0.3)
                                }
                            }
                            
                            // 顶层牌
                            if let topCard = gameModel.discardPile.last {
                                CardView(
                                    card: topCard,
                                    width: 80,
                                    height: 120,
                                    isPlayable: false
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .slide),
                                    removal: .opacity
                                ))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 80, height: 120)
                            }
                        }
                    }
                    
                    // 游戏状态信息
                    Text(gameModel.message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.5))
                                .shadow(color: .white.opacity(0.1), radius: 5)
                        )
                        .padding(.horizontal)
                        .scaleEffect(messageScale)
                        .opacity(messageOpacity)
                        .offset(y: messageOffset)
                        .onChange(of: gameModel.message) { newMessage in
                            // 消息变化时的动画 - 更明显的效果
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                messageScale = 1.2
                                messageOpacity = 0.6
                                messageOffset = -15
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    messageScale = 1.0
                                    messageOpacity = 1.0
                                    messageOffset = 0
                                }
                            }
                        }
                    
                    // 当前玩家指示
                    Text(gameModel.currentPlayer == .human ? "你的回合" : "电脑回合")
                        .font(.headline)
                        .foregroundColor(gameModel.currentPlayer == .human ? .green : .red)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    Capsule()
                                        .stroke(gameModel.currentPlayer == .human ? .green : .red, lineWidth: 2)
                                )
                        )
                        .padding(.bottom)
                    
                    Spacer()
                    
                    // 玩家手牌
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -15) {
                            ForEach(gameModel.playerHand) { card in
                                CardView(
                                    card: card,
                                    width: 70,
                                    height: 105,
                                    isPlayable: card.isPlayable && gameModel.currentPlayer == .human && gameModel.gameStatus == .playing
                                ) {
                                    playCardWithAnimation(card)
                                }
                                .padding(.bottom, card.isPlayable && gameModel.currentPlayer == .human ? 20 : 0)
                                .rotationEffect(.degrees(Double.random(in: -2...2)))
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                
                // 动画中的卡牌
                if let card = animatedCard {
                    CardView(
                        card: card,
                        width: 70,
                        height: 105,
                        isPlayable: false
                    )
                    .offset(animationOffset)
                    .rotationEffect(.degrees(animationRotation))
                    .scaleEffect(animationScale)
                    .opacity(isCardDrawn || isCardPlayed || isComputerDrawing ? 1 : 0)
                    .shadow(color: .white, radius: 5)
                }
                
                // 颜色选择视图
                if gameModel.gameStatus == .colorSelection {
                    ColorSelectionView { color in
                        gameModel.selectColor(color)
                    }
                }
            }
        }
        .sheet(isPresented: $showingRules) {
            RulesView()
        }
        .onChange(of: gameModel.currentPlayer) { newPlayer in
            if newPlayer == .computer {
                // 延迟执行电脑回合，让玩家有时间看到状态变化
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        gameModel.computerTurn()
                    }
                }
            }
        }
    }
    
    // 抽牌动画
    private func drawCardWithAnimation(geometry: GeometryProxy) {
        guard gameModel.currentPlayer == .human && gameModel.gameStatus == .playing else { return }
        
        if let topCard = gameModel.deck.last {
            animatedCard = topCard
            isCardDrawn = true
            
            let deckPosition = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height + geometry.size.height / 2
            )
            
            let targetPosition = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            
            animationOffset = CGSize(
                width: targetPosition.x - deckPosition.x,
                height: targetPosition.y - deckPosition.y
            )
            
            animationRotation = 0
            animationScale = 1.0
            
            // 使用更非线性的动画曲线
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.4)) {
                animationOffset = .zero
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation {
                    gameModel.drawCard()
                    isCardDrawn = false
                    animatedCard = nil
                }
            }
        }
    }
    
    // 出牌动画
    private func playCardWithAnimation(_ card: Card) {
        guard gameModel.currentPlayer == .human && gameModel.gameStatus == .playing else { return }
        
        animatedCard = card
        isCardPlayed = true
        
        let startPosition = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height / 2
        )
        
        let targetPosition = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height + UIScreen.main.bounds.height / 2
        )
        
        animationOffset = CGSize(
            width: targetPosition.x - startPosition.x,
            height: targetPosition.y - startPosition.y
        )
        
        animationRotation = 0
        animationScale = 1.0
        
        // 使用更非线性的动画曲线
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.4)) {
            animationOffset = .zero
            animationScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                gameModel.playCard(card)
                isCardPlayed = false
                animatedCard = nil
            }
        }
    }
} 
