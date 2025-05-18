import SwiftUI
import AVFoundation
import Speech
import UIKit

@available(iOS 15.0, *)
struct VoiceInteractionView: View {
    @State private var isListening = false
    @State private var transcribedText: String? = nil
    @State private var messages: [ChatMessage] = []
    @State private var speechRecognizer: SFSpeechRecognizer?
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var permissionAlertTitle = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingSettings = false
    @State private var sessionStartTime = Date()
    @State private var currentMessages: [ChatMessage] = []
    @State private var showingNewChatAlert = false
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("apiDomain") private var apiDomain = "https://api.openai.com"
    @AppStorage("apiPath") private var apiPath = "/v1/chat/completions"
    @AppStorage("apiModel") private var apiModel = "gpt-4o-mini"
    @Environment(\.presentationMode) var presentationMode
    @State private var currentResponse = ""
    @State private var isStreaming = false
    
    // 文字输入相关状态
    @State private var textInput = ""
    @State private var isTextInputActive = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool
    
    // 波纹动画状态
    @State private var rippleScale1: CGFloat = 1.0
    @State private var rippleScale2: CGFloat = 1.0
    @State private var rippleScale3: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.orange.opacity(0.1).ignoresSafeArea()
            
            VStack {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        stopListening()
                        saveCurrentSession()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text("实时交互")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if !currentMessages.isEmpty {
                                showingNewChatAlert = true
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        NavigationLink(destination: ChatHistoryView()) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            APIManager.shared.clearHistory()
                            currentMessages.removeAll()
                        }) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                
                // 聊天消息列表
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isStreaming {
                                MessageBubble(message: ChatMessage(content: currentResponse, isUser: false, isThinking: true))
                                    .id("streaming")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: currentResponse) { _ in
                        withAnimation {
                            scrollProxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }
                
                Spacer()
                
                // 实时转写区域
                if isListening {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        Text(transcribedText ?? "正在聆听...")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                // 文字输入区域
                if isTextInputActive && !isListening {
                    HStack {
                        TextField("输入消息...", text: $textInput)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(20)
                            .focused($isTextFieldFocused)
                        
                        Button(action: {
                            if !textInput.isEmpty {
                                sendTextMessage()
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
                
                // 底部交互控制区
                HStack(spacing: 20) {
                    // 文字输入切换按钮
                    Button(action: {
                        if isListening {
                            stopListening()
                        }
                        isTextInputActive.toggle()
                        if isTextInputActive {
                            isTextFieldFocused = true
                        }
                    }) {
                        Image(systemName: isTextInputActive ? "mic" : "keyboard")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                            .padding()
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 3)
                    }
                    
                    // 语音按钮
                    if !isTextInputActive {
                        ZStack {
                            // 波纹动画效果（仅在录音时显示）
                            if isListening {
                                // 第三层波纹（最外层）
                                Circle()
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1.5)
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(rippleScale1)
                                    .animation(
                                        Animation.easeInOut(duration: 2.0)
                                            .repeatForever(autoreverses: true)
                                            .delay(0.1),
                                        value: rippleScale1
                                    )
                                
                                // 第一层波纹
                                Circle()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(rippleScale2)
                                    .animation(
                                        Animation.easeInOut(duration: 1.2)
                                            .repeatForever(autoreverses: true),
                                        value: rippleScale2
                                    )
                                
                                // 第二层波纹
                                Circle()
                                    .stroke(Color.orange.opacity(0.4), lineWidth: 3)
                                    .frame(width: 90, height: 90)
                                    .scaleEffect(rippleScale3)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true)
                                            .delay(0.2),
                                        value: rippleScale3
                                    )
                                
                                // 声波粒子效果（左侧）
                                ForEach(0..<3) { i in
                                    Circle()
                                        .fill(Color.orange.opacity(0.3))
                                        .frame(width: 4, height: 4)
                                        .offset(x: -45 - CGFloat(i * 8), y: CGFloat((-1 + i) * 10))
                                        .scaleEffect(isListening ? 1.5 : 0.8)
                                        .opacity(isListening ? 0.7 : 0)
                                        .animation(
                                            Animation.easeInOut(duration: 0.8)
                                                .repeatForever(autoreverses: true)
                                                .delay(0.1 * Double(i)),
                                            value: isListening
                                        )
                                }
                                
                                // 声波粒子效果（右侧）
                                ForEach(0..<3) { i in
                                    Circle()
                                        .fill(Color.orange.opacity(0.3))
                                        .frame(width: 4, height: 4)
                                        .offset(x: 45 + CGFloat(i * 8), y: CGFloat((-1 + i) * 10))
                                        .scaleEffect(isListening ? 1.5 : 0.8)
                                        .opacity(isListening ? 0.7 : 0)
                                        .animation(
                                            Animation.easeInOut(duration: 0.8)
                                                .repeatForever(autoreverses: true)
                                                .delay(0.1 * Double(i)),
                                            value: isListening
                                        )
                                }
                            }
                            
                            // 白色背景
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                            
                            // 按钮背景渐变
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            isListening ? Color.red : Color.orange,
                                            isListening ? Color.red.opacity(0.8) : Color.orange.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            // 麦克风图标
                            Image(systemName: "waveform.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .opacity(isListening ? 0.9 : 1.0)
                                .scaleEffect(isListening ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.5), value: isListening)
                            
                            // 点击时的涟漪效果
                            if isListening {
                                Circle()
                                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(isListening ? 1.1 : 1.0)
                                    .animation(
                                        Animation.easeInOut(duration: 0.8)
                                            .repeatForever(autoreverses: true),
                                        value: isListening
                                    )
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isListening {
                                        // 触觉反馈
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.prepare()
                                        generator.impactOccurred()
                                        
                                        // 开始录音
                                        safelyCheckMicrophonePermission()
                                        
                                        // 启动波纹动画
                                        withAnimation {
                                            rippleScale1 = 1.4
                                            rippleScale2 = 1.2
                                            rippleScale3 = 1.3
                                        }
                                    }
                                }
                                .onEnded { _ in
                            if isListening {
                                        // 结束触觉反馈
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        
                                        // 停止录音
                                stopListening()
                                if let transcribedText = transcribedText, !transcribedText.isEmpty {
                                    sendMessage()
                                }
                                        
                                        // 重置波纹动画
                                        withAnimation {
                                            rippleScale1 = 1.0
                                            rippleScale2 = 1.0
                                            rippleScale3 = 1.0
                                        }
                            }
                        }
                        )
                        .padding(.vertical, 15) // 添加垂直间距，为波纹效果留出空间
                        
                        // 提示文本
                        Text(isListening ? "松开停止" : "按住说话")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(isListening ? .red.opacity(0.8) : .gray)
                            .padding(.top, 8)
                            .animation(.easeInOut(duration: 0.3), value: isListening)
                    }
                }
                .padding(.bottom, isTextInputActive ? 5 : 30)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 初始化语音识别器
            initializeSpeechRecognizer()
            
            // 添加键盘通知
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    Task { @MainActor in
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                Task { @MainActor in
                    keyboardHeight = 0
                }
            }
        }
        .onDisappear {
            stopListening()
        }
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text(permissionAlertTitle),
                message: Text(permissionAlertMessage),
                primaryButton: .default(Text("去设置")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .alert("发生错误", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("开始新对话", isPresented: $showingNewChatAlert) {
            Button("取消", role: .cancel) { }
            Button("确定") {
                startNewChat()
            }
        } message: {
            Text("当前对话将被保存，确定要开始新对话吗？")
        }
    }
    
    // 发送文字消息
    private func sendTextMessage() {
        guard !textInput.isEmpty else { return }
        
        let messageContent = textInput
        textInput = ""
        
        Task {
            // 添加用户消息
            let userMessage = ChatMessage(content: messageContent, isUser: true)
            await MainActor.run {
                messages.append(userMessage)
                currentMessages.append(userMessage)
                currentResponse = ""
                isStreaming = true
            }
            
            do {
                let stream = try await StreamingAPIManager.shared.streamChatRequest(userMessage: messageContent)
                
                for try await chunk in stream {
                    await MainActor.run {
                        currentResponse += chunk
                    }
                }
                
                await MainActor.run {
                    let botMessage = ChatMessage(content: currentResponse, isUser: false)
                    messages.append(botMessage)
                    currentMessages.append(botMessage)
                    isStreaming = false
                    currentResponse = ""
                }
            } catch {
                await MainActor.run {
                    isStreaming = false
                    let errorMessage = ChatMessage(content: "请求失败: \(error.localizedDescription)", isUser: false)
                    messages.append(errorMessage)
                    currentMessages.append(errorMessage)
                }
            }
        }
    }
    
    // 初始化语音识别器
    private func initializeSpeechRecognizer() {
        // 尝试初始化中文识别器
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        
        // 如果中文不可用，尝试使用设备默认语言
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        }
        
        // 如果仍然不可用，尝试使用英语
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
        
        // 如果所有尝试都失败
        if speechRecognizer == nil {
            showError("无法初始化语音识别器，请确保您的设备支持语音识别功能。")
        }
    }
    
    // 错误处理
    private func showError(_ message: String) {
        Task { @MainActor in
            errorMessage = message
            showingErrorAlert = true
        }
    }
    
    // 安全地检查麦克风权限（带错误处理）
    private func safelyCheckMicrophonePermission() {
        do {
            checkMicrophonePermission()
        } catch {
            showError("检查麦克风权限时发生错误: \(error.localizedDescription)")
        }
    }
    
    // 检查麦克风权限
    private func checkMicrophonePermission() {
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch microphoneStatus {
        case .denied, .restricted:
            // 用户拒绝了麦克风权限
            goToMicrophoneSettings()
        case .notDetermined:
            // 尚未弹出权限请求窗口
            requestMicrophoneAuthorization()
        case .authorized:
            // 已授权，检查语音识别权限
            checkSpeechRecognitionPermission()
        @unknown default:
            showError("未知的麦克风权限状态")
        }
    }
    
    // 请求麦克风授权
    private func requestMicrophoneAuthorization() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            Task { @MainActor in
                if granted {
                    // 麦克风权限获取成功，检查语音识别权限
                    checkSpeechRecognitionPermission()
                } else {
                    // 用户拒绝了麦克风权限
                    goToMicrophoneSettings()
                }
            }
        }
    }
    
