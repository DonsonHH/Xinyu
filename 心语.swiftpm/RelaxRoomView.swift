import SwiftUI

struct Song: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
}

struct RelaxRoomView: View {
    // 示例推荐歌曲数据
    let recommendedSongs: [Song] = [
        Song(title: "治愈钢琴曲", artist: "轻音乐"),
        Song(title: "自然之声", artist: "大自然"),
        Song(title: "舒缓吉他", artist: "吉他手"),
        Song(title: "冥想旋律", artist: "冥想音乐"),
    ]
    
    @State private var showARMeditation = false
    @EnvironmentObject var tabSelection: TabSelection
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                            ForEach(recommendedSongs) { song in
                                Button(action: {
                                    if let url = URL(string: "qqmusic://") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ZStack {
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
                                                .frame(width: 140, height: 140)
                                            Image(systemName: "music.note")
                                                .font(.system(size: 36))
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
                                    .frame(width: 140)
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
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 功能卡片组
                VStack(spacing: 16) {
                    // 运动减压卡片
                    Button(action: {
                        if let url = URL(string: "keep://") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
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
                    NavigationLink(destination: ARMeditationGuideView()) {
                        HStack {
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
                    // 冥想训练卡片
                    Button(action: {
                        if let url = URL(string: "keep://") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
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
                    Button(action: {
                        tabSelection.selectedTab = 1
                    }) {
                        HStack {
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
            .padding(.top, 24)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 245/255, blue: 235/255),
                    Color(red: 255/255, green: 236/255, blue: 210/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("放松室")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RelaxRoomView_Previews: PreviewProvider {
    static var previews: some View {
        RelaxRoomView()
    }
} 