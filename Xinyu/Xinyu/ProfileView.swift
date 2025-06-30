import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var isEditing = false
    
    // 编辑状态的临时变量
    @State private var editNickname = ""
    @State private var editGender: Gender = .notSpecified
    @State private var editBirthday = Date()
    @State private var editOccupation: String = ""
    @State private var editMBTIType: String = ""
    
    // 头像选择相关
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    // 日期格式化
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.doesRelativeDateFormatting = false
        return formatter
    }()
    
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
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1),
                    Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // 头像区域
                    VStack(spacing: 10) {
                        // 头像
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            }
                            
                            // 编辑模式下显示修改按钮
                            if isEditing {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            showingImagePicker = true
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(red: 255/255, green: 159/255, blue: 10/255))
                                                    .frame(width: 36, height: 36)
                                                
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .offset(x: 8, y: 8)
                                    }
                                }
                                .frame(width: 110, height: 110)
                            }
                        }
                        .padding(.bottom, 5)
                        
                        // 昵称
                        if isEditing {
                            TextField("请输入昵称", text: $editNickname)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text(profileManager.userProfile.nickname)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.top, 30)
                    
                    // 个人信息卡片
                    VStack(spacing: 5) {
                        Text("个人信息")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        VStack(spacing: 0) {
                            // 性别
                            profileItem(title: "性别") {
                                if isEditing {
                                    Picker("性别", selection: $editGender) {
                                        ForEach(Gender.allCases, id: \.self) { gender in
                                            Text(gender.description).tag(gender)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .padding(.horizontal)
                                } else {
                                    Text(profileManager.userProfile.gender.description)
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            // 生日
                            profileItem(title: "生日") {
                                if isEditing {
                                    DatePicker(
                                        "",
                                        selection: $editBirthday,
                                        displayedComponents: .date
                                    )
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "zh_CN"))
                                } else {
                                    Text(dateFormatter.string(from: profileManager.userProfile.birthday))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            // 职业
                            profileItem(title: "职业") {
                                if isEditing {
                                    Picker("职业", selection: $editOccupation) {
                                        ForEach(occupations, id: \.self) { occupation in
                                            Text(occupation).tag(occupation)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(.black)
                                } else {
                                    Text(profileManager.userProfile.occupation)
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            // MBTI类型
                            profileItem(title: "MBTI") {
                                if isEditing {
                                    Picker("MBTI", selection: $editMBTIType) {
                                        ForEach(mbtiTypes, id: \.self) { type in
                                            Text(type).tag(type)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(.black)
                                } else {
                                    Text(profileManager.userProfile.mbtiType)
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            // 注册日期（不可编辑）
                            profileItem(title: "注册日期") {
                                Text(dateFormatter.string(from: Date()))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal, 15)
                        .padding(.top, 5)
                    }
                    
                    // 编辑/保存按钮
                    Button(action: {
                        if isEditing {
                            // 保存修改
                            saveChanges()
                        }
                        
                        withAnimation {
                            isEditing.toggle()
                            
                            if isEditing {
                                // 初始化编辑数据
                                editNickname = profileManager.userProfile.nickname
                                editGender = profileManager.userProfile.gender
                                editBirthday = profileManager.userProfile.birthday
                                editOccupation = profileManager.userProfile.occupation
                                editMBTIType = profileManager.userProfile.mbtiType
                            }
                        }
                    }
                    ) {
                        HStack {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                            Text(isEditing ? "保存修改" : "编辑信息")
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 255/255, green: 159/255, blue: 10/255))
                        )
                    }
                    .padding(.top, 10)
                    
                    // 如果正在编辑，显示取消按钮
                    if isEditing {
                        Button(action: {
                            withAnimation {
                                isEditing = false
                            }
                        }) {
                            Text("取消")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 255/255, green: 159/255, blue: 10/255), lineWidth: 2)
                                )
                        }
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
        }
        .navigationTitle("个人资料")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: {
            loadProfileImage()
            // 初始化编辑数据
            editNickname = profileManager.userProfile.nickname
            editGender = profileManager.userProfile.gender
            editBirthday = profileManager.userProfile.birthday
            editOccupation = profileManager.userProfile.occupation
            editMBTIType = profileManager.userProfile.mbtiType
        })
    }
    
    // 保存修改
    private func saveChanges() {
        profileManager.updateProfile(
            nickname: editNickname,
            gender: editGender,
            birthday: editBirthday,
            occupation: editOccupation,
            mbtiType: editMBTIType
        )
        
        // 保存头像
        if let uiImage = profileImage {
            if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
                saveProfileImageToUserDefaults(imageData: imageData)
            }
        }
    }
    
    // 载入图片
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = inputImage
    }
    
    // 加载用户头像
    private func loadProfileImage() {
        if let imageData = UserDefaults.standard.data(forKey: "profileImage") {
            if let uiImage = UIImage(data: imageData) {
                profileImage = uiImage
            }
        }
    }
    
    // 保存头像到 UserDefaults
    private func saveProfileImageToUserDefaults(imageData: Data) {
        UserDefaults.standard.set(imageData, forKey: "profileImage")
    }
    
    // 自定义个人信息项
    private func profileItem<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            content()
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    guard let self = self else { return }
                    if let uiImage = image as? UIImage {
                        Task { @MainActor in
                            self.parent.image = uiImage
                        }
                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
} 