import SwiftUI
import AVFoundation
import Speech
import UIKit

@available(iOS 15.0, *)
struct VoiceInteractionView: View {
    // MARK: - 状态变量
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
    @State private var sessionStartTime = Date()
    @State private var showingNewChatAlert = false
    @State private var showingSaveAlert = false
    @State private var showingSaveSuccess = false
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
    
    // 当前会话ID
    @State private var currentSessionId: UUID?
    
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - 视图主体
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
                navigationBar
                
                // 聊天消息列表
                messageList
                
                // 实时转写区域
                if isListening {
                    transcriptionView
                }
                
                // 文字输入区域
                if isTextInputActive && !isListening {
                    textInputView
                }
                
                // 底部交互控制区
                bottomControlArea
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: setupView)
        .onDisappear(perform: cleanupView)
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
            Button("不保存") {
                stopListening()
                presentationMode.wrappedValue.dismiss()
            }
            Button("保存") {
                saveCurrentSession()
                showingSaveAlert = false
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("是否保存当前对话进度？保存后可以在历史记录中继续对话。")
        }
        .overlay(successOverlay)
    }
    
    // MARK: - 子视图
    private var navigationBar: some View {
        HStack {
            Button(action: {
                stopListening()
                if !messages.isEmpty {
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
                    if !messages.isEmpty {
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
                NavigationLink(destination: VoiceSettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var messageList: some View {
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
    }
    
    private var transcriptionView: some View {
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
    
    private var textInputView: some View {
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
    
    private var bottomControlArea: some View {
        VStack {
            HStack(spacing: 20) {
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
                
                if !isTextInputActive {
                    voiceButton
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
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
    }
    
    private var voiceButton: some View {
        ZStack {
            if isListening {
                rippleEffect
            }
            
            Circle()
                .fill(Color.white)
                .frame(width: 70, height: 70)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            
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
            
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .foregroundColor(.white)
                .opacity(isListening ? 0.9 : 1.0)
                .scaleEffect(isListening ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: isListening)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isListening {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        safelyCheckMicrophonePermission()
                        withAnimation {
                            rippleScale1 = 1.4
                            rippleScale2 = 1.2
                            rippleScale3 = 1.3
                        }
                    }
                }
                .onEnded { _ in
                    if isListening {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        stopListening()
                        if let transcribedText = transcribedText, !transcribedText.isEmpty {
                            sendMessage()
                        }
                        withAnimation {
                            rippleScale1 = 1.0
                            rippleScale2 = 1.0
                            rippleScale3 = 1.0
                        }
                    }
                }
        )
        .padding(.vertical, 15)
    }
    
    private var rippleEffect: some View {
        ZStack {
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
            
            Circle()
                .stroke(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.3), lineWidth: 2)
                .frame(width: 100, height: 100)
                .scaleEffect(rippleScale2)
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                    value: rippleScale2
                )
            
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
        }
    }
    
    private var successOverlay: some View {
        Group {
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingSaveSuccess)
    }
    
    // MARK: - 视图生命周期
    private func setupView() {
        initializeSpeechRecognizer()
        setupKeyboardObservers()
    }
    
    private func cleanupView() {
        stopListening()
        saveSessionOnDisappear()
    }
    
    private func setupKeyboardObservers() {
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
    
    // MARK: - 消息处理
    private func sendTextMessage() {
        guard !textInput.isEmpty else { return }
        
        let messageContent = textInput
        textInput = ""
        
        Task {
            await sendMessage(content: messageContent)
        }
    }
    
    private func sendMessage(content: String) async {
        // 添加用户消息
        let userMessage = ChatMessage(content: content, isUser: true, timestamp: Date())
        await MainActor.run {
            messages.append(userMessage)
            currentResponse = ""
            isStreaming = true
        }
        
        do {
            let stream = try await StreamingAPIManager.shared.streamChatRequest(userMessage: content)
            var accumulatedResponse = ""
            
            for try await chunk in stream {
                await MainActor.run {
                    accumulatedResponse += chunk
                    currentResponse = accumulatedResponse
                }
                // 添加小延迟使显示更自然
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
            await MainActor.run {
                let botMessage = ChatMessage(content: currentResponse, isUser: false, timestamp: Date())
                messages.append(botMessage)
                isStreaming = false
                currentResponse = ""
            }
        } catch {
            await MainActor.run {
                isStreaming = false
                let errorMessage = ChatMessage(content: "请求失败: \(error.localizedDescription)", isUser: false, timestamp: Date())
                messages.append(errorMessage)
            }
        }
    }
    
    private func sendMessage() {
        guard let transcribedText = transcribedText, !transcribedText.isEmpty else { return }
        
        Task {
            await sendMessage(content: transcribedText)
            self.transcribedText = nil
        }
    }
    
    // MARK: - 会话管理
    private func startNewChat() {
        if !messages.isEmpty {
            saveCurrentSession()
        }
        
        messages.removeAll()
        sessionStartTime = Date()
        currentSessionId = nil
        
        Task {
            await StreamingAPIManager.shared.clearHistory()
        }
    }
    
    private func saveCurrentSession() {
        guard !messages.isEmpty else { return }
        
        Task {
            let (title, summary) = await ChatHistoryManager.shared.generateSummaryAndTitle(for: messages)
            
            let session = ChatSession(
                id: currentSessionId ?? UUID(),
                title: title,
                summary: summary,
                startTime: sessionStartTime,
                endTime: Date(),
                messages: messages
            )
            
            await MainActor.run {
                ChatHistoryManager.shared.addChatSession(session)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
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
    
    private func saveSessionOnDisappear() {
        if !messages.isEmpty {
            saveCurrentSession()
        }
    }
    
    // MARK: - 语音识别
    private func initializeSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        }
        
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
        
        if speechRecognizer == nil {
            showError("无法初始化语音识别器，请确保您的设备支持语音识别功能。")
        }
    }
    
    private func showError(_ message: String) {
        Task { @MainActor in
            errorMessage = message
            showingErrorAlert = true
        }
    }
    
    private func safelyCheckMicrophonePermission() {
        do {
            checkMicrophonePermission()
        } catch {
            showError("检查麦克风权限时发生错误: \(error.localizedDescription)")
        }
    }
    
    private func checkMicrophonePermission() {
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch microphoneStatus {
        case .denied, .restricted:
            goToMicrophoneSettings()
        case .notDetermined:
            requestMicrophoneAuthorization()
        case .authorized:
            checkSpeechRecognitionPermission()
        @unknown default:
            showError("未知的麦克风权限状态")
        }
    }
    
    private func requestMicrophoneAuthorization() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            Task { @MainActor in
                if granted {
                    checkSpeechRecognitionPermission()
                } else {
                    goToMicrophoneSettings()
                }
            }
        }
    }
    
    private func goToMicrophoneSettings() {
        Task { @MainActor in
            permissionAlertTitle = "您还没有允许麦克风权限"
            permissionAlertMessage = "去设置一下吧"
            showingPermissionAlert = true
        }
    }
    
    private func checkSpeechRecognitionPermission() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch speechStatus {
        case .denied, .restricted:
            goToSpeechRecognitionSettings()
        case .notDetermined:
            requestSpeechRecognitionAuthorization()
        case .authorized:
            safeStartListening()
        @unknown default:
            showError("未知的语音识别权限状态")
        }
    }
    
    private func requestSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                if status == .authorized {
                    safeStartListening()
                } else {
                    goToSpeechRecognitionSettings()
                }
            }
        }
    }
    
    private func goToSpeechRecognitionSettings() {
        Task { @MainActor in
            permissionAlertTitle = "您还没有允许语音识别权限"
            permissionAlertMessage = "去设置一下吧"
            showingPermissionAlert = true
        }
    }
    
    private func safeStartListening() {
        do {
            startListening()
        } catch {
            showError("启动语音识别时发生错误: \(error.localizedDescription)")
        }
    }
    
    private func startListening() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            showError("语音识别器不可用，请稍后再试。")
            return
        }
        
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
            
            withAnimation {
                rippleScale1 = 1.0
                rippleScale2 = 1.0
                rippleScale3 = 1.0
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var showActionBubble = false
    @State private var showingCopySuccess = false
    @State private var displayedText = ""
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
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
                        HStack(spacing: 8) {
                            Text(displayedText)
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
                                .onAppear {
                                    if !message.isUser {
                                        animateText()
                                    } else {
                                        displayedText = message.content
                                    }
                                }
                            
                            if !message.isUser {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showActionBubble.toggle()
                                    }
                                }) {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 90/255, green: 200/255, blue: 250/255))
                                        .padding(4)
                                }
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
    }
    
    private func animateText() {
        let text = message.content
        var index = 0
        
        func animateNextCharacter() {
            guard index < text.count else { return }
            let endIndex = text.index(text.startIndex, offsetBy: index + 1)
            displayedText = String(text[..<endIndex])
            index += 1
            
            if index < text.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    animateNextCharacter()
                }
            }
        }
        
        animateNextCharacter()
    }
}

struct VoiceInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInteractionView()
    }
} 
