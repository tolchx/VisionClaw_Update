import Foundation

class ChatHistoryManager: ObservableObject {
    static let shared = ChatHistoryManager()
    
    @Published var sessions: [ChatSession] = []
    
    private let fileManager = FileManager.default
    private let fileName = "chat_history.json"
    
    private init() {
        loadSessions()
    }
    
    private var historyURL: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    func saveSession(_ session: ChatSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }
        persist()
    }
    
    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persist()
    }
    
    func deleteSession(id: UUID) {
        sessions.removeAll(where: { $0.id == id })
        persist()
    }
    
    func updateSessionTitle(id: UUID, newTitle: String) {
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].title = newTitle
            persist()
        }
    }
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            print("Failed to save chat history: \(error.localizedDescription)")
        }
    }
    
    private func loadSessions() {
        guard fileManager.fileExists(atPath: historyURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: historyURL)
            sessions = try JSONDecoder().decode([ChatSession].self, from: data)
        } catch {
            print("Failed to load chat history: \(error.localizedDescription)")
        }
    }
}
