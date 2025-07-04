import SwiftUI
import AVKit
import Combine

struct Song: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
}

struct QQMusicSong: Identifiable, Codable, Equatable {
    let id = UUID()
    let author: String
    let lrc: String
    let pic: String
    let title: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case author, lrc, pic, title, url
    }
    
    static func == (lhs: QQMusicSong, rhs: QQMusicSong) -> Bool {
        lhs.title == rhs.title && lhs.author == rhs.author && lhs.url == rhs.url
    }
}

class QQMusicFetcher: ObservableObject {
    @Published var songs: [QQMusicSong] = []
    
    func fetchSongs() {
        guard let url = URL(string: "https://api2.52jan.com/music/songlist?server=qqmusic&id=8672698451") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let songs = try? JSONDecoder().decode([QQMusicSong].self, from: data) {
                DispatchQueue.main.async {
                    self.songs = songs
                }
            }
        }.resume()
    }
}

struct RelaxRoomView: View {
    @StateObject private var fetcher = QQMusicFetcher()
    @State private var player: AVPlayer? = nil
    @State private var selectedSongs: [QQMusicSong] = []
    @State private var showPlayError: Bool = false
    @EnvironmentObject var tabSelection: TabSelection
    
    private func refreshSongs() {
        if fetcher.songs.count > 5 {
            selectedSongs = Array(fetcher.songs.shuffled().prefix(5))
        } else {
            selectedSongs = fetcher.songs
        }
    }
    
    var body: some View {
        NavigationStack {
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
                        RelaxRoomHeaderView()
                        QQMusicRecommendView(songs: selectedSongs, player: $player, showPlayError: $showPlayError, onRefresh: refreshSongs)
                        // 功能卡片组
                        FunctionCardGroupView(tabSelection: tabSelection)
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
            .onAppear {
                fetcher.fetchSongs()
            }
            .onChange(of: fetcher.songs) { _ in
                refreshSongs()
            }
            .alert("播放失败，可能是歌曲地址已失效或不支持播放", isPresented: $showPlayError) {
                Button("确定", role: .cancel) {}
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RelaxRoomView_Previews: PreviewProvider {
    static var previews: some View {
        RelaxRoomView().environmentObject(TabSelection())
    }
}

private struct BingDailyImageView: View {
    var body: some View {
        AsyncImage(url: URL(string: "https://bing.img.run/1366x768.php")) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 180, height: 240)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 350, height: 250)
                    .clipped()
                    .cornerRadius(18)
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }
}

private struct RelaxRoomHeaderView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("欢迎来到你的放松室")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
            Text("在这里，放松身心，享受片刻的宁静与治愈")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            BingDailyImageView()
                .padding(.top, 4)
        }
        .padding(.top, 32)
    }
}

private struct QQMusicRecommendView: View {
    let songs: [QQMusicSong]
    @Binding var player: AVPlayer?
    @Binding var showPlayError: Bool
    var onRefresh: () -> Void
    @State private var currentPlayingURL: String? = nil
    @State private var isPlaying: Bool = false
    @State private var refreshTrigger: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note").foregroundColor(.purple)
                Text("治愈音乐推荐").font(.system(size: 17, weight: .medium)).foregroundColor(.gray)
                Spacer()
                Button(action: {
                    refreshTrigger += 1
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                }
            }
            .onChange(of: refreshTrigger) { _ in
                onRefresh()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(songs) { song in
                        ZStack(alignment: .topTrailing) {
                            VStack {
                                AsyncImage(url: URL(string: song.pic)) { image in
                                    image.resizable()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 100, height: 100)
                                .cornerRadius(12)
                                Text(song.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text(song.author)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                HStack {
                                    Button(action: {
                                        do {
                                            let session = AVAudioSession.sharedInstance()
                                            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                                            try session.setActive(true)
                                            if let url = URL(string: song.url) {
                                                if currentPlayingURL == song.url && isPlaying {
                                                    player?.pause()
                                                    isPlaying = false
                                                } else if currentPlayingURL == song.url && !isPlaying {
                                                    player?.play()
                                                    isPlaying = true
                                                } else {
                                                    player = AVPlayer(url: url)
                                                    player?.play()
                                                    currentPlayingURL = song.url
                                                    isPlaying = true
                                                }
                                            } else {
                                                showPlayError = true
                                            }
                                        } catch {
                                            showPlayError = true
                                        }
                                    }) {
                                        Image(systemName: (currentPlayingURL == song.url && isPlaying) ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .frame(width: 120)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            // 右上角跳转按钮
                            Button(action: {
                                if let url = URL(string: "qqmusic://") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image(systemName: "arrowshape.turn.up.right.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.green)
                                    .padding(6)
                            }
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
    }
}

// 功能卡片组子视图
private struct FunctionCardGroupView: View {
    @ObservedObject var tabSelection: TabSelection
    var body: some View {
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
    }
} 