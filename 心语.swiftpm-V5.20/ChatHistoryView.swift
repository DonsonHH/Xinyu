import SwiftUI

struct ChatHistoryView: View {
    @StateObject private var historyManager = ChatHistoryManager.shared
    @State private var showingDeleteAlert = false
    @State private var selectedSession: ChatSession?
    @State private var showingClearAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.orange.opacity(0.1).ignoresSafeArea()
            
            VStack {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        // 直接返回到根视图
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text("聊天历史")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button(action: {
                        if !historyManager.chatSessions.isEmpty {
                            showingClearAlert = true
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                
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
                    List {
                        ForEach(historyManager.chatSessions) { session in
                            NavigationLink(destination: ChatDetailView(session: session)) {
                                ChatSessionRow(session: session)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    selectedSession = session
                                    showingDeleteAlert = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            historyManager.removeChatSession(at: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .navigationBarHidden(true)
        .interactiveDismissDisabled(false) // 确保支持左滑返回
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
    }
}

struct ChatDetailView: View {
    let session: ChatSession
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.orange.opacity(0.1).ignoresSafeArea()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(session.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitle(session.title, displayMode: .inline)
        .interactiveDismissDisabled(false) // 确保支持左滑返回
    }
}

struct ChatHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHistoryView()
    }
} 