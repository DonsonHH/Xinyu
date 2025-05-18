import SwiftUI

struct SettingsView: View {
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