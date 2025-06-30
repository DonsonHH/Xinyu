import SwiftUI
import AVFoundation
import HealthKit
import Speech
import ARKit

struct EmotionFeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var detectedEmotion: String = "加载中..." // 默认显示加载中
    @State private var emotionScore: Int = 0 // 默认分数
    @State private var emotionDescription: String = "正在分析您的情绪状态..." // 默认描述
    @State private var isCameraActive: Bool = false // 默认关闭相机
    @State private var hrvValue: Double = Double.random(in: 20...80) // 随机HRV值
    @State private var stressLevel: String = "未知"
    @State private var isRecordingVoice: Bool = false
    @State private var voiceText: String = ""
    @State private var textInput: String = ""
    @State private var recordingMode: RecordingMode = .none
    @State private var emotionRecords: [EmotionRecord] = []
    @State private var showingTextInput: Bool = false
    @State private var isLoading: Bool = true // 添加加载状态
    @State private var isRotating: Bool = false // 添加旋转动画状态
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioEngine: AVAudioEngine?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var speechRecognizer: SFSpeechRecognizer?
    @State private var isRecognizing: Bool = false
    @State private var waveformAmplitude: CGFloat = 0.0
    @State private var cameraPermissionGranted: Bool = false
    @State private var showCameraPermissionAlert: Bool = false
    @State private var cameraOpacity: Double = 0
    
    // 使用 ThemeManager 管理全局主题
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // 定义录音模式枚举
    enum RecordingMode {
        case none, voice, text, face
    }
    
    // 定义情绪记录结构
    struct EmotionRecord: Identifiable {
        let id = UUID()
        let timestamp: Date
        let emotion: String
        let content: String
        let hrvValue: Double
        let stressLevel: String
    }
    
    // 不同情绪对应的背景颜色
    private func backgroundColorForEmotion() -> Color {
        switch detectedEmotion {
        case "平静":
            return Color.blue.opacity(0.2)
        case "开心":
            return Color.yellow.opacity(0.3)
        case "悲伤":
            return Color.indigo.opacity(0.2)
        case "生气":
            return Color.red.opacity(0.2)
        case "焦虑":
            return Color.purple.opacity(0.2)
        default:
            return Color.orange.opacity(0.1)
        }
    }
    
    // 波形动画视图
    struct WaveformView: View {
        let amplitude: CGFloat
        @State private var phase: CGFloat = 0
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // 第一层波形
                    WaveformLayer(
                        amplitude: amplitude * 1.2,
                        frequency: 2.0,
                        phase: phase,
                        color: .orange.opacity(0.8)
                    )
                    
                    // 第二层波形
                    WaveformLayer(
                        amplitude: amplitude * 0.8,
                        frequency: 3.0,
                        phase: phase + 0.5,
                        color: .orange.opacity(0.6)
                    )
                    
                    // 第三层波形
                    WaveformLayer(
                        amplitude: amplitude * 0.6,
                        frequency: 4.0,
                        phase: phase + 1.0,
                        color: .orange.opacity(0.4)
                    )
                }
                .frame(height: 60)
                .onAppear {
                    withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                        phase = .pi * 2
                    }
                }
            }
        }
    }
    
    // 单个波形层
    struct WaveformLayer: View {
        let amplitude: CGFloat
        let frequency: CGFloat
        let phase: CGFloat
        let color: Color
        
        var body: some View {
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midHeight = height / 2
                    let wavelength = width / frequency
                    
                    path.move(to: CGPoint(x: 0, y: midHeight))
                    
                    for x in stride(from: 0, through: width, by: 1) {
                        let relativeX = x / wavelength
                        let sine = sin(relativeX * .pi * 2 + phase)
                        let y = midHeight + sine * amplitude * midHeight
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 根据当前情绪变化的背景颜色
            themeManager.globalBackgroundColor
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 0.5), value: themeManager.globalBackgroundColor)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 返回按钮
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        Text("今日情绪反馈")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                    .padding()
                    
                    // HRV 状态显示
                    VStack(spacing: 10) {
                        Text("当前 HRV 状态")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.2f", hrvValue))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("压力水平: \(stressLevel)")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // 情绪记录方式选择
                    VStack(spacing: 15) {
                        Text("记录情绪")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                        Button(action: {
                                recordingMode = .voice
                                isRecordingVoice = true
                                showingTextInput = false
                                // 直接开始语音识别
                                startSpeechRecognition()
                            }) {
                                VStack {
                                    Image(systemName: "mic.fill")
                                        .font(.title)
                                    Text("语音")
                                        .font(.caption)
                                }
                                .foregroundColor(isRecordingVoice ? .orange : .gray)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(isRecordingVoice ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                            }
                            
                            Button(action: {
                                recordingMode = .text
                                showingTextInput = true
                                isRecordingVoice = false
                            }) {
                                VStack {
                                    Image(systemName: "text.bubble.fill")
                                        .font(.title)
                                    Text("文本")
                                        .font(.caption)
                                }
                                .foregroundColor(showingTextInput ? .orange : .gray)
                    .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(showingTextInput ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                            }
                            
                        Button(action: {
                                recordingMode = .face
                            isCameraActive.toggle()
                        }) {
                                VStack {
                                    Image(systemName: "face.smiling.fill")
                                        .font(.title)
                                    Text("人脸")
                                        .font(.caption)
                                }
                                .foregroundColor(isCameraActive ? .orange : .gray)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(isCameraActive ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                            }
                        }
                        
                        // 添加游戏卡片
                        NavigationLink(destination: NMOGameView()) {
                            VStack(spacing: 15) {
                                HStack {
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading) {
                                        Text("NMO 小游戏")
                                            .font(.headline)
                                            .foregroundColor(.orange)
                                        
                                        Text("放松心情，开始游戏")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            )
                            .padding(.horizontal)
                        }
                        
                        // 相机预览区域
                        if isCameraActive {
                            ZStack {
                                Rectangle()
                                    .fill(Color.black.opacity(0.8))
                                    .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 1.2)
                                    .cornerRadius(20)
                                    .opacity(cameraOpacity)
                                
                                if cameraPermissionGranted {
                                    CameraPreviewView()
                                        .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 1.2)
                                        .cornerRadius(20)
                                        .opacity(cameraOpacity)
                                } else {
                                VStack {
                                    Image(systemName: "face.smiling")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("实时情绪分析中...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    }
                                    .opacity(cameraOpacity)
                                }
                            }
                            .padding(.horizontal)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: isCameraActive)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.5)) {
                                    cameraOpacity = 1
                                }
                            }
                            .onDisappear {
                                cameraOpacity = 0
                            }
                        }
                        
                        // 语音录制状态显示
                        if isRecordingVoice {
                            VStack(spacing: 15) {
                                Text("正在录音...")
                                    .font(.system(size: 16))
                                .foregroundColor(.orange)
                                
                                // 波形动画
                                WaveformView(amplitude: waveformAmplitude)
                                    .frame(height: 60)
                                
                                // 停止录音按钮
                                Button(action: {
                                    stopSpeechRecognition()
                                }) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.system(size: 30))
                                    .foregroundColor(.orange)
                            }
                                
                                // 识别的文本显示
                                if !voiceText.isEmpty {
                                    Text(voiceText)
                                        .font(.system(size: 14))
                                .foregroundColor(.gray)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                .padding(.horizontal)
                                }
                                
                                // 保存按钮
                                if !voiceText.isEmpty {
                                    Button(action: {
                                        let record = EmotionRecord(
                                            timestamp: Date(),
                                            emotion: detectedEmotion,
                                            content: voiceText,
                                            hrvValue: hrvValue,
                                            stressLevel: stressLevel
                                        )
                                        emotionRecords.append(record)
                                        voiceText = ""
                                        isRecordingVoice = false
                                        recordingMode = .none
                                    }) {
                                        Text("保存")
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.orange)
                                            .cornerRadius(10)
                            }
                            .padding(.top, 10)
                                }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        }
                        
                        // 文本输入弹窗
                        if showingTextInput {
                            VStack {
                                TextField("输入你的情绪...", text: $textInput)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                .padding(.horizontal)
                            
                                Button(action: {
                                    if !textInput.isEmpty {
                                        let record = EmotionRecord(
                                            timestamp: Date(),
                                            emotion: detectedEmotion,
                                            content: textInput,
                                            hrvValue: hrvValue,
                                            stressLevel: stressLevel
                                        )
                                        emotionRecords.append(record)
                                        textInput = ""
                                        showingTextInput = false
                                        recordingMode = .none
                                    }
                                }) {
                                    Text("保存")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.orange)
                                        .cornerRadius(10)
                                }
                                .padding()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                    // 查看详细分析按钮
                    NavigationLink(destination: EmotionAnalysisView()) {
                            HStack {
                            Text("查看详细情绪分析")
                            .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                            .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showCameraPermissionAlert) {
            Alert(
                title: Text("需要相机权限"),
                message: Text("请在设置中允许访问相机以进行情绪分析"),
                primaryButton: .default(Text("去设置"), action: openSettings),
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .onAppear {
            // 启动加载动画
            isRotating = true
            
            // 5秒后更新情绪状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                isLoading = false
                isRotating = false
                updateRandomEmotion()
            }
            
            // 初始化全局背景颜色
            themeManager.setGlobalBackgroundColorForEmotion(detectedEmotion)
            
            // 请求 HealthKit 授权并获取 HRV 数据
            requestHealthKitAuthorization()
            fetchHRVData()
            
            // 请求麦克风和语音识别权限
            requestMicrophonePermission()
            requestSpeechRecognitionPermission()
            
            // 请求相机权限
            requestCameraPermission()
        }
        .onChange(of: detectedEmotion) { newEmotion in
            updateEmotionInfo(for: newEmotion)
            // 更新全局背景颜色
            themeManager.setGlobalBackgroundColorForEmotion(newEmotion)
        }
    }
    
    // 随机生成情绪
    private func updateRandomEmotion() {
        let emotions = ["平静", "开心", "悲伤", "生气", "焦虑"]
        detectedEmotion = emotions.randomElement() ?? "平静"
    }
    
    // 根据检测到的情绪更新信息
    private func updateEmotionInfo(for emotion: String) {
        switch emotion {
        case "平静":
            emotionScore = 75
            emotionDescription = "通过分析，你目前的情绪状态看起来平静。"
        case "开心":
            emotionScore = 90
            emotionDescription = "通过分析，你目前的情绪状态看起来非常开心！"
        case "悲伤":
            emotionScore = 40
            emotionDescription = "通过分析，你目前的情绪状态看起来有些悲伤。"
        case "生气":
            emotionScore = 30
            emotionDescription = "通过分析，你目前的情绪状态看起来有些愤怒。"
        case "焦虑":
            emotionScore = 50
            emotionDescription = "通过分析，你目前的情绪状态看起来有些焦虑。"
        default:
            emotionScore = 65
            emotionDescription = "通过分析，你目前的情绪状态看起来比较复杂。"
        }
    }
    
    // 请求 HealthKit 授权
    private func requestHealthKitAuthorization() {
        let healthStore = HKHealthStore()
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        healthStore.requestAuthorization(toShare: [], read: [hrvType]) { success, error in
            if success {
                print("HealthKit authorization granted")
            } else if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    // 获取 HRV 数据
    private func fetchHRVData() {
        let healthStore = HKHealthStore()
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, result, error in
            if let result = result, let average = result.averageQuantity() {
                let hrvValue = average.doubleValue(for: HKUnit.secondUnit(with: .milli))
                DispatchQueue.main.async {
                    self.hrvValue = hrvValue
                    self.updateStressLevel(hrv: hrvValue)
                }
            } else if let error = error {
                print("Error fetching HRV data: \(error.localizedDescription)")
            }
        }
        
        healthStore.execute(query)
    }
    
    // 根据 HRV 值更新压力水平
    private func updateStressLevel(hrv: Double) {
        if hrv > 50 {
            stressLevel = "低"
        } else if hrv > 30 {
            stressLevel = "中"
        } else {
            stressLevel = "高"
        }
    }
    
    // 请求麦克风权限
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Microphone permission granted")
            } else {
                print("Microphone permission denied")
            }
        }
    }
    
    // 请求语音识别权限
    private func requestSpeechRecognitionPermission() {
#if targetEnvironment(simulator)
    print("模拟器不支持语音识别功能")
#else
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Speech recognition authorized")
            case .denied:
                print("Speech recognition denied")
            case .restricted:
                print("Speech recognition restricted")
            case .notDetermined:
                print("Speech recognition not determined")
            @unknown default:
                print("Speech recognition unknown status")
            }
        }
