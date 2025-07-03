import Foundation
import Combine
import SwiftUI

@MainActor
final class ChatHistoryManager: ObservableObject {
    static let shared = ChatHistoryManager()
    
    @Published private(set) var chatSessions: [ChatSession] = []
    private let saveKey = "chatSessions"
    
    private init() {}
    
    func loadChatSessions() async {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let sessions = try? JSONDecoder().decode([ChatSession].self, from: data) {
            chatSessions = sessions
        }
    }
    
    private func saveChatSessions() {
        if let data = try? JSONEncoder().encode(chatSessions) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    func addChatSession(_ session: ChatSession) {
        chatSessions.append(session)
        saveChatSessions()
    }
    
    func removeChatSession(at indexSet: IndexSet) {
        chatSessions.remove(atOffsets: indexSet)
        saveChatSessions()
    }
    
    func clearAllSessions() {
        chatSessions.removeAll()
        saveChatSessions()
    }
    
    func generateSummaryAndTitle(for messages: [ChatMessage]) async -> (title: String, summary: String) {
        // 过滤出用户消息并按时间排序
        let userMessages = messages.filter { $0.isUser }.sorted { $0.timestamp < $1.timestamp }
        
        guard !userMessages.isEmpty else {
            return ("新对话", "暂无内容")
        }
        
        // 构建对话文本
        let conversationText = userMessages.map { $0.content }.joined(separator: "\n")
        
        do {
            let prompt = """
            请根据以下对话内容生成一个简短的标题（不超过10个字）和摘要（不超过20个字，且不得分段）。\n标题要简洁明了，反映对话的主要内容。\n摘要要概括对话的要点，且不得分段。\n\n对话内容：\n\(conversationText)\n\n请按以下格式返回：\n标题：xxx\n摘要：xxx
            """
            
            let stream = try await StreamingAPIManager.shared.streamChatRequestOnce(userMessage: prompt)
            var response = ""
            
            for try await chunk in stream {
                response += chunk
            }
            
            // 解析响应
            let lines = response.components(separatedBy: .newlines)
            var title = "新对话"
            var summary = "暂无内容"
            
            for line in lines {
                if line.hasPrefix("标题：") {
                    title = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("摘要：") {
                    summary = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
            }
            
            // 确保标题和摘要不为空且摘要不超过20字且无分段
            if title.isEmpty { title = "新对话" }
            if summary.isEmpty { summary = "暂无内容" }
            summary = summary.replacingOccurrences(of: "\n", with: "")
            if summary.count > 20 {
                summary = String(summary.prefix(20))
            }
            
            return (title, summary)
        } catch {
            // 如果生成失败，使用第一条消息作为标题和摘要
            let firstMessage = userMessages[0].content
            let title = String(firstMessage.prefix(10))
            var summary = String(firstMessage.prefix(20))
            summary = summary.replacingOccurrences(of: "\n", with: "")
            return (title, summary)
        }
    }
    
    func upsertChatSession(_ session: ChatSession) {
        if let idx = chatSessions.firstIndex(where: { $0.id == session.id }) {
            chatSessions[idx] = session
        } else {
            chatSessions.append(session)
        }
        saveChatSessions()
    }
} 