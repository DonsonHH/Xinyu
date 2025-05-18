import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profileManager = UserProfileManager.shared
    @Binding var isPresented: Bool
    
    // 表单状态
    @State private var nickname = ""
    @State private var selectedGender: Gender = .notSpecified
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var selectedOccupation: String = ""
    @State private var selectedMBTIType: String = ""
    @State private var showMBTITest = false
    @State private var currentQuestionIndex = 0
    @State private var answers: [Int] = Array(repeating: 0, count: 20)
    
    // 验证状态
    @State private var showNicknameError = false
    @State private var showOccupationError = false
    @State private var isFormValid = false
    
    // 当前页码
    @State private var currentPage = 0
    
    // 职业列表
    private let occupations = [
        "请选择...",
        "学生",
        "教师",
        "医生",
        "工程师",
        "设计师",
        "程序员",
        "销售",
        "管理",
        "自由职业",
        "其他"
    ]
    
    // MBTI类型列表
    private let mbtiTypes = [
        "请选择...",
        "INTJ", "INTP", "ENTJ", "ENTP",
        "INFJ", "INFP", "ENFJ", "ENFP",
        "ISTJ", "ISFJ", "ESTJ", "ESFJ",
        "ISTP", "ISFP", "ESTP", "ESFP"
    ]
    
    // MBTI测试题目
    private let mbtiQuestions = [
        "在社交场合中，你更倾向于：",
        "在做决定时，你更看重：",
        "你更喜欢的工作方式是：",
        "在压力下，你倾向于：",
        "你更喜欢的学习方式是：",
        "在团队中，你更倾向于：",
        "面对问题时，你更倾向于：",
        "你更喜欢的环境是：",
        "在做计划时，你更倾向于：",
        "在沟通中，你更注重：",
        "你更喜欢的信息类型是：",
        "在空闲时间，你更倾向于：",
        "你更看重的是：",
        "在解决问题时，你更倾向于：",
        "你更喜欢的工作环境是：",
        "在做决定时，你更倾向于：",
        "你更喜欢的学习环境是：",
        "在团队合作中，你更倾向于：",
        "面对变化时，你更倾向于：",
        "你更看重的是："
    ]
    
    // MBTI选项
    private let mbtiOptions = [
        ["主动与他人交流", "等待他人主动交流"],
        ["逻辑和客观事实", "个人价值观和感受"],
        ["按计划有序进行", "灵活随机应变"],
        ["寻求外部支持", "独立思考解决"],
        ["通过实践学习", "通过理论学习"],
        ["积极参与讨论", "倾听他人意见"],
        ["分析具体细节", "关注整体概念"],
        ["热闹的社交场合", "安静的独处空间"],
        ["制定详细计划", "保持灵活开放"],
        ["表达自己的想法", "理解他人的想法"],
        ["具体的事实数据", "抽象的概念理论"],
        ["参加社交活动", "独自放松休息"],
        ["效率和结果", "过程和体验"],
        ["分析问题原因", "寻找解决方案"],
        ["结构化的环境", "自由的环境"],
        ["收集更多信息", "快速做出决定"],
        ["小组讨论学习", "独自学习"],
        ["领导团队", "配合团队"],
        ["适应新变化", "保持原有方式"],
        ["完成任务目标", "享受过程体验"]
    ]
    
    // 日期格式化
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.2),
                    Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 标题
                Text(showMBTITest ? "MBTI 人格测试" : "让我们开始吧")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    .padding(.top, 40)
                
                Text(showMBTITest ? "请回答以下问题，帮助我们了解您的性格特征" : "请填写一些基本信息帮助我们提供更好的服务")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
                
                // 内容区域
                ZStack {
                    if showMBTITest {
                        mbtiTestView
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    } else {
                        // 原有的页面内容
                        if currentPage == 0 {
                            nicknameView
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        } else if currentPage == 1 {
                            genderView
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        } else if currentPage == 2 {
                            birthdayView
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        } else if currentPage == 3 {
                            occupationView
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        } else if currentPage == 4 {
                            mbtiSelectionView
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                
                // 底部导航
                if !showMBTITest {
                    HStack {
                        // 上一页按钮
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                Text("上一步")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(red: 255/255, green: 159/255, blue: 10/255), lineWidth: 2)
                                    )
                            }
                        } else {
                            Spacer().frame(width: 100)
                        }
                        
                        Spacer()
                        
                        // 下一页按钮
                        if currentPage < 4 {
                            Button(action: {
                                withAnimation {
                                    validateAndProceed()
                                }
                            }) {
                                Text("下一步")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(isCurrentPageValid() ? Color(red: 255/255, green: 159/255, blue: 10/255) : Color.gray)
                                    )
                            }
                            .disabled(!isCurrentPageValid())
                        } else {
                            Button(action: {
                                completeOnboarding()
                            }) {
                                Text("完成")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(isCurrentPageValid() ? Color(red: 255/255, green: 159/255, blue: 10/255) : Color.gray)
                                    )
                            }
                            .disabled(!isCurrentPageValid())
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
        .onAppear {
            validateForm()
        }
    }
    
    // MBTI选择页面
    private var mbtiSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("您的MBTI类型")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                .padding(.top, 40)
            
            Text("如果您知道自己的MBTI类型，请直接选择；如果不知道，可以点击下方按钮进行测试")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            Picker("MBTI", selection: $selectedMBTIType) {
                ForEach(mbtiTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.black)
            .onChange(of: selectedMBTIType) { _ in
                validateForm()
            }
            
            Button(action: {
                withAnimation {
                    showMBTITest = true
                }
            }) {
                Text("进行MBTI测试")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 255/255, green: 159/255, blue: 10/255))
                    .cornerRadius(10)
            }
            
            Spacer()
        }
    }
    
    // MBTI测试页面
    private var mbtiTestView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 进度条
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(mbtiQuestions.count))
                .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 255/255, green: 159/255, blue: 10/255)))
                .padding(.top, 20)
            
            Text("问题 \(currentQuestionIndex + 1)/\(mbtiQuestions.count)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            Text(mbtiQuestions[currentQuestionIndex])
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                .padding(.top, 10)
            
            VStack(spacing: 15) {
                ForEach(0..<2) { index in
                    Button(action: {
                        answers[currentQuestionIndex] = index + 1
                        if currentQuestionIndex < mbtiQuestions.count - 1 {
                            // 添加延迟
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    currentQuestionIndex += 1
                                }
                            }
                        } else {
                            calculateMBTI()
                        }
                    }) {
                        Text(mbtiOptions[currentQuestionIndex][index])
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                }
            }
            
            // 添加返回上一题按钮
            if currentQuestionIndex > 0 {
                Button(action: {
                    withAnimation {
                        currentQuestionIndex -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("返回上一题")
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 255/255, green: 159/255, blue: 10/255), lineWidth: 2)
                    )
                }
                .padding(.top, 20)
            }
            
            Spacer()
        }
    }
    
    // 昵称页面
    private var nicknameView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("请输入您的昵称")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                .padding(.top, 40)
            
            Text("这将是我们称呼您的方式")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            TextField("请输入昵称", text: $nickname)
                .font(.system(size: 18, design: .rounded))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .onChange(of: nickname) { _ in
                    showNicknameError = nickname.isEmpty
                    validateForm()
                }
            
            if showNicknameError {
                Text("请输入您的昵称")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
    }
    
    // 性别页面
    private var genderView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("请选择您的性别")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                .padding(.top, 40)
            
            Text("这有助于我们为您提供更个性化的服务")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            ForEach(Gender.allCases, id: \.self) { gender in
                Button(action: {
                    selectedGender = gender
                    validateForm()
                }) {
                    HStack {
                        Text(gender.description)
                            .font(.system(size: 18, design: .rounded))
                            .foregroundColor(selectedGender == gender ? .white : .black)
                        
                        Spacer()
                        
                        if selectedGender == gender {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedGender == gender ? 
                                  Color(red: 255/255, green: 159/255, blue: 10/255) : 
                                  Color.gray.opacity(0.1))
                    )
                }
            }
            
            Spacer()
        }
    }
    
    // 生日页面
    private var birthdayView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("请选择您的生日")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                .padding(.top, 40)
            
            Text("这有助于我们更好地了解您")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            DatePicker(
                "出生日期",
                selection: $birthday,
                displayedComponents: .date
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .onChange(of: birthday) { _ in
                validateForm()
            }
            
            Spacer()
        }
    }
    
    // 职业页面
    private var occupationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("请选择您的职业")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                .padding(.top, 40)
            
            Text("这将帮助我们更好地了解您")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            Picker("职业", selection: $selectedOccupation) {
                ForEach(occupations, id: \.self) { occupation in
                    Text(occupation).tag(occupation)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.black)
            .onChange(of: selectedOccupation) { _ in
                validateForm()
            }
            
            Spacer()
        }
    }
    
    // 验证当前页面
    private func isCurrentPageValid() -> Bool {
        switch currentPage {
        case 0:
            return !nickname.isEmpty
        case 1:
            return selectedGender != .notSpecified
        case 2:
            return true
        case 3:
            return !selectedOccupation.isEmpty && selectedOccupation != "请选择..."
        case 4:
            return !selectedMBTIType.isEmpty && selectedMBTIType != "请选择..."
        default:
            return false
        }
    }
    
    // 验证所有表单
    private func validateForm() {
        isFormValid = isCurrentPageValid()
    }
    
    // 验证并前进到下一页
    private func validateAndProceed() {
        if isCurrentPageValid() {
            withAnimation {
                currentPage += 1
            }
        }
    }
    
    // 完成引导过程
    private func completeOnboarding() {
        profileManager.updateProfile(
            nickname: nickname,
            gender: selectedGender,
            birthday: birthday,
            occupation: selectedOccupation,
            mbtiType: selectedMBTIType
        )
        profileManager.completeOnboarding()
        withAnimation {
            isPresented = false
        }
    }
    
    private func calculateMBTI() {
        var type = ""
        
        // E/I
        let eiScore = answers[0...4].filter { $0 == 1 }.count
        type += eiScore > 2 ? "E" : "I"
        
        // S/N
        let snScore = answers[5...9].filter { $0 == 1 }.count
        type += snScore > 2 ? "S" : "N"
        
        // T/F
        let tfScore = answers[10...14].filter { $0 == 1 }.count
        type += tfScore > 2 ? "T" : "F"
        
        // J/P
        let jpScore = answers[15...19].filter { $0 == 1 }.count
        type += jpScore > 2 ? "J" : "P"
        
        selectedMBTIType = type
        showMBTITest = false
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
    }
} 