import Foundation
import SwiftUI
import Combine

enum APIError: Error {
    case invalidURL
    case jsonEncodingError
    case invalidResponse
    case authenticationError
    case rateLimitError
    case serverError(statusCode: Int)
}

@available(iOS 15.0, *)
private actor MessageHistoryActor {
    private var messageHistory: [[String: String]] = []
    private var maxHistoryLength: Int
    
    init(maxHistoryLength: Int) {
        self.maxHistoryLength = maxHistoryLength
    }
    
    func updateMaxHistoryLength(_ newLength: Int) {
        self.maxHistoryLength = newLength
        // 如果当前历史记录超过新的长度限制，删除多余的消息
        while messageHistory.count > maxHistoryLength {
            messageHistory.removeFirst()
        }
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
    
    // 千问API配置
    private let apiKey = "sk-2b0120253a5c4a06bba8a9e4164dea9a"
    private let baseURL = "https://dashscope.aliyuncs.com/api/v1/apps/717d5ce4c24342379459d3c7d4815ae8/completion"
    private let messageHistoryActor: MessageHistoryActor
    
    // 用户配置
    private var maxHistoryLength: Int {
        get { UserDefaults.standard.integer(forKey: "maxHistoryLength") }
        set {
            UserDefaults.standard.set(newValue, forKey: "maxHistoryLength")
            Task {
                await messageHistoryActor.updateMaxHistoryLength(newValue)
            }
        }
    }
    private var temperature: Double {
        get { UserDefaults.standard.double(forKey: "temperature") }
        set { UserDefaults.standard.set(newValue, forKey: "temperature") }
    }
    private var systemPrompt: String {
        get { UserDefaults.standard.string(forKey: "systemPrompt") ?? "你是一个情绪管理助手，帮助用户管理情绪。" }
        set { UserDefaults.standard.set(newValue, forKey: "systemPrompt") }
    }
    private var incrementalOutput: Bool {
        get { UserDefaults.standard.bool(forKey: "incrementalOutput") }
        set { UserDefaults.standard.set(newValue, forKey: "incrementalOutput") }
    }
    private var topP: Double {
        get { UserDefaults.standard.double(forKey: "topP") }
        set { UserDefaults.standard.set(newValue, forKey: "topP") }
    }
    private var topK: Int {
        get { UserDefaults.standard.integer(forKey: "topK") }
        set { UserDefaults.standard.set(newValue, forKey: "topK") }
    }
    private var maxTokens: Int {
        get { UserDefaults.standard.integer(forKey: "maxTokens") }
        set { UserDefaults.standard.set(newValue, forKey: "maxTokens") }
    }
    
    private init() {
        // 从 UserDefaults 获取初始值，如果不存在则使用默认值
        let initialMaxHistoryLength = UserDefaults.standard.integer(forKey: "maxHistoryLength")
        let defaultMaxHistoryLength = initialMaxHistoryLength > 0 ? initialMaxHistoryLength : 10
        
        // 初始化 messageHistoryActor
        self.messageHistoryActor = MessageHistoryActor(maxHistoryLength: defaultMaxHistoryLength)
        
        // 设置默认值（如果尚未设置）
        if initialMaxHistoryLength == 0 {
            UserDefaults.standard.set(10, forKey: "maxHistoryLength")
        }
        if UserDefaults.standard.double(forKey: "temperature") == 0 {
            UserDefaults.standard.set(0.7, forKey: "temperature")
        }
        if UserDefaults.standard.string(forKey: "systemPrompt") == nil {
            UserDefaults.standard.set("你是一个情绪管理助手，帮助用户管理情绪。", forKey: "systemPrompt")
        }
        if !UserDefaults.standard.bool(forKey: "incrementalOutput") {
            UserDefaults.standard.set(true, forKey: "incrementalOutput")
        }
        if UserDefaults.standard.double(forKey: "topP") == 0 {
            UserDefaults.standard.set(0.8, forKey: "topP")
        }
        if UserDefaults.standard.integer(forKey: "topK") == 0 {
            UserDefaults.standard.set(50, forKey: "topK")
        }
        if UserDefaults.standard.integer(forKey: "maxTokens") == 0 {
            UserDefaults.standard.set(2000, forKey: "maxTokens")
        }
    }
    
    private func addToHistory(role: String, content: String) async {
        await messageHistoryActor.addMessage(role: role, content: content)
    }
    
    func clearHistory() async {
        await messageHistoryActor.clearHistory()
    }
    
    private func getMessageHistory() async -> [[String: String]] {
        var messages = await messageHistoryActor.getHistory()
        // 添加系统提示词
        if !messages.contains(where: { $0["role"] == "system" }) {
            messages.insert(["role": "system", "content": systemPrompt], at: 0)
        }
        return messages
    }
    
    // 公共流式请求实现，传入完整 messages 队列
    private func makeStreamChatRequest(messages: [[String: String]]) async throws -> AsyncThrowingStream<String, Error> {
        let requestBody: [String: Any] = [
            "input": ["messages": messages],
            "parameters": [
                "incremental_output": incrementalOutput,
                "temperature": temperature,
                "top_p": topP,
                "top_k": topK,
                "max_tokens": maxTokens
            ]
        ]
        guard let url = URL(string: baseURL) else {
            print("StreamingAPIManager: URL无效")
            throw APIError.invalidURL
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("StreamingAPIManager: JSON编码失败")
            throw APIError.jsonEncodingError
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("enable", forHTTPHeaderField: "X-DashScope-SSE")
        request.httpBody = jsonData
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
                        if line.contains("[DONE]") {
                            print("StreamingAPIManager: 收到完成信号")
                            if !accumulatedContent.isEmpty {
                                await self.addToHistory(role: "assistant", content: accumulatedContent)
                            }
                            break
                        }
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

    // 原有：会加入历史
    func streamChatRequest(userMessage: String) async throws -> AsyncThrowingStream<String, Error> {
        print("StreamingAPIManager: 准备发起请求，userMessage: \(userMessage)")
        await addToHistory(role: "user", content: userMessage)
        let messages = await getMessageHistory()
        return try await makeStreamChatRequest(messages: messages)
    }

    // 新增：不会加入历史
    func streamChatRequestOnce(userMessage: String) async throws -> AsyncThrowingStream<String, Error> {
        print("StreamingAPIManager: [ONCE] 准备发起一次性请求，userMessage: \(userMessage)")
        // 只用系统提示和本次 userMessage，不加历史
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userMessage]
        ]
        return try await makeStreamChatRequest(messages: messages)
    }
    
    // 测试API连接
    func testConnection() async throws -> Bool {
        let testMessage = "测试连接"
        let stream = try await streamChatRequest(userMessage: testMessage)
        
        for try await _ in stream {
            // 只要收到任何响应就认为连接成功
            return true
        }
        
        return false
    }
} 