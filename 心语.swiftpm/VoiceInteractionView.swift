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
    
    @State private var showingHistoryDrawer = false
    
    // MARK: - 视图主体
    var body: some View {
        ZStack {
            // 温柔渐变背景
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 255/255, green: 245/255, blue: 235/255), Color(red: 255/255, green: 236/255, blue: 210/255)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部温情导航栏
                HStack {
                    Button(action: {
                        withAnimation {
                            showingHistoryDrawer = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                            )
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("温柔陪伴你的每一天")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    }
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
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.95))
                .shadow(color: Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.05), radius: 8, x: 0, y: 4)
                
                // 聊天消息列表
                messageList
                
                // 实时转写区域
                if isListening {
                    transcriptionView
                }
                
                // 微信风格底部输入区
                wechatInputBar
            }
            
            if showingHistoryDrawer {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showingHistoryDrawer = false
                        }
                    }
                HStack {
                    ChatHistoryView(onClose: {
                        withAnimation {
                            showingHistoryDrawer = false
                        }
                    })
                    .frame(width: min(UIScreen.main.bounds.width * 0.8, 350))
                    .background(Color.white)
                    .transition(.move(edge: .leading))
                    Spacer()
                }
                .zIndex(100)
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
            .background(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
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
    
    // 微信风格底部输入区
    private var wechatInputBar: some View {
        HStack(spacing: 8) {
            // 语音按钮
            ZStack {
                if isListening {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 255/255, green: 236/255, blue: 210/255))
                        .frame(width: 44, height: 44)
                    Text("松开发送")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                } else {
                    Button(action: {
                        safelyCheckMicrophonePermission()
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isListening {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            safelyCheckMicrophonePermission()
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
                        }
                    }
            )
            // 输入框
            TextField("说出你的心事或输入文字…", text: $textInput)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.orange.opacity(0.05), radius: 2, x: 0, y: 1)
                .focused($isTextFieldFocused)
            // 发送按钮
            Button(action: {
                if !textInput.isEmpty {
                    sendTextMessage()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(textInput.isEmpty ? .gray : .white)
                    .background(
                        Circle()
                            .fill(textInput.isEmpty ? Color.gray.opacity(0.2) : Color(red: 255/255, green: 159/255, blue: 10/255))
                            .frame(width: 38, height: 38)
                    )
            }
            .disabled(textInput.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
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
        print("[DEBUG] 调用 saveCurrentSession at cleanupView")

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
            print("[DEBUG] 调用 saveCurrentSession at startNewChat")
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
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
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
            let hwFormat = inputNode.inputFormat(forBus: 0)
            if hwFormat.channelCount == 0 || hwFormat.sampleRate == 0 {
                showError("音频输入不可用，请在真机上测试并检查麦克风权限")
                return
            }
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                
                if let result = result {
                    Task { @MainActor in
                        transcribedText = result.bestTranscription.formattedString
                        textInput = result.bestTranscription.formattedString
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
                VStack(alignment: .trailing) {
                    Text(message.content)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 255/255, green: 159/255, blue: 10/255), Color(red: 255/255, green: 200/255, blue: 100/255)]), startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(22)
                        .shadow(color: Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.08), radius: 4, x: 0, y: 2)
                }
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
            } else {
                Image("cat_avatar")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    .background(
                        Circle()
                            .fill(Color(red: 255/255, green: 236/255, blue: 210/255).opacity(0.5))
                            .frame(width: 44, height: 44)
                    )
                VStack(alignment: .leading) {
                    Text(message.content)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 255/255, green: 236/255, blue: 210/255), Color.white]), startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        .cornerRadius(22)
                        .shadow(color: Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.08), radius: 4, x: 0, y: 2)
                }
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

struct VoiceInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInteractionView()
    }
} 
