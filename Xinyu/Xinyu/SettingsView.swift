import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage("maxHistoryLength") private var maxHistoryLength = 10
    @AppStorage("temperature") private var temperature = 0.7
    @AppStorage("systemPrompt") private var systemPrompt = "你是一个情绪管理助手，帮助用户管理情绪。"
    @AppStorage("incrementalOutput") private var incrementalOutput = true
    @AppStorage("topP") private var topP = 0.8
    @AppStorage("topK") private var topK = 50
    @AppStorage("maxTokens") private var maxTokens = 2000
    @AppStorage("selectedVoice") private var selectedVoice = "zh-CN"
    @AppStorage("inputLanguage") private var inputLanguage = "auto"
    @AppStorage("backgroundChat") private var backgroundChat = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let availableVoices = [
        ("zh-CN", "中文（中国）"),
        ("en-US", "英语（美国）"),
        ("ja-JP", "日语（日本）"),
        ("ko-KR", "韩语（韩国）"),
        ("fr-FR", "法语（法国）"),
        ("de-DE", "德语（德国）"),
        ("es-ES", "西班牙语（西班牙）"),
        ("it-IT", "意大利语（意大利）")
    ]
    
    let inputLanguages = [
        ("auto", "自动检测"),
        ("zh-CN", "中文"),
        ("en-US", "英语"),
        ("ja-JP", "日语"),
        ("ko-KR", "韩语"),
        ("fr-FR", "法语"),
        ("de-DE", "德语"),
        ("es-ES", "西班牙语"),
        ("it-IT", "意大利语")
    ]
    
    var body: some View {
        List {
            NavigationLink(destination: ChatHistoryView()) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("聊天历史")
                        .font(.headline)
                }
            }
            
            NavigationLink(destination: PersonalizationView()) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("个性化")
                        .font(.headline)
                }
            }
            
            NavigationLink(destination: VoiceSettingsView()) {
                HStack {
                    Image(systemName: "waveform.circle")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("对话设置")
                        .font(.headline)
                }
            }
            
            NavigationLink(destination: PrivacyPolicyView()) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("隐私政策")
                        .font(.headline)
                }
            }
            
            NavigationLink(destination: AboutView()) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("关于")
                        .font(.headline)
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(InsetGroupedListStyle())
        .interactiveDismissDisabled()
        .background(themeManager.globalBackgroundColor)
    }
}

struct VoiceSettingsView: View {
    @AppStorage("maxHistoryLength") private var maxHistoryLength = 10
    @AppStorage("temperature") private var temperature = 0.7
    @AppStorage("systemPrompt") private var systemPrompt = "你是一个情绪管理助手，帮助用户管理情绪。"
    @AppStorage("incrementalOutput") private var incrementalOutput = true
    @AppStorage("topP") private var topP = 0.8
    @AppStorage("topK") private var topK = 50
    @AppStorage("maxTokens") private var maxTokens = 2000
    @AppStorage("selectedVoice") private var selectedVoice = "zh-CN"
    @AppStorage("inputLanguage") private var inputLanguage = "auto"
    @AppStorage("backgroundChat") private var backgroundChat = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isTesting = false
    
    let availableVoices = [
        ("zh-CN", "中文（中国）"),
        ("en-US", "英语（美国）"),
        ("ja-JP", "日语（日本）"),
        ("ko-KR", "韩语（韩国）"),
        ("fr-FR", "法语（法国）"),
        ("de-DE", "德语（德国）"),
        ("es-ES", "西班牙语（西班牙）"),
        ("it-IT", "意大利语（意大利）")
    ]
    
    let inputLanguages = [
        ("auto", "自动检测"),
        ("zh-CN", "中文"),
        ("en-US", "英语"),
        ("ja-JP", "日语"),
        ("ko-KR", "韩语"),
        ("fr-FR", "法语"),
        ("de-DE", "德语"),
        ("es-ES", "西班牙语"),
        ("it-IT", "意大利语")
    ]
    
