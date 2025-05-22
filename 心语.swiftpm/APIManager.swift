import Foundation
import SwiftUI

class APIManager {
    // 单例模式
    nonisolated(unsafe) static let shared = APIManager()
    
    // 在这里设置您的默认 API 密钥
    private let defaultAPIKey = "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"
    
    // 消息历史记录
    private var messageHistory: [[String: String]] = []
    private let maxHistoryLength = 100
    
    private init() {}
    
    // 从AppStorage读取API设置
    private func getAPISettings() -> (key: String, model: String, temperature: Double, maxTokens: Int) {
        let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? defaultAPIKey
        let apiModel = UserDefaults.standard.string(forKey: "apiModel") ?? "gpt-4o-mini"
        let temperature = UserDefaults.standard.double(forKey: "temperature")
        let maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        
        return (apiKey, apiModel, temperature, maxTokens)
    }
    
    // 添加消息到历史记录
    private func addToHistory(role: String, content: String) {
        messageHistory.append(["role": role, "content": content])
        if messageHistory.count > maxHistoryLength {
            messageHistory.removeFirst()
        }
    }
    
    // 清空历史记录
    func clearHistory() {
        messageHistory.removeAll()
    }
    
    // 发送API请求并返回结果
    func sendChatRequest(userMessage: String) async throws -> String {
        let settings = getAPISettings()
        
        // 验证API设置
        guard !settings.key.isEmpty else {
            throw APIError.noAPIKey
        }
        
        // 使用用户配置的API域名和路径
        let apiDomain = UserDefaults.standard.string(forKey: "apiDomain") ?? "https://api.openai.com"
        let apiPath = UserDefaults.standard.string(forKey: "apiPath") ?? "/v1/chat/completions"
        
        guard let url = URL(string: apiDomain + apiPath) else {
            throw APIError.invalidURL
        }
        
        // 添加用户消息到历史记录
        addToHistory(role: "user", content: userMessage)
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(settings.key)", forHTTPHeaderField: "Authorization")
        
        // 准备请求体
        var messages: [[String: String]] = [
            ["role": "system", "content": "你是一个友好的AI助手，用中文回答用户的问题。请保持回答简洁明了，如果问题涉及敏感内容，请礼貌地拒绝回答。"]
        ]
        messages.append(contentsOf: messageHistory)
        
        let requestBody: [String: Any] = [
            "model": settings.model,
            "messages": messages,
            "temperature": settings.temperature,
            "max_tokens": settings.maxTokens,
            "presence_penalty": 0.6,
            "frequency_penalty": 0.3,
            "stream": true,  // 明确指定不使用流式响应
            "top_p": 1.0,     // 添加top_p参数
            "n": 1,           // 明确指定只返回一个回复
            "stop": [] as [String]  // 使用空数组代替nil
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.jsonEncodingError
        }
        
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // 增强错误处理
            switch httpResponse.statusCode {
            case 200...299:
                break // 成功状态码，继续处理
            case 401:
                throw APIError.authenticationError
            case 429:
                throw APIError.rateLimitError
            case 500:
                throw APIError.serverError(statusCode: 500)
            default:
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            // 解析响应
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw APIError.jsonDecodingError
            }
            
            // 检查API错误
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw APIError.apiError(message: message)
            }
            
            guard let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw APIError.jsonDecodingError
            }
            
            // 添加AI回复到历史记录
            addToHistory(role: "assistant", content: content)
            
            return content
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// API错误类型
enum APIError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case jsonEncodingError
    case jsonDecodingError
    case invalidResponse
    case authenticationError
    case rateLimitError
    case serverError(statusCode: Int)
    case apiError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "未设置API密钥，请在设置中添加密钥。"
        case .invalidURL:
            return "API URL无效，请检查您的设置。"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .jsonEncodingError:
            return "无法创建请求数据。"
        case .jsonDecodingError:
            return "无法解析API返回的数据。"
        case .invalidResponse:
            return "收到的响应无效。"
        case .authenticationError:
            return "API认证失败，请检查您的API密钥。"
        case .rateLimitError:
            return "API请求频率超限，请稍后再试。"
        case .serverError(let statusCode):
            return "服务器错误，状态码: \(statusCode)"
        case .apiError(let message):
            return "API错误: \(message)"
        }
    }
}
