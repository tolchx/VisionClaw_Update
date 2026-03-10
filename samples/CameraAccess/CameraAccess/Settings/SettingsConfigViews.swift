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
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    Spacer()
                    Text("OpenClaw Config Detail")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding()

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
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    Spacer()
                    Text("Gemini Config Detail")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding()

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
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    Spacer()
                    Text("Glasses Connection")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding()
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
