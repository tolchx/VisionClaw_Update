import SwiftUI

struct SettingsField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.leading, 4)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .keyboardType(keyboardType)
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

struct OpenClawConnectionSettingsView: View {
    @Binding var openClawHost: String
    @Binding var openClawPort: String
    @Binding var openClawGatewayToken: String
    @Binding var webrtcSignalingURL: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack(spacing: 0) {
                // Custom Header to match the others if pushed without native nabBar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    Spacer()
                    Text("OpenClaw Config Detail")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 40)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        SettingsField(title: "OpenClaw Host", placeholder: "http://your-mac.local", text: $openClawHost)
                        SettingsField(title: "OpenClaw Port", placeholder: "18789", text: $openClawPort, keyboardType: .numberPad)
                        SettingsField(title: "Gateway Token", placeholder: "Optional", text: $openClawGatewayToken, isSecure: true)
                        SettingsField(title: "WebRTC Signaling URL", placeholder: "wss://...", text: $webrtcSignalingURL)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct GeminiConnectionSettingsView: View {
    @Binding var geminiAPIKey: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    Spacer()
                    Text("Gemini Config Detail")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 40)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        SettingsField(title: "Gemini API Key", placeholder: "AIzaSy...", text: $geminiAPIKey, isSecure: true)
                        
                        // Informational Text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your API key is stored securely on your device.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Link("Get an API key from Google AI Studio ↗", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                                .font(.caption2.bold())
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct GlassesConnectionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
         ZStack {
            AnimatedBackground()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    Spacer()
                    Text("Glasses Connection")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 40)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                Spacer()
                Text("Not Connected")
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct MemoriesSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var newMemory: String = ""

    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    Spacer()
                    Text("Memories")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 40)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                List {
                    Section(header: Text("ADD NEW MEMORY").foregroundColor(.gray)) {
                        HStack {
                            TextField("Something to remember...", text: $newMemory)
                                .foregroundColor(.white)
                            Button(action: addMemory) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(newMemory.isEmpty)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section(header: Text("STORED MEMORIES").foregroundColor(.gray)) {
                        if settings.memories.isEmpty {
                            Text("No memories stored yet.")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(settings.memories, id: \.self) { memory in
                                Text(memory)
                                    .foregroundColor(.white)
                            }
                            .onDelete(perform: deleteMemory)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private func addMemory() {
        let trimmed = newMemory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            settings.memories.append(trimmed)
            newMemory = ""
        }
    }

    private func deleteMemory(at offsets: IndexSet) {
        settings.memories.remove(atOffsets: offsets)
    }
}
