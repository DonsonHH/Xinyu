import Foundation

@available(iOS 15.0, *)
private actor MessageHistoryActor {
    private var messageHistory: [[String: String]] = []
    private let maxHistoryLength: Int
    
    init(maxHistoryLength: Int) {
        self.maxHistoryLength = maxHistoryLength
    }
    
    func addMessage(role: String, content: String) {
        messageHistory.append(["role": role, "content": content])
        if messageHistory.count > maxHistoryLength {
            messageHistory.removeFirst()
        }
    }
    
    func clearHistory() {
        messageHistory.removeAll()
    }
    
    func getHistory() -> [[String: String]] {
        return messageHistory
    }
}

@available(iOS 15.0, *)
final class StreamingAPIManager: @unchecked Sendable {
    static let shared = StreamingAPIManager()
    
    private let defaultAPIKey = "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"
    private let messageHistoryActor: MessageHistoryActor
    
    private init() {
        self.messageHistoryActor = MessageHistoryActor(maxHistoryLength: 100)
    }
    
    private func getAPISettings() -> (key: String, model: String, temperature: Double) {
        let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? defaultAPIKey
        let apiModel = UserDefaults.standard.string(forKey: "apiModel") ?? "gpt-4o-mini"
        let temperature = UserDefaults.standard.double(forKey: "temperature")
        
        return (apiKey, apiModel, temperature)
    }
    
    private func addToHistory(role: String, content: String) async {
        await messageHistoryActor.addMessage(role: role, content: content)
    }
    
    func clearHistory() async {
        await messageHistoryActor.clearHistory()
    }
    
    private func getMessageHistory() async -> [[String: String]] {
        await messageHistoryActor.getHistory()
    }
    
    func streamChatRequest(userMessage: String) async throws -> AsyncThrowingStream<String, Error> {
        let settings = getAPISettings()
        
        guard !settings.key.isEmpty else {
            throw APIError.noAPIKey
        }
        
        let apiDomain = UserDefaults.standard.string(forKey: "apiDomain") ?? "https://api.openai.com"
        let apiPath = UserDefaults.standard.string(forKey: "apiPath") ?? "/v1/chat/completions"
        
        guard let url = URL(string: apiDomain + apiPath) else {
            throw APIError.invalidURL
        }
        
        // 添加用户消息到历史记录
        await addToHistory(role: "user", content: userMessage)
        
        // 准备请求体
        var messages: [[String: String]] = [
            ["role": "system", "content": "你是一个友好的AI助手，用中文回答用户的问题。请保持回答简洁明了，如果问题涉及敏感内容，请礼貌地拒绝回答。"]
        ]
        messages.append(contentsOf: await getMessageHistory())
        
        let requestBody: [String: Any] = [
            "model": settings.model,
            "messages": messages,
            "temperature": settings.temperature,
            "stream": true,
            "presence_penalty": 0.6,
            "frequency_penalty": 0.3
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.jsonEncodingError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(settings.key)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (result, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.authenticationError
        case 429:
            throw APIError.rateLimitError
        case 500:
            throw APIError.serverError(statusCode: 500)
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    var accumulatedContent = ""
                    
                    for try await line in result.lines {
                        guard line.hasPrefix("data: "),
                              let data = line.dropFirst(6).data(using: .utf8) else {
                            continue
                        }
                        
                        // 处理 [DONE] 消息
                        if line.contains("[DONE]") {
                            // 将完整的回复添加到历史记录
                            if !accumulatedContent.isEmpty {
                                await self.addToHistory(role: "assistant", content: accumulatedContent)
                            }
                            break
                        }
                        
                        // 解析JSON数据
                        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let firstChoice = choices.first,
                              let delta = firstChoice["delta"] as? [String: Any],
                              let content = delta["content"] as? String else {
                            continue
                        }
                        
                        accumulatedContent += content
                        continuation.yield(content)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
                
                continuation.onTermination = { @Sendable status in
                    print("Stream terminated with status: \(status)")
                }
            }
        }
    }
} 