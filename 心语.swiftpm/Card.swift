import SwiftUI

struct Card: Identifiable {
    let id = UUID()
    let color: CardColor
    let type: CardType
    let value: Int
    
    var displayValue: String {
        if type == .number {
            return "\(value)"
        } else {
            return type.symbol
        }
    }
    
    var isPlayable: Bool = false
    
    static func createDeck() -> [Card] {
        var deck: [Card] = []
        
        // 添加数字牌
        for color in [CardColor.red, .blue, .green, .yellow] {
            // 添加 0
            deck.append(Card(color: color, type: .number, value: 0))
            
            // 添加 1-9
            for value in 1...9 {
                deck.append(Card(color: color, type: .number, value: value))
                deck.append(Card(color: color, type: .number, value: value))
            }
            
            // 添加功能牌
            deck.append(Card(color: color, type: .skip, value: -1))
            deck.append(Card(color: color, type: .skip, value: -1))
            deck.append(Card(color: color, type: .reverse, value: -1))
            deck.append(Card(color: color, type: .reverse, value: -1))
            deck.append(Card(color: color, type: .drawTwo, value: -1))
            deck.append(Card(color: color, type: .drawTwo, value: -1))
        }
        
        // 添加万能牌
        for _ in 0..<4 {
            deck.append(Card(color: .wild, type: .wild, value: -1))
            deck.append(Card(color: .wild, type: .wildDrawFour, value: -1))
        }
        
        return deck
    }
}

enum CardColor: CaseIterable {
    case red, blue, green, yellow, wild
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .wild: return .black
        }
    }
}

enum CardType {
    case number
    case skip
    case reverse
    case drawTwo
    case wild
    case wildDrawFour
    
    var symbol: String {
        switch self {
        case .skip: return "⏭"
        case .reverse: return "↩️"
        case .drawTwo: return "+2"
        case .wild: return "🎨"
        case .wildDrawFour: return "+4"
        case .number: return ""
        }
    }
} 