    var body: some View {
        List {
            Section(header: Text("语音设置"), footer: Text("配置语音输入和输出相关的参数")) {
                Picker("AI语音", selection: $selectedVoice) {
                    ForEach(availableVoices, id: \.0) { voice in
                        Text(voice.1).tag(voice.0)
                    }
                }
                .pickerStyle(.navigationLink)
                .onChange(of: selectedVoice) { newValue in
                    playSampleVoice(newValue)
                }
                
                Picker("输入语言", selection: $inputLanguage) {
                    ForEach(inputLanguages, id: \.0) { language in
                        Text(language.1).tag(language.0)
                    }
                }
                .pickerStyle(.navigationLink)
                
                Toggle("后台对话", isOn: $backgroundChat)
                    .tint(Color(red: 255/255, green: 159/255, blue: 10/255))
            }
            
            Section(header: Text("对话参数"), footer: Text("配置对话相关的参数")) {
                Stepper("历史记录长度: \(maxHistoryLength)", value: $maxHistoryLength, in: 5...20)
                    .onChange(of: maxHistoryLength) { newValue in
                        if newValue < 5 { maxHistoryLength = 5 }
                        if newValue > 20 { maxHistoryLength = 20 }
                    }
                
                Stepper("温度: \(String(format: "%.1f", temperature))", value: $temperature, in: 0...1, step: 0.1)
                    .onChange(of: temperature) { newValue in
                        if newValue < 0 { temperature = 0 }
                        if newValue > 1 { temperature = 1 }
                    }
                
                Stepper("Top P: \(String(format: "%.1f", topP))", value: $topP, in: 0...1, step: 0.1)
                    .onChange(of: topP) { newValue in
                        if newValue < 0 { topP = 0 }
                        if newValue > 1 { topP = 1 }
                    }
                
                Stepper("Top K: \(topK)", value: $topK, in: 1...100)
                    .onChange(of: topK) { newValue in
                        if newValue < 1 { topK = 1 }
                        if newValue > 100 { topK = 100 }
                    }
                
                Stepper("最大生成长度: \(maxTokens)", value: $maxTokens, in: 100...4000, step: 100)
                    .onChange(of: maxTokens) { newValue in
                        if newValue < 100 { maxTokens = 100 }
                        if newValue > 4000 { maxTokens = 4000 }
                    }
                
                Toggle("增量输出", isOn: $incrementalOutput)
            }
            
            Section(header: Text("系统提示词"), footer: Text("设置AI助手的角色和行为，这将影响AI的回复风格和内容")) {
                TextEditor(text: $systemPrompt)
                    .frame(minHeight: 100)
                    .onChange(of: systemPrompt) { newValue in
                        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            systemPrompt = "你是一个情绪管理助手，帮助用户管理情绪。"
                        }
                    }
            }
            
            Section {
                NavigationLink(destination: APISettingsView()) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.orange)
                        Text("API设置")
                    }
                }
            }
        }
        .navigationTitle("对话设置")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(InsetGroupedListStyle())
        .interactiveDismissDisabled()
        .background(themeManager.globalBackgroundColor)
    }
    
    private func playSampleVoice(_ voiceIdentifier: String) {
        let utterance = AVSpeechUtterance(string: "这是一段示例语音")
        utterance.voice = AVSpeechSynthesisVoice(language: voiceIdentifier)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}

struct APISettingsView: View {
    @AppStorage("apiKey") private var apiKey = "sk-2b0120253a5c4a06bba8a9e4164dea9a"
    @AppStorage("apiDomain") private var apiDomain = "https://dashscope.aliyuncs.com"
    @AppStorage("apiPath") private var apiPath = "/api/v1/apps/717d5ce4c24342379459d3c7d4815ae8/completion"
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isTesting = false
    @State private var showingAPIKey = false
    @State private var apiStatus: APIStatus = .unknown
    
