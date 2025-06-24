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
        ZStack(alignment: .top) {
            // 柔和渐变背景+装饰圆
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 250/255, blue: 240/255),
                    Color(red: 255/255, green: 236/255, blue: 210/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            Circle()
                .fill(Color(red: 255/255, green: 220/255, blue: 180/255).opacity(0.18))
                .frame(width: 220, height: 220)
                .offset(x: -80, y: -80)
            Circle()
                .fill(Color(red: 180/255, green: 220/255, blue: 255/255).opacity(0.12))
                .frame(width: 180, height: 180)
                .offset(x: 120, y: 60)
            
            ScrollView {
                VStack(spacing: 36) {
                    // 顶部欢迎语和插画
                    VStack(spacing: 10) {
                        Text("欢迎来到你的放松室")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        Text("在这里，放松身心，享受片刻的宁静与治愈")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                        // 插画（如有图片可替换为Image("relax_illustration")）
                        Text("🐱☁️🌿")
                            .font(.system(size: 44))
                            .padding(.top, 4)
                    }
                    .padding(.top, 32)
                    
                    // 音乐推荐卡片
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(.purple)
                            Text("治愈音乐推荐")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(recommendedSongs) { song in
                                    Button(action: {
                                        if let url = URL(string: "qqmusic://") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 18)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color.purple.opacity(0.7),
                                                                Color.blue.opacity(0.5)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 120, height: 120)
                                                Image(systemName: "music.note")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                            VStack(alignment: .center, spacing: 4) {
                                                Text(song.title)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.black)
                                                    .lineLimit(1)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                Text(song.artist)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                                    .lineLimit(1)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                            }
                                            .padding(.horizontal, 2)
                                        }
                                        .frame(width: 120)
                                        .background(Color.white)
                                        .cornerRadius(18)
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                    .padding(.horizontal, 8)
                    
                    // 功能卡片组
                    VStack(spacing: 22) {
                        // 运动减压卡片
                        Button(action: {
                            if let url = URL(string: "keep://") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "figure.run")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                        Text("运动减压")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    Text("舒展身体，释放压力")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .semibold))
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
                            .cornerRadius(22)
                        }
                        // 正念投影卡片
                        NavigationLink(destination: ARMeditationGuideView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "person.fill.viewfinder")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                        Text("正念投影")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    Text("AR冥想导师 · 呼吸引导")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .semibold))
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
                            .cornerRadius(22)
                        }
                        // 冥想训练卡片
                        Button(action: {
                            if let url = URL(string: "keep://") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "brain.head.profile")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                        Text("冥想训练")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    Text("专注当下，觉察自我")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .semibold))
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
                            .cornerRadius(22)
                        }
                        // NMO小游戏卡片
                        NavigationLink(destination: NMOGameView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                        Text("NMO小游戏")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    Text("放松心情，轻松一刻")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 255/255, green: 204/255, blue: 0/255),
                                        Color(red: 255/255, green: 159/255, blue: 10/255)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(22)
                        }
                        // AI倾诉对话卡片
                        Button(action: {
                            tabSelection.selectedTab = 1
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                        Text("AI倾诉对话")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    Text("语音、文字、表情陪伴你")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .semibold))
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
                            .cornerRadius(22)
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // 底部温馨祝福
                    VStack(spacing: 8) {
                        Text("祝你拥有温柔的一天 ☀️")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                        Text("—— 心语AI陪伴你")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RelaxRoomView_Previews: PreviewProvider {
    static var previews: some View {
        RelaxRoomView().environmentObject(TabSelection())
    }
} 