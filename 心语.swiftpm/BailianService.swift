/*//import Foundation

// 白炼相关错误类型定义
enum BailianError: Error {
    case invalidURL // URL无效
    case networkError(Error) // 网络错误
    case invalidResponse // 响应无效
    case unauthorized // 未授权
    case unknown // 未知错误
}

// 白炼服务，负责与阿里云白炼API进行网络通信
class BailianService: NSObject, URLSessionDataDelegate {
    static let shared = BailianService() // 单例
    
    // API配置
    private let apiKey = "" // TODO: 填入白炼API密钥
    private let baseURL = "" // TODO: 填入白炼API基础URL
    
    // 历史消息
    private var chatHistory: [(role: String, content: String)] = []
    private let maxHistoryMessages = 10
    
    // 回调类型
    typealias CompletionHandler = (String?, Error?) -> Void
    typealias StreamHandler = (String) -> Void
    typealias ThinkingHandler = (String) -> Void
    typealias LoadingHandler = (Bool) -> Void
    
    private var receivedData: Data = Data()
    private var dataTask: URLSessionDataTask?
    private var onReceive: ((String) -> Void)?
    private var onComplete: ((Error?) -> Void)?
    
    private override init() {}
    
    // 清除历史
    func clearChatHistory() {
        chatHistory.removeAll()
    }
    
    // 添加历史
    private func addMessageToHistory(role: String, content: String) {
        chatHistory.append((role: role, content: content))
        if chatHistory.count > maxHistoryMessages {
            if let index = chatHistory.firstIndex(where: { $0.role != "system" }) {
                chatHistory.remove(at: index)
            }
        }
    }
    
    // 构建messages
    private func buildMessages(prompt: String) -> [[String: String]] {
        var messages: [[String: String]] = chatHistory.map { ["role": $0.role, "content": $0.content] }
        messages.append(["role": "user", "content": prompt])
        return messages
    }
    
    // 流式发送消息
    func sendMessageStream(prompt: String,
                          onReceive: @escaping StreamHandler,
                          onThinking: @escaping ThinkingHandler,
                          onLoading: @escaping LoadingHandler,
                          onComplete: @escaping CompletionHandler) {
        print("BailianService: 准备发起请求，prompt: \(prompt)")
        addMessageToHistory(role: "user", content: prompt)
        let messages = buildMessages(prompt: prompt)
        
        guard let url = URL(string: baseURL) else {
            print("BailianService: URL无效")
            onComplete(nil, NSError(domain: "BailianService", code: 0, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("enable", forHTTPHeaderField: "X-DashScope-SSE")
        
        // TODO: 根据白炼API文档调整请求体格式
        let body: [String: Any] = [
            "input": ["messages": messages],
            "parameters": ["incremental_output": true]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            print("BailianService: 请求URL: \(url)")
            print("BailianService: 请求Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("BailianService: 请求体: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        } catch {
            print("BailianService: 请求体序列化失败: \(error)")
            onComplete(nil, error)
            return
        }
        
        // 状态
        var fullResponse = ""
        onLoading(true)
        
        // 处理流式数据
        let streamDelegate = BailianStreamDelegate(
            onReceive: { content in
                fullResponse += content
                onReceive(content)
            },
            onThinking: onThinking,
            onLoading: onLoading,
            onComplete: { content, error in
                onLoading(false)
                if let content = content, error == nil {
                    self.addMessageToHistory(role: "assistant", content: content)
                }
                onComplete(content, error)
            }
        )
        let session = URLSession(configuration: .default, delegate: streamDelegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        print("BailianService: dataTask已创建，准备resume")
        task.resume()
    }
}

// 流式处理委托
class BailianStreamDelegate: NSObject, URLSessionDataDelegate {
    private let onReceive: (String) -> Void
    private let onThinking: (String) -> Void
    private let onLoading: (Bool) -> Void
    private let onComplete: (String?, Error?) -> Void
    var task: URLSessionDataTask?
    private var buffer = Data()
    private var fullResponse = ""
    
    init(onReceive: @escaping (String) -> Void,
         onThinking: @escaping (String) -> Void,
         onLoading: @escaping (Bool) -> Void,
         onComplete: @escaping (String?, Error?) -> Void) {
        self.onReceive = onReceive
        self.onThinking = onThinking
        self.onLoading = onLoading
        self.onComplete = onComplete
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("BailianService: 收到原始data: \(data)")
        buffer.append(data)
        guard let string = String(data: data, encoding: .utf8) else {
            print("BailianService: data解码为字符串失败")
            return
        }
        print("BailianService: 解码后字符串: \(string)")
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            print("BailianService: SSE行: \(line)")
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            if line.hasPrefix("data:") {
                let jsonString = String(line.dropFirst(5))
                print("BailianService: data:后内容: \(jsonString)")
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        // TODO: 根据白炼API响应格式调整解析逻辑
                        if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let output = json["output"] as? [String: Any],
                           let text = output["text"] as? String {
                            print("BailianService: 解析到text: \(text)")
                            DispatchQueue.main.async {
                                self.fullResponse += text
                                print("BailianService: onReceive回调内容: \(text)")
                                self.onReceive(text)
                            }
                        }
                    } catch {
                        print("BailianService: 解析JSON出错: \(error)")
                        print("BailianService: 原始data: \(jsonString)")
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("BailianService: didCompleteWithError: \(String(describing: error))")
        DispatchQueue.main.async {
            self.onLoading(false)
            print("BailianService: onComplete回调内容: \(self.fullResponse), error: \(String(describing: error))")
            if let error = error {
                self.onComplete(nil, error)
            } else {
                self.onComplete(self.fullResponse, nil)
            }
        }
    }
} */