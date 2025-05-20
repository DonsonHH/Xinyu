import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("apiDomain") private var apiDomain = "https://api.openai.com"
    @AppStorage("apiPath") private var apiPath = "/v1/chat/completions"
    @AppStorage("apiModel") private var apiModel = "gpt-4o-mini"
    @AppStorage("selectedVoice") private var selectedVoice = "zh-CN"
    @AppStorage("inputLanguage") private var inputLanguage = "auto"
    @AppStorage("backgroundChat") private var backgroundChat = false
    
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
                    Text("语音设置")
                        .font(.headline)
                }
            }
            
            NavigationLink(destination: APISettingsView()) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("API 设置")
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
        .listStyle(InsetGroupedListStyle())
        .interactiveDismissDisabled(false)
    }
}

struct VoiceSettingsView: View {
    @AppStorage("selectedVoice") private var selectedVoice = "zh-CN"
    @AppStorage("inputLanguage") private var inputLanguage = "auto"
    @AppStorage("backgroundChat") private var backgroundChat = false
    
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
            Section(header: Text("AI语音设置"), footer: Text("选择AI回复时使用的语音，选择后会自动播放示例")) {
                Picker("AI语音", selection: $selectedVoice) {
                    ForEach(availableVoices, id: \.0) { voice in
                        Text(voice.1).tag(voice.0)
                    }
                }
                .pickerStyle(.navigationLink)
                .onChange(of: selectedVoice) { newValue in
                    playSampleVoice(newValue)
                }
            }
            
            Section(header: Text("输入语言设置"), footer: Text("选择语音输入时使用的语言，设置为自动检测时会根据内容自动识别语言")) {
                Picker("输入语言", selection: $inputLanguage) {
                    ForEach(inputLanguages, id: \.0) { language in
                        Text(language.1).tag(language.0)
                    }
                }
                .pickerStyle(.navigationLink)
            }
            
            Section(header: Text("其他设置"), footer: Text("开启后台对话后，即使应用在后台运行也能继续对话")) {
                Toggle("后台对话", isOn: $backgroundChat)
                    .tint(Color(red: 255/255, green: 159/255, blue: 10/255))
            }
        }
        .navigationTitle("语音设置")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(InsetGroupedListStyle())
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
        .interactiveDismissDisabled(false)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("隐私政策")
                    .font(.title)
                    .bold()
                
                Text("我们重视您的隐私。本应用不会收集或存储您的个人信息。")
                    .padding(.bottom)
                
                Text("数据使用")
                    .font(.headline)
                Text("所有语音数据仅在本地处理，不会上传到任何服务器。")
                
                Text("权限说明")
                    .font(.headline)
                Text("本应用需要麦克风权限用于语音输入，需要扬声器权限用于语音输出。")
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .interactiveDismissDisabled(false)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.orange)
            
            Text("心语")
                .font(.title)
                .bold()
            
            Text("版本 1.0.0")
                .foregroundColor(.gray)
            
            Text("用声音传递心意")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .navigationTitle("关于")
        .interactiveDismissDisabled(false)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
} 