    enum APIStatus: Equatable {
        case unknown
        case success
        case failure(String)
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .success: return .green
            case .failure: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .success: return "checkmark.circle"
            case .failure: return "xmark.circle"
            }
        }
        
        static func == (lhs: APIStatus, rhs: APIStatus) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown):
                return true
            case (.success, .success):
                return true
            case (.failure(let lhsError), .failure(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("API配置"), footer: Text("配置API连接参数，请确保填写正确的API密钥和地址")) {
                HStack {
                    if showingAPIKey {
                        TextField("API密钥", text: $apiKey)
                    } else {
                        SecureField("API密钥", text: $apiKey)
                    }
                    Button(action: { showingAPIKey.toggle() }) {
                        Image(systemName: showingAPIKey ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                TextField("API域名", text: $apiDomain)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                
                TextField("API路径", text: $apiPath)
                    .autocapitalization(.none)
            }
            
            Section {
                Button(action: {
                    Task {
                        await testAPIConnection()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("测试连接")
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.orange)
                .disabled(isTesting || apiKey.isEmpty)
            }
            
            if apiStatus != .unknown {
                Section(header: Text("API状态")) {
                    HStack {
                        Image(systemName: apiStatus.icon)
                            .foregroundColor(apiStatus.color)
                        Text(apiStatus == .success ? "API连接正常" : "API连接异常")
                            .foregroundColor(apiStatus.color)
                    }
                    
                    if case .failure(let error) = apiStatus {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API地址：\(apiDomain + apiPath)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("认证方式：Bearer Token")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("请求方法：POST")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("内容类型：application/json")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .navigationTitle("API设置")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(InsetGroupedListStyle())
        .background(themeManager.globalBackgroundColor)
        .alert("API测试", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func testAPIConnection() async {
        isTesting = true
        defer { isTesting = false }
        
        do {
            // 构建完整的API URL
            let fullURL = apiDomain + apiPath
            guard let url = URL(string: fullURL) else {
                alertMessage = "无效的API地址"
                apiStatus = .failure("无效的API地址")
                showingAlert = true
                return
            }
            
            // 创建测试请求
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("enable", forHTTPHeaderField: "X-DashScope-SSE")
            
            // 构建测试消息
            let testMessage = ["role": "user", "content": "测试连接"]
            let requestBody: [String: Any] = [
                "input": ["messages": [testMessage]],
                "parameters": [
                    "incremental_output": true,
                    "temperature": 0.7,
                    "top_p": 0.8,
                    "top_k": 50,
                    "max_tokens": 100
                ]
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
            
            // 发送请求
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    alertMessage = "连接成功！"
                    apiStatus = .success
                case 401:
                    alertMessage = "认证失败，请检查API密钥"
                    apiStatus = .failure("认证失败，请检查API密钥")
                case 403:
                    alertMessage = "访问被拒绝，请检查API权限"
                    apiStatus = .failure("访问被拒绝，请检查API权限")
                case 404:
                    alertMessage = "API地址不存在，请检查域名和路径"
                    apiStatus = .failure("API地址不存在，请检查域名和路径")
                case 429:
                    alertMessage = "请求频率超限，请稍后重试"
                    apiStatus = .failure("请求频率超限，请稍后重试")
                case 500...599:
                    alertMessage = "服务器错误，请稍后重试"
                    apiStatus = .failure("服务器错误，请稍后重试")
                default:
                    alertMessage = "连接失败，状态码：\(httpResponse.statusCode)"
                    apiStatus = .failure("连接失败，状态码：\(httpResponse.statusCode)")
                }
            } else {
                alertMessage = "连接失败，请检查网络"
                apiStatus = .failure("连接失败，请检查网络")
            }
        } catch {
            alertMessage = "连接失败：\(error.localizedDescription)"
            apiStatus = .failure(error.localizedDescription)
        }
        
        showingAlert = true
    }
}

struct PersonalizationView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("enableVoice") private var enableVoice = true
    @AppStorage("enableHaptic") private var enableHaptic = true
    
    var body: some View {
        List {
            Section(header: Text("外观")) {
                Toggle("深色模式", isOn: Binding(
                    get: { themeManager.getCurrentTheme().isDark },
                    set: { themeManager.setDarkMode($0) }
                ))
                .disabled(themeManager.getCurrentTheme().followSystem)
                
                Toggle("跟随系统", isOn: Binding(
                    get: { themeManager.getCurrentTheme().followSystem },
                    set: { themeManager.setFollowSystem($0) }
                ))
            }
            
            Section(header: Text("声音")) {
                Toggle("声音反馈", isOn: $enableVoice)
                Toggle("震动反馈", isOn: $enableHaptic)
            }
        }
        .navigationTitle("个性化")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(InsetGroupedListStyle())
        .interactiveDismissDisabled()
        .background(themeManager.globalBackgroundColor)
    }
}

struct PrivacyPolicyView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("隐私政策")
                        .font(.title)
                        .bold()
                        .foregroundColor(themeManager.textColor)
                    
                    Text("我们非常重视您的隐私保护。本应用致力于为您提供安全、私密的情绪管理服务。")
                        .foregroundColor(themeManager.textColor)
                    
                    Text("数据安全")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    Text("• 所有语音数据仅在本地处理，不会上传到任何服务器\n• 聊天记录仅保存在您的设备中\n• 采用端到端加密技术保护您的数据安全")
                        .foregroundColor(themeManager.textColor)
                    
                    Text("权限说明")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    Text("本应用需要以下权限：\n• 麦克风权限：用于语音输入\n• 扬声器权限：用于语音输出\n• 存储权限：用于保存聊天记录\n• 网络权限：用于语音识别服务")
                        .foregroundColor(themeManager.textColor)
                    
                    Text("数据使用")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    Text("• 您的所有数据都存储在本地设备中\n• 不会收集或分享您的个人信息\n• 不会向第三方提供任何用户数据\n• 您可以随时删除所有本地数据")
                        .foregroundColor(themeManager.textColor)
                }
                
                Group {
                    Text("更新说明")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    Text("本隐私政策可能会随应用更新而更新。更新时，我们会在应用内通知您。")
                        .foregroundColor(themeManager.textColor)
                    
                    Text("联系我们")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    Text("如果您对隐私政策有任何疑问，请通过以下方式联系我们：\nEmail: hi@cursor.com")
                        .foregroundColor(themeManager.textColor)
                }
            }
            .padding()
        }
        .background(themeManager.globalBackgroundColor)
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.large)
        .interactiveDismissDisabled()
    }
}

struct AboutView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Logo 部分
                VStack(spacing: 15) {
                    Image(systemName: "waveform.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.orange)
                    
                    Text("心语")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.textColor)
                    
                    Text("版本 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // 应用描述
                VStack(spacing: 20) {
                    Text("用声音传递心意")
                        .font(.title2)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("心语是一款专注于情绪管理的智能助手，通过语音交互和情绪分析，帮助您更好地了解和管理自己的情绪状态。")
                        .multilineTextAlignment(.center)
                        .foregroundColor(themeManager.textColor)
                        .padding(.horizontal)
                }
                
                // 功能特点
                VStack(alignment: .leading, spacing: 15) {
                    Text("主要功能")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    FeatureRow(icon: "waveform", text: "智能语音交互")
                    FeatureRow(icon: "chart.bar.fill", text: "情绪分析追踪")
                    FeatureRow(icon: "book.fill", text: "心情日记记录")
                    FeatureRow(icon: "person.fill", text: "个性化设置")
                }
                .padding(.horizontal)
                
                // 联系方式
                VStack(spacing: 10) {
                    Text("联系我们")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Email: hi@cursor.com")
                        .foregroundColor(.gray)
                    
                    Text("官方网站: www.cursor.com")
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
        }
        .background(themeManager.globalBackgroundColor)
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.large)
        .interactiveDismissDisabled()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.title3)
            Text(text)
                .foregroundColor(themeManager.textColor)
            Spacer()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
} 
