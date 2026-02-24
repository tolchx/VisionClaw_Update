import SwiftUI

struct ChatHistoryView: View {
    @StateObject var historyManager = ChatHistoryManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var editingSessionId: UUID?
    @State private var newTitle: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                List {
                    ForEach(historyManager.sessions) { session in
                        NavigationLink(destination: ChatSessionDetailView(session: session)) {
                            VStack(alignment: .leading, spacing: 4) {
                                if editingSessionId == session.id {
                                    HStack {
                                        TextField("Session Title", text: $newTitle, onCommit: {
                                            historyManager.updateSessionTitle(id: session.id, newTitle: newTitle)
                                            editingSessionId = nil
                                        })
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .foregroundColor(.black)
                                        
                                        Button("Done") {
                                            historyManager.updateSessionTitle(id: session.id, newTitle: newTitle)
                                            editingSessionId = nil
                                        }
                                    }
                                } else {
                                    Text(session.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(session.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("\(session.messages.count) messages")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                historyManager.deleteSession(id: session.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                editingSessionId = session.id
                                newTitle = session.title
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                    }
                    .onDelete(perform: historyManager.deleteSession)
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ChatSessionDetailView: View {
    let session: ChatSession
    
    var body: some View {
        ZStack {
            AnimatedBackground()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(session.messages) { message in
                        ChatMessageBubble(text: message.text, isUser: message.role == .user)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHistoryView()
    }
}
