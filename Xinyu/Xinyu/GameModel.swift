import SwiftUI
import Combine

class GameModel: ObservableObject {
    @Published var playerHand: [Card] = []
    @Published var computerHand: [Card] = []
    @Published var discardPile: [Card] = []
    @Published var currentPlayer: Player = .human
    @Published var gameStatus: GameStatus = .playing
    @Published var message: String = "游戏开始！"
    @Published var deck: [Card] = []
    
    enum Player {
        case human, computer
    }
    
    enum GameStatus {
        case playing, colorSelection, gameOver
    }
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        // 重置游戏状态
        playerHand = []
        computerHand = []
        discardPile = []
        currentPlayer = .human
        gameStatus = .playing
        message = "游戏开始！"
        
        // 创建并洗牌
        deck = Card.createDeck()
        deck.shuffle()
        
        // 发牌
        for _ in 0..<7 {
            if let card = deck.popLast() {
                playerHand.append(card)
            }
            if let card = deck.popLast() {
                computerHand.append(card)
            }
        }
        
        // 放置第一张牌
        while true {
            if let firstCard = deck.popLast() {
                if firstCard.type == .number {
                    discardPile.append(firstCard)
                    break
                }
                deck.insert(firstCard, at: 0)
            }
        }
        
        // 检查玩家是否有可出的牌
        checkPlayableCards()
    }
    
    func drawCard() {
        guard gameStatus == .playing else { return }
        guard currentPlayer == .human else { return }
        
        // 如果牌堆为空，重新洗牌
        if deck.isEmpty {
            reshuffleDeck()
        }
        
        if let drawnCard = deck.popLast() {
            playerHand.append(drawnCard)
            message = "你抽了一张牌"
            
            // 检查抽到的牌是否可以打出
            if let topCard = discardPile.last, canPlayCard(drawnCard, after: topCard) {
                // 可以选择打出这张牌
                checkPlayableCards()
            } else {
                // 不能打出，轮到电脑
                currentPlayer = .computer
                computerTurn()
            }
        } else {
            // 如果没有牌可抽，游戏结束
            gameStatus = .gameOver
            message = "没有牌可抽了！游戏结束！"
        }
    }
    
    private func reshuffleDeck() {
        // 保存弃牌堆最上面的牌
        guard let topCard = discardPile.last else { return }
        discardPile.removeLast()
        
        // 将弃牌堆的牌洗入牌堆
        deck = discardPile
        deck.shuffle()
        
        // 清空弃牌堆，只保留最上面的牌
        discardPile = [topCard]
    }
    
    private func canPlayCard(_ card: Card, after topCard: Card) -> Bool {
        // 通配牌总是可以出
        if card.color == .wild {
            return true
        }
        
        // 颜色相同或者类型/数值相同
        return card.color == topCard.color || 
               (card.type == topCard.type && card.type != .number) || 
               (card.type == .number && topCard.type == .number && card.value == topCard.value)
    }
    
    private func checkPlayableCards() {
        guard let topCard = discardPile.last else { return }
        
        // 更新玩家手牌的可玩状态
        for i in 0..<playerHand.count {
            playerHand[i].isPlayable = canPlayCard(playerHand[i], after: topCard)
        }
    }
    
    func playCard(_ card: Card) {
        // 检查是否可以出这张牌
        if let topCard = discardPile.last, !canPlayCard(card, after: topCard) {
            return
        }
        
        // 从玩家手中移除这张牌
        if let index = playerHand.firstIndex(where: { $0.id == card.id }) {
            playerHand.remove(at: index)
        }
        
        // 将牌放入弃牌堆
        discardPile.append(card)
        
        // 检查游戏是否结束
        if playerHand.isEmpty {
            gameStatus = .gameOver
            message = "恭喜你赢了！"
            return
        }
        
        // 处理特殊牌的效果
        switch card.type {
        case .skip:
            // 跳过电脑的回合
            currentPlayer = .human
            message = "跳过电脑回合！"
            
        case .reverse:
            // 反转顺序
            currentPlayer = .human
            message = "顺序反转！"
            
        case .drawTwo:
            // 电脑抽两张牌
            for _ in 0..<2 {
                if deck.isEmpty {
                    reshuffleDeck()
                }
                if let newCard = deck.popLast() {
                    computerHand.append(newCard)
                }
            }
            currentPlayer = .human
            message = "电脑抽了两张牌！"
            
        case .wild, .wildDrawFour:
            // 需要选择颜色
            gameStatus = .colorSelection
            if card.type == .wildDrawFour {
                // 电脑抽四张牌
                for _ in 0..<4 {
                    if deck.isEmpty {
                        reshuffleDeck()
                    }
                    if let newCard = deck.popLast() {
                        computerHand.append(newCard)
                    }
                }
                message = "选择颜色，电脑抽了四张牌！"
            } else {
                message = "选择颜色！"
            }
            
        default:
            // 普通牌，轮到电脑
            currentPlayer = .computer
            computerTurn()
        }
    }
    
    func selectColor(_ color: CardColor) {
        guard gameStatus == .colorSelection else { return }
        
        // 更新弃牌堆最上面的牌的颜色
        if var topCard = discardPile.last {
            topCard = Card(color: color, type: topCard.type, value: topCard.value)
            discardPile[discardPile.count - 1] = topCard
        }
        
        // 更新游戏状态
        gameStatus = .playing
        currentPlayer = .computer
        computerTurn()
    }
    
    func computerTurn() {
        guard currentPlayer == .computer && gameStatus == .playing else { return }
        
        // 检查电脑是否有可出的牌
        let playableCards = computerHand.filter { card in
            if let topCard = discardPile.last {
                return canPlayCard(card, after: topCard)
            }
            return true
        }
        
        if let cardToPlay = playableCards.randomElement() {
            // 电脑出牌
            if let index = computerHand.firstIndex(where: { $0.id == cardToPlay.id }) {
                let playedCard = computerHand.remove(at: index)
                discardPile.append(playedCard)
                
                // 处理特殊牌效果
                switch playedCard.type {
                case .skip:
                    message = "电脑跳过你的回合！"
                    currentPlayer = .computer
                    computerTurn()
                    
                case .reverse:
                    message = "电脑反转了顺序！"
                    currentPlayer = .computer
                    computerTurn()
                    
                case .drawTwo:
                    // 玩家抽两张牌
                    for _ in 0..<2 {
                        if deck.isEmpty {
                            reshuffleDeck()
                        }
                        if let newCard = deck.popLast() {
                            playerHand.append(newCard)
                        }
                    }
                    message = "你抽了两张牌！"
                    currentPlayer = .human
                    
                case .wild, .wildDrawFour:
                    // 电脑随机选择颜色
                    let colors: [CardColor] = [.red, .blue, .green, .yellow]
                    let selectedColor = colors.randomElement() ?? .red
                    
                    // 更新弃牌堆最上面的牌的颜色
                    if var topCard = discardPile.last {
                        topCard = Card(color: selectedColor, type: topCard.type, value: topCard.value)
                        discardPile[discardPile.count - 1] = topCard
                    }
                    
                    if playedCard.type == .wildDrawFour {
                        // 玩家抽四张牌
                        for _ in 0..<4 {
                            if deck.isEmpty {
                                reshuffleDeck()
                            }
                            if let newCard = deck.popLast() {
                                playerHand.append(newCard)
                            }
                        }
                        message = "电脑选择了\(selectedColor)色，你抽了四张牌！"
                    } else {
                        message = "电脑选择了\(selectedColor)色！"
                    }
                    currentPlayer = .human
                    
                default:
                    message = "电脑出了一张牌"
                    currentPlayer = .human
                }
                
                // 检查游戏是否结束
                if computerHand.isEmpty {
                    gameStatus = .gameOver
                    message = "电脑赢了！"
                }
            }
        } else {
            // 电脑没有可出的牌，需要抽牌
            if deck.isEmpty {
                reshuffleDeck()
            }
            
            if let newCard = deck.popLast() {
                computerHand.append(newCard)
                message = "电脑抽了一张牌"
                
                // 检查抽到的牌是否可以打出
                if let topCard = discardPile.last, canPlayCard(newCard, after: topCard) {
                    // 电脑可以打出这张牌
                    if let index = computerHand.firstIndex(where: { $0.id == newCard.id }) {
                        let playedCard = computerHand.remove(at: index)
                        discardPile.append(playedCard)
                        message = "电脑抽了一张牌并打出"
                        
                        // 处理特殊牌效果
                        switch playedCard.type {
                        case .skip:
                            message = "电脑跳过你的回合！"
                            currentPlayer = .computer
                            computerTurn()
                            
                        case .reverse:
                            message = "电脑反转了顺序！"
                            currentPlayer = .computer
                            computerTurn()
                            
                        case .drawTwo:
                            // 玩家抽两张牌
                            for _ in 0..<2 {
                                if deck.isEmpty {
                                    reshuffleDeck()
                                }
                                if let newCard = deck.popLast() {
                                    playerHand.append(newCard)
                                }
                            }
                            message = "你抽了两张牌！"
                            currentPlayer = .human
                            
                        case .wild, .wildDrawFour:
                            // 电脑随机选择颜色
                            let colors: [CardColor] = [.red, .blue, .green, .yellow]
                            let selectedColor = colors.randomElement() ?? .red
                            
                            // 更新弃牌堆最上面的牌的颜色
                            if var topCard = discardPile.last {
                                topCard = Card(color: selectedColor, type: topCard.type, value: topCard.value)
                                discardPile[discardPile.count - 1] = topCard
                            }
                            
                            if playedCard.type == .wildDrawFour {
                                // 玩家抽四张牌
                                for _ in 0..<4 {
                                    if deck.isEmpty {
                                        reshuffleDeck()
                                    }
                                    if let newCard = deck.popLast() {
                                        playerHand.append(newCard)
                                    }
                                }
                                message = "电脑选择了\(selectedColor)色，你抽了四张牌！"
                            } else {
                                message = "电脑选择了\(selectedColor)色！"
                            }
                            currentPlayer = .human
                            
                        default:
                            message = "电脑出了一张牌"
                            currentPlayer = .human
                        }
                        
                        // 检查游戏是否结束
                        if computerHand.isEmpty {
                            gameStatus = .gameOver
                            message = "电脑赢了！"
                        }
                    }
                } else {
                    // 不能打出，轮到玩家
                    currentPlayer = .human
                }
            }
        }
        
        // 更新玩家手牌的可玩状态
        checkPlayableCards()
    }
} 