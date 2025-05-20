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
    @State private var showingActionBubble = false
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
    
    // 添加新的状态变量
    @State private var showingSaveAlert = false
    @State private var showingCopySuccess = false
    @State private var showingSaveSuccess = false
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 255/255, blue: 255/255),
                    Color(red: 250/255, green: 250/255, blue: 250/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        stopListening()
                        if !currentMessages.isEmpty {
                            showingSaveAlert = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                            )
                    }
                    
                    Spacer()
                    
                    Text("实时交互")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if !currentMessages.isEmpty {
                                showingNewChatAlert = true
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                                )
                        }
                        
                        NavigationLink(destination: ChatHistoryView()) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                                )
                        }
                        
                        Button(action: {
                            if !currentMessages.isEmpty {
                                showingSaveAlert = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                                )
                        }
                        
                        Button(action: {
                            showingActionBubble = false
                        }) {
                            NavigationLink(destination: SettingsView()) {
                                HStack {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                    
                                    Text("语音设置")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Color.white
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                
                // 聊天消息列表
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            
                            if isStreaming {
                                MessageBubble(message: ChatMessage(content: currentResponse, isUser: false, isThinking: true))
                                    .id("streaming")
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 16)
                        .padding(.bottom, 100) // 为底部输入区域留出空间
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: currentResponse) { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            scrollProxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }
                
                Spacer()
                
                // 实时转写区域
                if isListening {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .font(.title3)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                            )
                        
                        Text(transcribedText ?? "正在聆听...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 文字输入区域
                if isTextInputActive && !isListening {
                    HStack {
                        TextField("输入消息...", text: $textInput)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .focused($isTextFieldFocused)
                        
                        Button(action: {
                            if !textInput.isEmpty {
                                sendTextMessage()
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .background(
                                    Circle()
                                        .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                                        .frame(width: 44, height: 44)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 底部交互控制区
                ZStack {
                    VStack {
                        Spacer()
                        
                        // 悬浮输入区域
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
                                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.8))
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    )
                            }
                            
                            // 语音按钮
                            if !isTextInputActive {
                                ZStack {
                                    // 波纹动画效果（仅在录音时显示）
                                    if isListening {
                                        // 第三层波纹（最外层）
                                        Circle()
                                            .stroke(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.2), lineWidth: 1.5)
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
                                            .stroke(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.3), lineWidth: 2)
                                            .frame(width: 100, height: 100)
                                            .scaleEffect(rippleScale2)
                                            .animation(
                                                Animation.easeInOut(duration: 1.2)
                                                    .repeatForever(autoreverses: true),
                                                value: rippleScale2
                                            )
                                        
                                        // 第二层波纹
                                        Circle()
                                            .stroke(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.4), lineWidth: 3)
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
                                                .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.3))
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
                                                .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.3))
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
                                                    Color(red: 255/255, green: 159/255, blue: 10/255),
                                                    Color(red: 255/255, green: 149/255, blue: 0/255)
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
                                            .stroke(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.5), lineWidth: 2)
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
                                .padding(.vertical, 15)
                                
                                // 提示文本
                                Text(isListening ? "松开停止" : "按住说话")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                    .padding(.top, 8)
                                    .animation(.easeInOut(duration: 0.3), value: isListening)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.clear)
                        )
                        .frame(width: 280, height: 60)
                        .padding(.bottom, 16)
                    }
                }
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
        .alert("保存对话", isPresented: $showingSaveAlert) {
            Button("取消", role: .cancel) { }
            Button("保存") {
                saveCurrentSession()
                showingSaveAlert = false
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("是否保存当前对话进度？保存后可以在历史记录中继续对话。")
        }
        .overlay(
            Group {
                if showingCopySuccess {
                    Text("已复制到剪贴板")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                        .transition(.scale.combined(with: .opacity))
                }
                
                if showingSaveSuccess {
                    Text("对话已保存")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingCopySuccess)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingSaveSuccess)
        )
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
        messages.removeAll()
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
                // 添加保存成功的提示
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // 显示保存成功提示
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingSaveSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showingSaveSuccess = false
                    }
                }
            }
        }
    }
    
    private func showCopySuccess() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingCopySuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingCopySuccess = false
            }
        }
    }
    
    private func navigateToVoiceSettings() {
        // 使用 NotificationCenter 通知主视图切换到语音设置页面
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToVoiceSettings"), object: nil)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var isShowingActions = false
    @State private var isLiked = false
    @State private var showLikeAnimation = false
    @State private var showActionBubble = false
    @State private var showingCopySuccess = false
    @State private var showingVoiceSettings = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            // AI消息的操作按钮
            if !message.isUser && !message.isThinking && showActionBubble {
                HStack(spacing: 16) {
                    Button(action: {
                        // 重新生成
                        regenerateMessage()
                    }) {
                        VStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                            Text("重新生成")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(Color(red: 90/255, green: 200/255, blue: 250/255))
                    }
                    
                    Button(action: {
                        // 语音播报
                        speakMessage()
                    }) {
                        VStack {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 14))
                            Text("语音播报")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(Color(red: 90/255, green: 200/255, blue: 250/255))
                    }
                    
                    Button(action: {
                        // 语音设置
                        showingVoiceSettings = true
                        showActionBubble = false
                    }) {
                        VStack {
                            Image(systemName: "waveform.circle")
                                .font(.system(size: 14))
                            Text("语音设置")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(Color(red: 90/255, green: 200/255, blue: 250/255))
                    }
                    .sheet(isPresented: $showingVoiceSettings) {
                        SettingsView()
                    }
                    
                    Button(action: {
                        // 复制文字
                        UIPasteboard.general.string = message.content
                        withAnimation {
                            showActionBubble = false
                        }
                        // 显示复制成功提示
                        showCopySuccess()
                    }) {
                        VStack {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                            Text("复制文字")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(Color(red: 90/255, green: 200/255, blue: 250/255))
                    }
                    
                    Button(action: {
                        // 点赞
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isLiked.toggle()
                            showLikeAnimation = true
                        }
                    }) {
                        VStack {
                            Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 14))
                            Text("点赞")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(isLiked ? Color(red: 255/255, green: 59/255, blue: 48/255) : Color(red: 90/255, green: 200/255, blue: 250/255))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .transition(.scale.combined(with: .opacity))
            }
            
            HStack {
                if message.isUser {
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    if !message.isUser {
                        Image(systemName: "brain.head.profile")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(Color(red: 90/255, green: 200/255, blue: 250/255))
                            .background(
                                Circle()
                                    .fill(Color(red: 90/255, green: 200/255, blue: 250/255).opacity(0.1))
                                    .frame(width: 40, height: 40)
                            )
                    }
                    
                    if message.isThinking {
                        // 思考中动画
                        HStack(spacing: 4) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color(red: 90/255, green: 200/255, blue: 250/255))
                                    .frame(width: 8, height: 8)
                                    .opacity(0.6)
                                    .scaleEffect(message.isThinking ? 1.2 : 0.8)
                                    .animation(
                                        Animation.easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(0.2 * Double(index)),
                                        value: message.isThinking
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    } else {
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                message.isUser ?
                                AnyView(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 255/255, green: 159/255, blue: 10/255),
                                            Color(red: 255/255, green: 149/255, blue: 0/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                ) :
                                AnyView(Color.white)
                            )
                            .foregroundColor(message.isUser ? .white : .black)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .onLongPressGesture(minimumDuration: 0.5) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showActionBubble = true
                                }
                            }
                    }
                    
                    if message.isUser {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .background(
                                Circle()
                                    .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                                    .frame(width: 40, height: 40)
                            )
                    }
                }
                
                if !message.isUser {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if showActionBubble {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showActionBubble = false
                }
            }
        }
        .overlay(
            Group {
                if showingCopySuccess {
                    Text("已复制到剪贴板")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingCopySuccess)
        )
    }
    
    // 重新生成消息
    private func regenerateMessage() {
        // TODO: 实现重新生成逻辑
    }
    
    // 语音播报
    private func speakMessage() {
        let utterance = AVSpeechUtterance(string: message.content)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    private func showCopySuccess() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingCopySuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingCopySuccess = false
            }
        }
    }
}

struct VoiceInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInteractionView()
    }
} 