import SwiftUI

struct ChatHistoryView: View {
    var onClose: (() -> Void)? = nil
    @StateObject private var historyManager = ChatHistoryManager.shared
    @State private var showingDeleteAlert = false
    @State private var selectedSession: ChatSession?
    @State private var showingClearAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 背景
            Color(red: 255/255, green: 245/255, blue: 235/255)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    if let onClose = onClose {
                        Button(action: { onClose() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .background(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.08))
                                )
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                    } else {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .background(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.08))
                                )
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                    }
                    Spacer()
                    Text("聊天历史")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    Spacer()
                    if !historyManager.chatSessions.isEmpty {
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .background(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.08))
                                )
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .background(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.05))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                
                if historyManager.chatSessions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("暂无聊天记录")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(historyManager.chatSessions.sorted(by: { $0.startTime > $1.startTime })) { session in
                                NavigationLink(destination: ChatDetailView(session: session)) {
                                    ChatSessionRow(session: session)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        selectedSession = session
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .interactiveDismissDisabled()
        .onAppear {
            // 确保在视图出现时加载聊天历史
            Task {
                await historyManager.loadChatSessions()
            }
        }
        .alert("删除对话", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let session = selectedSession,
                   let index = historyManager.chatSessions.firstIndex(where: { $0.id == session.id }) {
                    historyManager.removeChatSession(at: IndexSet(integer: index))
                }
            }
        } message: {
            Text("确定要删除这条对话记录吗？此操作无法撤销。")
        }
        .alert("清空历史", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                historyManager.clearAllSessions()
            }
        } message: {
            Text("确定要清空所有聊天记录吗？此操作无法撤销。")
        }
    }
}

struct ChatSessionRow: View {
    let session: ChatSession
    var highlight: String = ""
    var isSelected: Bool = false
    
    func highlightText(_ text: String) -> Text {
        guard !highlight.isEmpty else { return Text(text) }
        let parts = text.components(separatedBy: highlight)
        var result = Text("")
        for (i, part) in parts.enumerated() {
            result = result + Text(part)
            if i < parts.count - 1 {
                result = result + Text(highlight).foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255)).bold()
            }
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                highlightText(session.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if session.isArchived {
                    Image(systemName: "archivebox")
                        .foregroundColor(Color.gray)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.trailing, 2)
                }
                Text(session.lastModified.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            highlightText(session.summary)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            HStack {
                Text(session.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(session.messages.count) 条消息")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 255/255, green: 236/255, blue: 210/255))
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.18))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color(red: 255/255, green: 159/255, blue: 10/255) : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct ChatDetailView: View {
    let session: ChatSession
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // 背景
            Color(red: 255/255, green: 245/255, blue: 235/255)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .background(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.08))
                            )
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Text(session.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    
                    Spacer()
                    
                    // 占位视图保持对称
                    Circle()
                        .fill(.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .background(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.05))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(session.messages) { message in
                            MessageBubbleView(message: message)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(red: 255/255, green: 159/255, blue: 10/255))
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.7))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                
                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct ChatHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHistoryView()
    }
} 
