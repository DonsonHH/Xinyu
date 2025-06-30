import Foundation
import SwiftUI
import Combine

// 用户配置文件模型
struct UserProfile: Codable {
    var nickname: String
    var gender: Gender
    var birthday: Date
    var occupation: String
    var mbtiType: String
    var hasCompletedOnboarding: Bool
    
    init(nickname: String = "", gender: Gender = .notSpecified, birthday: Date = Date(), occupation: String = "", mbtiType: String = "", hasCompletedOnboarding: Bool = false) {
        self.nickname = nickname
        self.gender = gender
        self.birthday = birthday
        self.occupation = occupation
        self.mbtiType = mbtiType
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "男"
    case female = "女"
    case notSpecified = "未指定"
    
    var description: String {
        return self.rawValue
    }
}

// 心情记录结构
struct MoodEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let mood: String
    let emotion: String
    let hrvValue: Double
    let note: String
    
    init(id: UUID = UUID(), date: Date = Date(), mood: String, emotion: String, hrvValue: Double, note: String) {
        self.id = id
        self.date = date
        self.mood = mood
        self.emotion = emotion
        self.hrvValue = hrvValue
        self.note = note
    }
}

@MainActor
final class UserProfileManager: ObservableObject {
    @Published var userProfile: UserProfile
    @Published var moodEntries: [MoodEntry] = []
    
    static let shared = UserProfileManager()
    private let userProfileKey = "userProfile"
    private let moodEntriesKey = "moodEntries"
    
    private init() {
        // 尝试从UserDefaults中加载用户资料
        if let data = UserDefaults.standard.data(forKey: userProfileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = profile
        } else {
            // 创建新的默认配置文件
            self.userProfile = UserProfile()
        }
        
        // 加载心情记录
        if let data = UserDefaults.standard.data(forKey: moodEntriesKey),
           let entries = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            self.moodEntries = entries
        }
    }
    
    func saveProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: userProfileKey)
        }
    }
    
    func saveMoodEntries() {
        if let data = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(data, forKey: moodEntriesKey)
        }
    }
    
    func completeOnboarding() {
        userProfile.hasCompletedOnboarding = true
        saveProfile()
    }
    
    func isOnboardingCompleted() -> Bool {
        return userProfile.hasCompletedOnboarding
    }
    
    func updateProfile(nickname: String, gender: Gender, birthday: Date, occupation: String, mbtiType: String) {
        userProfile.nickname = nickname
        userProfile.gender = gender
        userProfile.birthday = birthday
        userProfile.occupation = occupation
        userProfile.mbtiType = mbtiType
        saveProfile()
    }
    
    // 添加心情记录
    func addMoodEntry(date: Date, mood: String, emotion: String, hrvValue: Double, note: String) {
        let entry = MoodEntry(date: date, mood: mood, emotion: emotion, hrvValue: hrvValue, note: note)
        moodEntries.append(entry)
        saveMoodEntries()
    }
    
    // 获取指定日期的心情记录
    func getMoodEntries(for date: Date) -> [MoodEntry] {
        let calendar = Calendar.current
        return moodEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    // 获取所有心情记录，按日期排序
    func getAllMoodEntries() -> [MoodEntry] {
        return moodEntries.sorted { $0.date > $1.date }
    }
} 