#endif
    }
    
    // 开始语音识别
    private func startSpeechRecognition() {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN")), recognizer.isAvailable else {
            print("Speech recognizer is not available")
            return
        }
        
        speechRecognizer = recognizer
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        // 配置识别请求
        recognitionRequest.shouldReportPartialResults = true
        
        // 创建音频引擎
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            print("Unable to create audio engine")
            return
        }
        
        // 配置音频输入
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // 安装音频tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
            
            // 计算音频振幅
            let channelData = buffer.floatChannelData?[0]
            let frameLength = UInt32(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<Int(frameLength) {
                let sample = channelData?[i] ?? 0
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))
            DispatchQueue.main.async {
                // 增加振幅系数，使波形更加明显
                self.waveformAmplitude = CGFloat(rms * 15)
            }
        }
        
        // 启动音频引擎
        do {
            try audioEngine.start()
            isRecognizing = true
        } catch {
            print("Failed to start audio engine: \(error)")
            return
        }
        
        // 开始识别任务
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.voiceText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil {
                self.stopSpeechRecognition()
            }
        }
    }
    
    // 停止语音识别
    private func stopSpeechRecognition() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecognizing = false
        waveformAmplitude = 0
    }
    
    // 相机预览视图
    struct CameraPreviewView: UIViewRepresentable {
        func makeUIView(context: Context) -> UIView {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 1.2))
            let previewLayer = AVCaptureVideoPreviewLayer()
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            // 设置相机
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return view
            }
            
            session.addInput(input)
            previewLayer.session = session
            session.startRunning()
            
            return view
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {}
    }
    
    // 请求相机权限
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    if !granted {
                        self.showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    // 打开设置
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// 情绪选择按钮（仅用于演示）
struct EmotionButton: View {
    let emotion: String
    @Binding var currentEmotion: String
    
    var body: some View {
        Button(action: {
            withAnimation {
                currentEmotion = emotion
            }
        }) {
            Text(emotion)
                .font(.system(size: 14))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(currentEmotion == emotion ? Color.orange : Color.gray.opacity(0.2))
                )
                .foregroundColor(currentEmotion == emotion ? .white : .gray)
        }
    }
}

