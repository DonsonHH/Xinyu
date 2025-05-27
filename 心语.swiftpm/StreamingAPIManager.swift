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
    
    // 千问API配置（和QianwenService一致，直接写死）
    private let apiKey = "sk-6267c004c2ac41d69c098628660f41d0"
    private let baseURL = "https://dashscope.aliyuncs.com/api/v1/apps/5c9a2dd9688448ccbdc5247c289b5096/completion"
    private let messageHistoryActor: MessageHistoryActor
    
    private init() {
        self.messageHistoryActor = MessageHistoryActor(maxHistoryLength: 10)
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
        print("StreamingAPIManager: 准备发起请求，userMessage: \(userMessage)")
        
        // 1. 添加用户消息到历史
        await addToHistory(role: "user", content: userMessage)
        let messages = await getMessageHistory() + [["role": "user", "content": userMessage]]
        
        // 2. 构建请求体（和千问一致）
        let requestBody: [String: Any] = [
            "input": ["messages": messages],
            "parameters": ["incremental_output": true]
        ]
        
        guard let url = URL(string: baseURL) else {
            print("StreamingAPIManager: URL无效")
            throw APIError.invalidURL
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("StreamingAPIManager: JSON编码失败")
            throw APIError.jsonEncodingError
        }
        
        // 3. 构建请求（和千问一致）
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("enable", forHTTPHeaderField: "X-DashScope-SSE")
        request.httpBody = jsonData
        
        // 4. 捕获所有需要的值
        let finalRequest = request
        let finalURL = url
        let finalJsonData = jsonData
        
        print("StreamingAPIManager: 请求URL: \(finalURL)")
        print("StreamingAPIManager: 请求Headers: \(finalRequest.allHTTPHeaderFields ?? [:])")
        print("StreamingAPIManager: 请求体: \(String(data: finalJsonData, encoding: .utf8) ?? "")")
        
        return AsyncThrowingStream { @Sendable continuation in
            let task = Task(priority: .userInitiated) {
                do {
                    let (result, response) = try await URLSession.shared.bytes(for: finalRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("StreamingAPIManager: 无效的HTTP响应")
                        throw APIError.invalidResponse
                    }
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        break
                    case 401:
                        print("StreamingAPIManager: 认证错误")
                        throw APIError.authenticationError
                    case 429:
                        print("StreamingAPIManager: 请求频率限制")
                        throw APIError.rateLimitError
                    case 500:
                        print("StreamingAPIManager: 服务器错误 500")
                        throw APIError.serverError(statusCode: 500)
                    default:
                        print("StreamingAPIManager: 服务器错误 \(httpResponse.statusCode)")
                        throw APIError.serverError(statusCode: httpResponse.statusCode)
                    }
                    
                    var accumulatedContent = ""
                    
                    for try await line in result.lines {
                        guard line.hasPrefix("data:"),
                              let data = line.dropFirst(5).data(using: .utf8) else {
                            continue
                        }
                        
                        // 处理 [DONE] 消息
                        if line.contains("[DONE]") {
                            print("StreamingAPIManager: 收到完成信号")
                            if !accumulatedContent.isEmpty {
                                await self.addToHistory(role: "assistant", content: accumulatedContent)
                            }
                            break
                        }
                        
                        // 修改：千问的响应格式是 output.text
                        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let output = json["output"] as? [String: Any],
                              let text = output["text"] as? String else {
                            print("StreamingAPIManager: JSON解析失败，原始数据: \(String(data: data, encoding: .utf8) ?? "")")
                            continue
                        }
                        
                        print("StreamingAPIManager: 收到内容: \(text)")
                        accumulatedContent += text
                        continuation.yield(text)
                    }
                    
                    continuation.finish()
                } catch {
                    print("StreamingAPIManager: 发生错误: \(error)")
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable status in
                print("StreamingAPIManager: 流终止，状态: \(status)")
                task.cancel()
            }
        }
    }
} 