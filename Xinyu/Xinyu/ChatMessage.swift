import Foundation

struct ChatMessage: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var content: String
    let isUser: Bool
    var isThinking: Bool
    let timestamp: Date
    let role: String
    
    init(id: UUID = UUID(), content: String, isUser: Bool, isThinking: Bool = false, timestamp: Date = Date(), role: String = "") {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.isThinking = isThinking
        self.timestamp = timestamp
        self.role = role
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: timestamp)
    }
} 