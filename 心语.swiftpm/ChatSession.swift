import Foundation

struct ChatSession: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let title: String
    let summary: String
    let startTime: Date
    let endTime: Date
    let messages: [ChatMessage]
    var isArchived: Bool = false
    
    init(id: UUID = UUID(), title: String, summary: String, startTime: Date, endTime: Date, messages: [ChatMessage], isArchived: Bool = false) {
        self.id = id
        self.title = title
        self.summary = summary
        self.startTime = startTime
        self.endTime = endTime
        self.messages = messages
        self.isArchived = isArchived
    }
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d分%d秒", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: startTime)
    }
    
    var lastModified: Date {
        messages.last?.timestamp ?? endTime
    }
    
    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
        lhs.id == rhs.id
    }
} 