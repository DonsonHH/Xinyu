import Foundation

struct ChatMessage: Identifiable, Codable, Sendable {
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
} 