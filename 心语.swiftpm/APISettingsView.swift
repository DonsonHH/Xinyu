import SwiftUI

struct APISettingsView: View {
    @AppStorage("apiKey") private var apiKey: String = "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"
    @AppStorage("apiModel") private var selectedModel: String = "gpt-4o-mini"
    @AppStorage("temperature") private var temperature: Double = 0.7
    @AppStorage("maxTokens") private var maxTokens: Int = 2000
    @State private var showingSavedAlert = false
    
    let availableModels = ["gpt-4o-mini"]
    
    var body: some View {
        Form {
            Section(header: Text("API 配置")) {
                SecureField("API Key", text: $apiKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Picker("模型", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            }
            
            Section(header: Text("生成参数")) {
                VStack {
                    HStack {
                        Text("温度")
                        Spacer()
                        Text(String(format: "%.1f", temperature))
                    }
                    Slider(value: $temperature, in: 0...1, step: 0.1)
                }
                
                Stepper("最大 Token 数: \(maxTokens)", value: $maxTokens, in: 100...4000, step: 100)
            }
            
            Section {
                Button(action: {
                    saveSettings()
                }) {
                    Text("保存设置")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.orange)
            }
        }
        .navigationTitle("API 设置")
        .interactiveDismissDisabled(false)
        .alert("保存成功", isPresented: $showingSavedAlert) {
            Button("确定", role: .cancel) { }
        }
    }
    
    private func saveSettings() {
        // 设置已通过 @AppStorage 自动保存
        showingSavedAlert = true
    }
}

struct APISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            APISettingsView()
        }
    }
} 