struct EmotionFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionFeedbackView()
    }
}

// 新增情绪分析页面
struct EmotionAnalysisView: View {
    @State private var selectedTab: Int = 0
    @State private var hrvHistory: [Double] = {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // 计算从昨天同一时间到现在的总分钟数
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let totalMinutes = calendar.dateComponents([.minute], from: yesterday, to: now).minute ?? 0
        
        // 生成更合理的HRV数据
        var data: [Double] = []
        var lastValue = Double.random(in: 40...60) // 初始值在正常范围内
        
        // 每30分钟一个数据点
        for minute in stride(from: 0, through: totalMinutes, by: 30) {
            let timeFactor = {
                let hour = (minute / 60) % 24
                return hour < 6 ? 0.8 : // 凌晨较低
                       hour < 9 ? 1.2 : // 早晨较高
                       hour < 12 ? 1.0 : // 上午正常
                       hour < 14 ? 0.9 : // 中午略低
                       hour < 18 ? 1.1 : // 下午较高
                       hour < 21 ? 0.95 : // 晚上略低
                       0.85 // 深夜较低
            }()
            
            // 添加随机波动，但保持在合理范围内
            let variation = Double.random(in: -5...5)
            lastValue = max(20, min(80, lastValue * timeFactor + variation))
            data.append(lastValue)
        }
        return data
    }()
    @State private var currentEmotion: String = "平静"
    @State private var emotionScore: Int = 75
    @State private var emotionDescription: String = "通过分析，你目前的情绪状态看起来平静。"
    @State private var recommendedSongs: [(title: String, artist: String, cover: String)] = [
        ("起风了", "买辣椒也用券", "music_cover_1"),
        ("光年之外", "邓紫棋", "music_cover_2"),
        ("晴天", "周杰伦", "music_cover_3"),
        ("稻香", "周杰伦", "music_cover_4"),
        ("夜曲", "周杰伦", "music_cover_5")
    ]
    @State private var showingARGuide = false
    @State private var showCameraPermissionAlert = false
    