    // 前往麦克风设置页面
    private func goToMicrophoneSettings() {
        Task { @MainActor in
            permissionAlertTitle = "您还没有允许麦克风权限"
            permissionAlertMessage = "去设置一下吧"
            showingPermissionAlert = true
        }
    }
    
    // 检查语音识别权限
    private func checkSpeechRecognitionPermission() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch speechStatus {
        case .denied, .restricted:
            // 用户拒绝了语音识别权限
            goToSpeechRecognitionSettings()
        case .notDetermined:
            // 尚未弹出权限请求窗口
            requestSpeechRecognitionAuthorization()
        case .authorized:
            // 已授权，开始语音识别
            safeStartListening()
        @unknown default:
            showError("未知的语音识别权限状态")
        }
    }
    
    // 请求语音识别授权
    private func requestSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                if status == .authorized {
                    // 语音识别权限获取成功，开始语音识别
                    safeStartListening()
                } else {
                    // 用户拒绝了语音识别权限
                    goToSpeechRecognitionSettings()
                }
            }
        }
    }
    
    // 前往语音识别设置页面
    private func goToSpeechRecognitionSettings() {
        Task { @MainActor in
            permissionAlertTitle = "您还没有允许语音识别权限"
            permissionAlertMessage = "去设置一下吧"
            showingPermissionAlert = true
        }
    }
    
    // 安全开始语音识别（带错误处理）
    private func safeStartListening() {
        do {
            startListening()
        } catch {
            showError("启动语音识别时发生错误: \(error.localizedDescription)")
        }
    }
    
    private func startListening() {
        // 检查语音识别器是否可用
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            showError("语音识别器不可用，请稍后再试。")
            return
        }
        
        // 初始化识别请求和音频引擎
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else {
                showError("无法创建语音识别请求")
                return
            }
            
            let inputNode = audioEngine.inputNode
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                
                if let result = result {
                    Task { @MainActor in
                        transcribedText = result.bestTranscription.formattedString
                    }
                    isFinal = result.isFinal
                }
                
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    
                    Task { @MainActor in
                        isListening = false
                        
                        // 重置波纹动画
                        withAnimation {
                            rippleScale1 = 1.0
                            rippleScale2 = 1.0
                            rippleScale3 = 1.0
                        }
                    }
                    
                    if let error = error {
                        print("语音识别错误: \(error.localizedDescription)")
                    }
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
            transcribedText = nil
            
            // 启动波纹动画
            withAnimation {
                rippleScale1 = 1.4
                rippleScale2 = 1.2
                rippleScale3 = 1.3
            }
            
        } catch {
            showError("启动语音识别失败: \(error.localizedDescription)")
        }
    }
    
    private func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isListening = false
            
            // 重置波纹动画
            withAnimation {
                rippleScale1 = 1.0
                rippleScale2 = 1.0
                rippleScale3 = 1.0
            }
        }
    }
    
    private func callAIAPI() async {
        guard let transcribedText = transcribedText, !transcribedText.isEmpty else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(content: transcribedText, isUser: true)
        await MainActor.run {
            messages.append(userMessage)
            currentMessages.append(userMessage)
            currentResponse = ""
            isStreaming = true
        }
        
        do {
            let stream = try await StreamingAPIManager.shared.streamChatRequest(userMessage: transcribedText)
            
            for try await chunk in stream {
                await MainActor.run {
                    currentResponse += chunk
                }
            }
            
            await MainActor.run {
                let botMessage = ChatMessage(content: currentResponse, isUser: false)
                messages.append(botMessage)
                currentMessages.append(botMessage)
                isStreaming = false
                currentResponse = ""
                self.transcribedText = nil
            }
        } catch {
            await MainActor.run {
                isStreaming = false
                self.transcribedText = nil
                let errorMessage = ChatMessage(content: "请求失败: \(error.localizedDescription)", isUser: false)
                messages.append(errorMessage)
                currentMessages.append(errorMessage)
            }
        }
    }
    
    private func sendMessage() {
        guard let transcribedText = transcribedText, !transcribedText.isEmpty else { return }
        
        Task {
            await callAIAPI()
        }
    }
    
    private func startNewChat() {
        // 保存当前会话
        if !currentMessages.isEmpty {
            saveCurrentSession()
        }
        
        // 重置状态
        currentMessages.removeAll()
        sessionStartTime = Date()
        APIManager.shared.clearHistory()
    }
    
    private func saveCurrentSession() {
        guard !currentMessages.isEmpty else { return }
        
        Task {
            let (title, summary) = await ChatHistoryManager.shared.generateSummaryAndTitle(for: currentMessages)
            
            let session = ChatSession(
                id: UUID(),
                title: title,
                summary: summary,
                startTime: sessionStartTime,
                endTime: Date(),
                messages: currentMessages
            )
            
            await MainActor.run {
                ChatHistoryManager.shared.addChatSession(session)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            HStack(spacing: 10) {
                if !message.isUser {
                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }
                
                if message.isThinking {
                    // 思考中动画
                    HStack(spacing: 3) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 7, height: 7)
                                .opacity(0.5)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
                } else {
                    Text(message.content)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(message.isUser ? Color.orange : Color.white)
                        .foregroundColor(message.isUser ? .white : .black)
                        .cornerRadius(20)
                }
                
                if message.isUser {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.orange)
                }
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct VoiceInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInteractionView()
    }
} 