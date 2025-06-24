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
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 255/255, blue: 255/255),
                    Color(red: 250/255, green: 250/255, blue: 250/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    if let onClose = onClose {
                        Button(action: { onClose() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                                .padding(4)
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
                                        .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                                )
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
                                        .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Color.white
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(session.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(session.summary)
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
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ChatDetailView: View {
    let session: ChatSession
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 255/255, green: 255/255, blue: 255/255),
                    Color(red: 250/255, green: 250/255, blue: 250/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
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
                                    .fill(Color(red: 255/255, green: 159/255, blue: 10/255).opacity(0.1))
                            )
                    }
                    
                    Spacer()
                    
                    Text(session.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 159/255, blue: 10/255))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Color.white
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(session.messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .interactiveDismissDisabled()
    }
}

struct ChatHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHistoryView()
    }
} 