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
    @State private var isTextInputActive = true
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool
    
    // 波纹动画状态
    @State private var rippleScale1: CGFloat = 1.0
    @State private var rippleScale2: CGFloat = 1.0
    @State private var rippleScale3: CGFloat = 1.0
    @State private var ripple = false
    
    // 当前会话ID
    @State private var currentSessionId: UUID?
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingHistoryDrawer = false
    @State private var showingClearHistoryAlert = false
    
    @State private var selectedSessionForDelete: ChatSession? = nil
    @State private var showingDeleteAlert = false
    @State private var selectedSessionForDetail: ChatSession? = nil
    
    @State private var searchText = ""
    @State private var isSearchActive = false
    
    @State private var showingArchiveAlert = false
    @State private var isSavingSession = false
    @State private var isSessionSummarySaving = false
    
    @StateObject private var ttsManager = SpeechSynthesizerManager()
    @State private var lastSpokenMessageId: UUID? = nil
    
    @State private var waveformHeights: [CGFloat] = Array(repeating: 0.5, count: 8)
    @State private var waveformTimer: Timer?
    
    @State private var waveformPoints: [CGFloat] = Array(repeating: 0.5, count: 40)
    @State private var waveformLineTimer: Timer?
    
    // MARK: - 视图主体
    var body: some View {
        NavigationStack {
            mainContent
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !showingHistoryDrawer {
                        VStack(spacing: 0) {
                            ttsStatusBar
                            bottomInputBar
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.spring()) {
                            showingHistoryDrawer = true
                        }
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text(currentSessionTitle)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            startNewChat()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        }
                    }
                }
                .toolbarBackground(.clear, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear(perform: setupView)
        .onDisappear(perform: cleanupView)
        .onChange(of: messages) { newMessages in
            speakLatestAImessageIfNeeded(messages: newMessages)
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
            Button("不保存") {
                stopListening()
                presentationMode.wrappedValue.dismiss()
            }
            Button("保存") {
                Task { await saveCurrentSessionIfChanged() }
                showingSaveAlert = false
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("是否保存当前对话进度？保存后可以在历史记录中继续对话。")
        }
        .alert("清空历史", isPresented: $showingClearHistoryAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                ChatHistoryManager.shared.clearAllSessions()
            }
        } message: {
            Text("确定要清空所有聊天记录吗？此操作无法撤销。")
        }
        .alert("删除对话", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let session = selectedSessionForDelete,
                   let idx = ChatHistoryManager.shared.chatSessions.firstIndex(where: { $0.id == session.id }) {
                    ChatHistoryManager.shared.removeChatSession(at: IndexSet(integer: idx))
                }
            }
        } message: {
            Text("确定要删除这条对话记录吗？此操作无法撤销。")
        }
        .alert("存档当前话题？", isPresented: $showingArchiveAlert) {
            Button("取消", role: .cancel) { }
            Button("存档", role: .destructive) {
                archiveCurrentSession()
            }
        } message: {
            Text("存档后该话题将无法继续对话，是否确认存档？")
        }
        .overlay(savingOverlay)
        .overlay(successOverlay)
        .sheet(item: $selectedSessionForDetail) { session in
            ChatDetailView(session: session)
        }
    }
    
    private var mainContent: some View {
                ZStack {
            backgroundGradient
            mainVStack
            if showingHistoryDrawer {
                historyDrawer
                    .zIndex(999)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 255/255, green: 245/255, blue: 235/255), Color(red: 255/255, green: 236/255, blue: 210/255)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var mainVStack: some View {
        VStack(spacing: 0) {
            messageList
                .ignoresSafeArea(.container, edges: .top)
            if isListening {
                transcriptionView
            }
        }
    }
    
    private var historyDrawer: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                                                            .onTapGesture {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.85, blendDuration: 0.2)) {
                        showingHistoryDrawer = false
                    }
                }
            GeometryReader { geometry in
                let drawerWidth = isSearchActive ? geometry.size.width : geometry.size.width * 0.8
                HStack(spacing: 0) {
                    historyDrawerPanel(geometry: geometry, drawerWidth: drawerWidth)
                        .animation(.spring(response: 0.38, dampingFraction: 0.85, blendDuration: 0.2), value: isSearchActive)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .ignoresSafeArea()
            }
        }
        .zIndex(1000)
    }
    
    private func historyDrawerPanel(geometry: GeometryProxy, drawerWidth: CGFloat) -> some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                Color(red: 255/255, green: 245/255, blue: 235/255)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    if ChatHistoryManager.shared.chatSessions.isEmpty {
                        historyEmptyView
                                                                } else {
                        historyScrollView(geometry: geometry)
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索聊天记录")
                .onChange(of: searchText) { newValue in
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.85, blendDuration: 0.2)) {
                        isSearchActive = !searchText.isEmpty
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("对话记录")
                                                        .font(.headline)
                                    }
                                }
                            }
                            .frame(width: drawerWidth)
                            .background(
                                RoundedRectangle(cornerRadius: 0, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .background(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.05))
                            )
                            .clipShape(
                                RoundedCorner(radius: 28, corners: [.topRight, .bottomRight])
                            )
                            .overlay(
                                RoundedCorner(radius: 28, corners: [.topRight, .bottomRight])
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 16, x: 8, y: 0)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                            .animation(.spring(response: 0.38, dampingFraction: 0.85, blendDuration: 0.2), value: showingHistoryDrawer)
    }
    
    private var historyEmptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("暂无聊天记录")
                .font(.title2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func historyScrollView(geometry: GeometryProxy) -> some View {
        let sortedSessions = ChatHistoryManager.shared.chatSessions.sorted { $0.lastModified > $1.lastModified }
        return ScrollView {
            historySessionList(sortedSessions: sortedSessions)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }
    
    private func historySessionList(sortedSessions: [ChatSession]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedSessions) { session in
                historySessionRow(session: session)
            }
        }
    }
    
    private func historySessionRow(session: ChatSession) -> some View {
        ChatSessionRow(session: session, highlight: searchText, isSelected: currentSessionId == session.id)
            .onTapGesture {
                if session.isArchived {
                    selectedSessionForDetail = session
                } else {
                    messages = session.messages
                    currentSessionId = session.id
                    sessionStartTime = session.startTime
                    withAnimation { showingHistoryDrawer = false }
                }
            }
            .contextMenu {
                Button(role: .destructive) {
                    selectedSessionForDelete = session
                    showingDeleteAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
                Button(role: .none) {
                    archiveSession(session)
                } label: {
                    Label("存档", systemImage: "archivebox")
                }
        }
    }
    
    // MARK: - 子视图
    private var messageList: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                if messages.isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.25))
                        Text("开始你的心语之旅吧~\n可以输入或说出你的心事")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .frame(maxWidth: 340)
                    .transition(.opacity)
                }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                        Spacer().frame(height: 80)
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
                .onChange(of: textInput) { _ in
                    if isTextInputActive, let lastMessage = messages.last {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
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
            // 切换输入方式按钮
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
            // 语音按钮区域
            if !isTextInputActive {
                voiceButton
            }
            // 输入框
            if isTextInputActive {
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // 新增voiceButton和rippleEffect实现，复用isListening、rippleScale1/2/3、safelyCheckMicrophonePermission、stopListening等状态和方法
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
                            sendTextMessage()
                        }
                        withAnimation {
                            rippleScale1 = 1.0
                            rippleScale2 = 1.0
                            rippleScale3 = 1.0
                        }
                    }
                }
        )
        .padding(.vertical, 8)
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
    
    private var savingOverlay: some View {
        Group {
            if isSavingSession {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 255/255, green: 159/255, blue: 10/255)))
                        .scaleEffect(1.2)
                    Text("对话保存中，请稍等")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSavingSession)
    }
    
    private var successOverlay: some View {
        Group {
            if showingSaveSuccess {
                Text("对话已保存")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
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

        Task { await saveCurrentSessionIfChanged() }
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
            // 1. 如果是新会话的第一条消息，立即创建卡片
            if messages.isEmpty {
                let newId = UUID()
                let userMessage = ChatMessage(content: messageContent, isUser: true, timestamp: Date())
                let session = ChatSession(
                    id: newId,
                    title: "新对话",
                    summary: "暂无摘要",
                    startTime: Date(),
                    endTime: Date(),
                    messages: [userMessage],
                    isArchived: false
                )
                ChatHistoryManager.shared.upsertChatSession(session)
                currentSessionId = newId
                sessionStartTime = Date()
                await MainActor.run {
                    messages = [userMessage]
                }
                await sendMessage(content: messageContent, isFirstAIReply: true)
            } else {
                await sendMessage(content: messageContent, isFirstAIReply: false)
            }
        }
    }
    
    private func sendMessage(content: String, isFirstAIReply: Bool) async {
        // 添加用户消息
        let userMessage = ChatMessage(content: content, isUser: true, timestamp: Date())
        await MainActor.run {
            messages.append(userMessage)
            currentResponse = ""
            isStreaming = true
        }
        print("[DEBUG] 用户消息已添加: \(content)")
        do {
            let stream = try await StreamingAPIManager.shared.streamChatRequest(userMessage: content)
            var accumulatedResponse = ""
            for try await chunk in stream {
                await MainActor.run {
                    accumulatedResponse += chunk
                    currentResponse = accumulatedResponse
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            await MainActor.run {
                let botMessage = ChatMessage(content: currentResponse, isUser: false, timestamp: Date())
                messages.append(botMessage)
                isStreaming = false
                print("[DEBUG] AI消息已添加: \(currentResponse)")
            }
            // 只在内容变化时才生成摘要
            let currentContent = messages.map { $0.content }.joined(separator: "\n")
            let lastSession = ChatHistoryManager.shared.chatSessions.last
            let lastContent = lastSession?.messages.map { $0.content }.joined(separator: "\n") ?? ""
            if currentContent != lastContent {
                await updateSessionSummaryAndTitle()
            }
        } catch {
            await MainActor.run {
                isStreaming = false
                let errorMessage = ChatMessage(content: "请求失败: \(error.localizedDescription)", isUser: false, timestamp: Date())
                messages.append(errorMessage)
                print("[DEBUG] AI消息请求失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateSessionSummaryAndTitle() async {
        await MainActor.run { isSessionSummarySaving = true }
        let (title, summary) = await ChatHistoryManager.shared.generateSummaryAndTitle(for: messages)
        let session = ChatSession(
            id: currentSessionId ?? UUID(),
            title: title,
            summary: summary,
            startTime: sessionStartTime,
            endTime: Date(),
            messages: messages,
            isArchived: false
        )
        ChatHistoryManager.shared.upsertChatSession(session)
        await MainActor.run { isSessionSummarySaving = false }
    }
    
    // MARK: - 会话管理
    private func startNewChat() {
        if !messages.isEmpty {
            print("[DEBUG] 调用 saveCurrentSession at startNewChat")
            isSavingSession = true
            Task { await saveCurrentSessionWithoutAISummary() }
        }
        
        messages.removeAll()
        sessionStartTime = Date()
        currentSessionId = nil
        
        Task {
            await StreamingAPIManager.shared.clearHistory()
        }
    }
    
    private func saveCurrentSessionWithoutAISummary() async {
        guard !messages.isEmpty else {
            await MainActor.run { isSavingSession = false }
            return
        }
        let currentContent = messages.map { $0.content }.joined(separator: "\n")
        let lastSession = ChatHistoryManager.shared.chatSessions.last
        let lastContent = lastSession?.messages.map { $0.content }.joined(separator: "\n") ?? ""
        if currentContent == lastContent {
            await MainActor.run { isSavingSession = false }
            return // 内容未变，不保存
        }
        let session = ChatSession(
            id: currentSessionId ?? UUID(),
            title: "新对话",
            summary: "暂无摘要",
            startTime: sessionStartTime,
            endTime: Date(),
            messages: messages
        )
        ChatHistoryManager.shared.upsertChatSession(session)
        await MainActor.run {
            isSavingSession = false
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingSaveSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSavingSession = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showingSaveSuccess = false
                    }
                }
            }
        }
    }
    
    private func saveCurrentSessionIfChanged() async {
        guard !messages.isEmpty else { return }
        let currentContent = messages.map { $0.content }.joined(separator: "\n")
        let lastSession = ChatHistoryManager.shared.chatSessions.last
        let lastContent = lastSession?.messages.map { $0.content }.joined(separator: "\n") ?? ""
        if currentContent == lastContent {
            return // 内容未变，不保存也不生成摘要
        }
            let (title, summary) = await ChatHistoryManager.shared.generateSummaryAndTitle(for: messages)
            let session = ChatSession(
                id: currentSessionId ?? UUID(),
                title: title,
                summary: summary,
                startTime: sessionStartTime,
                endTime: Date(),
                messages: messages
            )
        ChatHistoryManager.shared.upsertChatSession(session)
            await MainActor.run {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingSaveSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSavingSession = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showingSaveSuccess = false
                    }
                }
            }
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
    
    private func archiveCurrentSession() {
        guard let id = currentSessionId else { return }
        if var session = ChatHistoryManager.shared.chatSessions.first(where: { $0.id == id }) {
            var archivedSession = session
            archivedSession.isArchived = true
            ChatHistoryManager.shared.upsertChatSession(archivedSession)
        }
        messages.removeAll()
        currentSessionId = nil
        sessionStartTime = Date()
    }
    
    private var currentSessionTitle: String {
        if let id = currentSessionId, let session = ChatHistoryManager.shared.chatSessions.first(where: { $0.id == id }) {
            return session.title
        }
        return "温柔陪伴你的每一天"
    }

    private var bottomInputBar: some View {
        HStack(spacing: 10) {
            micOrKeyboardButton
            if isTextInputActive {
                chatTextField
            }
            if !isTextInputActive {
                voiceButton
            }
            sendButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 2)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    // 新增存档指定会话方法
    private func archiveSession(_ session: ChatSession) {
        var archivedSession = session
        archivedSession.isArchived = true
        ChatHistoryManager.shared.upsertChatSession(archivedSession)
    }

    private var micOrKeyboardButton: some View {
        Button(action: {
            if isListening { stopListening() }
            isTextInputActive.toggle()
            if isTextInputActive { isTextFieldFocused = true }
        }) {
            Image(systemName: isTextInputActive ? "mic" : "keyboard")
                .font(.system(size: 24))
        }
    }

    private var chatTextField: some View {
        TextField("说出你的心事或输入文字…", text: $textInput)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .font(.system(size: 16))
            .focused($isTextFieldFocused)
            .frame(minHeight: 36)
    }

    private var sendButton: some View {
        Button(action: {
            if !textInput.isEmpty { sendTextMessage() }
        }) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(textInput.isEmpty ? .gray : Color(red: 255/255, green: 159/255, blue: 10/255))
        }
        .disabled(textInput.isEmpty)
    }

    /// 检查并朗读最新AI消息
    private func speakLatestAImessageIfNeeded(messages: [ChatMessage]) {
        print("[DEBUG] 检查AI消息朗读触发: \(messages.last?.content ?? "nil") | isUser: \(messages.last?.isUser ?? true) | lastId: \(messages.last?.id.uuidString ?? "nil") | 已朗读: \(lastSpokenMessageId?.uuidString ?? "nil")")
        guard let last = messages.last, !last.isUser, last.id != lastSpokenMessageId, !last.content.isEmpty else {
            print("[DEBUG] 不满足朗读条件，跳过TTS"); return }
        let language = detectLanguage(for: last.content)
        print("[DEBUG] 调用TTS朗读: \(last.content) | language: \(language)")
        ttsManager.speak(text: last.content, language: language, utteranceId: last.id)
        lastSpokenMessageId = last.id
    }

    /// 简单语言检测（可扩展更复杂的检测）
    private func detectLanguage(for text: String) -> String {
        if text.range(of: "[\\u4E00-\\u9FFF]", options: .regularExpression) != nil {
            print("[DEBUG] 检测到中文，使用zh-CN")
            return "zh-CN"
        } else {
            print("[DEBUG] 未检测到中文，使用en-US")
            return "en-US"
        }
    }

    // 拆分底部TTS提示条，避免表达式过于复杂导致编译器报错
    private var ttsStatusBar: some View {
        Group {
            if ttsManager.isSpeaking || ttsManager.isPaused {
                HStack(spacing: 10) {
                    Image(systemName: ttsManager.isPaused ? "play.circle.fill" : "waveform.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(ttsManager.isPaused ? .gray : .orange)
                        .scaleEffect(ttsManager.isPaused ? 1.0 : 1.15)
                        .animation(.easeInOut(duration: 0.3), value: ttsManager.isPaused)
                    Text(ttsManager.isPaused ? "已暂停，点击继续" : "AI正在朗读，点击暂停")
                        .foregroundColor(.orange)
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    ttsWaveformBar
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(color: .orange.opacity(0.12), radius: 8, x: 0, y: 2)
                .padding(.bottom, 6)
                .padding(.horizontal, 24)
                .onTapGesture {
                    if ttsManager.isPaused {
                        ttsManager.continueSpeaking()
                    } else {
                        ttsManager.pauseSpeaking()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var ttsWaveformBar: some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { i in
                Capsule()
                    .fill(Color.orange)
                    .opacity(ttsManager.isPaused ? 0.18 : 0.35)
                    .frame(width: 2, height: 12 + 16 * waveformHeights[i])
            }
        }
        .frame(height: 28)
        .onAppear { startWaveformAnimation() }
        .onDisappear { stopWaveformAnimation() }
    }

    private func startWaveformAnimation() {
        stopWaveformAnimation()
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { _ in
            if ttsManager.isSpeaking && !ttsManager.isPaused {
                withAnimation(.easeInOut(duration: 0.16)) {
                    waveformHeights = waveformHeights.map { _ in CGFloat.random(in: 0.2...1.0) }
                }
            }
        }
    }

    private func stopWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = nil
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

// MARK: - 右侧圆角Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = 28.0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 