    // 生成时间标签
    private func generateTimeLabels() -> [String] {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return [
            formatter.string(from: yesterday),
            "12:00",
            "00:00",
            "12:00",
            formatter.string(from: now)
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 当前情绪卡片
                VStack(spacing: 15) {
                    Text("当前情绪")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(currentEmotion)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.bottom, 5)
                    
                    // 情绪分数环形进度条
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(emotionScore) / 100)
                            .stroke(
                                Color.orange,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(emotionScore)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.bottom, 5)
                    
                    Text(emotionDescription)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // HRV历史图表
                VStack(spacing: 15) {
                    Text("HRV 趋势")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    // 统计信息
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("平均值")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 4) {
                            Text("最高: \(String(format: "%.1f", hrvHistory.max() ?? 0))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 4) {
                            Text("最低: \(String(format: "%.1f", hrvHistory.min() ?? 0))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 5)
                    
                    // 折线图
                    LineChartView(
                        data: hrvHistory,
                        average: hrvHistory.reduce(0, +) / Double(hrvHistory.count),
                        max: hrvHistory.max() ?? 0,
                        min: hrvHistory.min() ?? 0
                    )
                    .frame(height: 200)
                    .padding(.horizontal)
                    
                    // 时间标签
                    HStack {
                        ForEach(generateTimeLabels(), id: \.self) { time in
                            Text(time)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            if time != generateTimeLabels().last {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // 今日总结
                VStack(spacing: 15) {
                    Text("今日总结")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // 情绪分析卡片
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.orange)
                                Text("情绪分析")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("根据您的HRV数据和情绪记录分析：")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 6, height: 6)
                                    Text("今日压力水平处于中等状态，建议适当放松")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                    Text("情绪波动较为平稳，但仍有提升空间")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text("建议通过以下方式调节情绪：")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // 情绪趋势卡片
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.blue)
                                Text("情绪趋势")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(spacing: 15) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("早晨")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("平静")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("中午")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("开心")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("现在")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("平静")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // 音乐推荐卡片
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundColor(.purple)
                                Text("推荐音乐")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(recommendedSongs, id: \.title) { song in
                                        Button(action: {
                                            if let url = URL(string: "qqmusic://") {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                ZStack {
                                                    // 默认封面背景
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [
                                                                    Color.purple.opacity(0.8),
                                                                    Color.blue.opacity(0.6)
                                                                ]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .frame(width: 160, height: 160)
                                                    
                                                    // 音乐图标
                                                    Image(systemName: "music.note")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.white.opacity(0.8))
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(song.title)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(.black)
                                                        .lineLimit(1)
                                                    
                                                    Text(song.artist)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.gray)
                                                        .lineLimit(1)
                                                }
                                                .padding(.horizontal, 4)
                                            }
                                            .frame(width: 160)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // 减压活动卡片组
                        VStack(spacing: 12) {
                            // 运动减压卡片
                            Button(action: {
                                if let url = URL(string: "keep://") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    // 左侧内容
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "figure.run")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                            
                                            Text("运动减压")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("瑜伽 · 冥想 · 慢跑")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    // 右侧装饰
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 255/255, green: 159/255, blue: 10/255),
                                            Color(red: 255/255, green: 149/255, blue: 0/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            
                            // 正念投影卡片
                            Button(action: {
                                startMindfulnessProjection()
                            }) {
                                HStack {
                                    // 左侧内容
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "person.fill.viewfinder")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                            
                                            Text("正念投影")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("AR冥想导师 · 实时呼吸引导")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    // 右侧装饰
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0/255, green: 122/255, blue: 255/255),
                                            Color(red: 0/255, green: 102/255, blue: 235/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .sheet(isPresented: $showingARGuide) {
                                ARMeditationGuideView()
                            }
                            
                            // 冥想训练卡片
                            Button(action: {
                                if let url = URL(string: "keep://") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    // 左侧内容
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "brain.head.profile")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                            
                                            Text("冥想训练")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("专注当下 · 觉察情绪")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    // 右侧装饰
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 175/255, green: 82/255, blue: 222/255),
                                            Color(red: 155/255, green: 62/255, blue: 202/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            
                            // AI倾诉对话卡片
                            NavigationLink(destination: VoiceInteractionView()) {
                                HStack {
                                    // 左侧内容
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                            
                                            Text("AI倾诉对话")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("语音 · 文字 · 表情")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    // 右侧装饰
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 52/255, green: 199/255, blue: 89/255),
                                            Color(red: 32/255, green: 179/255, blue: 69/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("情绪分析")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showCameraPermissionAlert) {
            Alert(
                title: Text("需要相机权限"),
                message: Text("请在设置中允许访问相机以使用AR正念投影功能"),
                primaryButton: .default(Text("去设置"), action: openSettings),
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
    
    // 添加正念投影相关方法
    private func startMindfulnessProjection() {
        // 检查相机权限
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // 已授权，启动 AR 正念投影
            showingARGuide = true
        case .notDetermined:
            // 请求权限
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingARGuide = true
                    } else {
                        self.showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // 显示权限提示
            showCameraPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// 修改折线图视图
struct LineChartView: View {
    let data: [Double]
    let average: Double
    let max: Double
    let min: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景网格
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Divider()
                            .background(Color.gray.opacity(0.2))
                        Spacer()
                    }
                    Divider()
                        .background(Color.gray.opacity(0.2))
                }
                
                // 渐变背景
                Path { path in
                    let width = geometry.size.width / CGFloat(data.count - 1)
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    
                    for index in 0..<data.count {
                        let x = width * CGFloat(index)
                        let y = height * (1 - CGFloat(data[index] / 100))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    // 闭合路径到底部
                    path.addLine(to: CGPoint(x: geometry.size.width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.2),
                            Color.blue.opacity(0.1),
                            Color.blue.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // 平均值线
                Path { path in
                    let y = geometry.size.height * (1 - CGFloat(average / 100))
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                
                // 折线图
                Path { path in
                    let width = geometry.size.width / CGFloat(data.count - 1)
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(data[0] / 100))))
                    
                    for index in 1..<data.count {
                        let x = width * CGFloat(index)
                        let y = height * (1 - CGFloat(data[index] / 100))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue,
                            Color.blue.opacity(0.7)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                
                // 数据点
                ForEach(0..<data.count, id: \.self) { index in
                    let width = geometry.size.width / CGFloat(data.count - 1)
                    let height = geometry.size.height
                    let x = width * CGFloat(index)
                    let y = height * (1 - CGFloat(data[index] / 100))
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// AR冥想导师视图
struct ARMeditationGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isBreathing = false
    @State private var breathingPhase = 0 // 0: 吸气, 1: 保持, 2: 呼气
    @State private var breathingScale: CGFloat = 1.0
    @State private var showingGuide = true
    @State private var timer: Timer? = nil
    
    let breathingTexts = [
        "慢慢吸气，感受空气流入身体，带来新的能量……",
        "保持呼吸，感受身体的平静与安定……",
        "缓缓呼气，释放压力与疲惫，让心灵更加轻盈……"
    ]
    
    var body: some View {
        ZStack {
            // AR相机预览
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
            
            // 冥想导师3D模型和动画
            if showingGuide {
                VStack {
                    Spacer()
                    
                    // 呼吸动画
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .scaleEffect(breathingScale)
                        .animation(
                            Animation.easeInOut(duration: 4)
                                .repeatForever(autoreverses: true),
                            value: breathingScale
                        )
                        .onAppear {
                            breathingScale = 1.5
                            startBreathingCycle()
                        }
                        .onDisappear {
                            timer?.invalidate()
                        }
                    
                    // 呼吸指导文本，字体大小随圆形缩放
                    Text(breathingText)
                        .font(.system(size: 22 * breathingScale, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                        .animation(.easeInOut(duration: 0.3), value: breathingScale)
                }
            }
            
            // 顶部控制栏
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingGuide.toggle()
                    }) {
                        Image(systemName: showingGuide ? "eye.slash.fill" : "eye.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    private var breathingText: String {
        breathingTexts[breathingPhase]
    }
    
    private func startBreathingCycle() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1.0)) {
                    breathingPhase = (breathingPhase + 1) % 3
                    // 让圆和文字同步缩放
                    switch breathingPhase {
                    case 0: // 吸气
                        breathingScale = 1.5
                    case 1: // 保持
                        breathingScale = 1.2
                    case 2: // 呼气
                        breathingScale = 0.9
                    default:
                        breathingScale = 1.0
                    }
                }
            }
        }
    }
}

// AR视图容器
struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
} 