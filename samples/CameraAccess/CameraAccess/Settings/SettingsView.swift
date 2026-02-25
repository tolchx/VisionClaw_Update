struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var settings = SettingsManager.shared

  @State private var geminiAPIKey: String = ""
  @State private var openClawHost: String = ""
  @State private var openClawPort: String = ""
  @State private var openClawHookToken: String = ""
  @State private var openClawGatewayToken: String = ""
  @State private var geminiSystemPrompt: String = ""
  @State private var webrtcSignalingURL: String = ""
  @State private var showResetConfirmation = false

  var body: some View {
    NavigationStack {
      ZStack {
        AnimatedBackground()
        
        List {
          // SECTION: AI
          Section(header: Text("AI").foregroundColor(.gray)) {
            NavigationLink(destination: AIBackendView()) {
              CategoryRow(title: "AI Backend", value: settings.activeAIBackend, icon: "cpu", iconColor: .blue)
            }
            
            NavigationLink(destination: CustomInstructionsView(text: $geminiSystemPrompt)) {
              CategoryRow(title: "Custom Instructions", icon: "text.quote", iconColor: .cyan)
            }
            
            CategoryRow(title: "Memories", value: "0", icon: "brain", iconColor: .purple)
          }
          .listRowBackground(Color.white.opacity(0.05))
          
          // SECTION: Hardware
          Section(header: Text("Hardware").foregroundColor(.gray)) {
            NavigationLink(destination: Text("Glasses Connection Detail")) {
                HStack {
                    Image(systemName: "eyeglasses")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("Glasses")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
          }
          .listRowBackground(Color.white.opacity(0.05))
          
          // SECTION: Voice
          Section(header: Text("Voice").foregroundColor(.gray)) {
            NavigationLink(destination: VoiceControlView()) {
              CategoryRow(title: "Voice Control", value: settings.wakePhrase, icon: "mic.fill", iconColor: .blue)
            }
          }
          .listRowBackground(Color.white.opacity(0.05))
          
          // SECTION: Advanced
          Section(header: Text("Advanced").foregroundColor(.gray)) {
            ToggleRow(title: "Auto-Reconnect", isOn: $settings.autoReconnect)
            ToggleRow(title: "Show Transcripts", isOn: $settings.showTranscripts)
            
            NavigationLink(destination: connectionSettingsView) {
                CategoryRow(title: "Connection Settings", icon: "link", iconColor: .gray)
            }
          }
          .listRowBackground(Color.white.opacity(0.05))
          
          // SECTION: Offline Capabilities
          Section(header: Text("Offline Capabilities").foregroundColor(.gray)) {
            NavigationLink(destination: OfflineModelView()) {
              CategoryRow(title: "Offline AI Model", value: "Not Installed", icon: "globe", iconColor: .cyan)
            }
          }
          .listRowBackground(Color.white.opacity(0.05))
          
          // Reset Section
          Section {
            Button(action: { showResetConfirmation = true }) {
                Text("Factory Reset")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
          }
          .listRowBackground(Color.red.opacity(0.1))
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
                .foregroundColor(.white.opacity(0.7))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                save()
                dismiss()
            }
            .fontWeight(.bold)
            .foregroundColor(.white)
        }
      }
      .alert("Reset Settings", isPresented: $showResetConfirmation) {
        Button("Reset", role: .destructive) {
          settings.resetAll()
          loadCurrentValues()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This will reset all settings to the values built into the app.")
      }
      .onAppear {
        loadCurrentValues()
      }
      .preferredColorScheme(.dark)
    }
  }

  // MARK: - Components

  private var connectionSettingsView: some View {
      ZStack {
          AnimatedBackground()
          ScrollView {
              VStack(spacing: 20) {
                  settingField(title: "OpenClaw Host", placeholder: "http://your-mac.local", text: $openClawHost)
                  settingField(title: "OpenClaw Port", placeholder: "18789", text: $openClawPort, keyboardType: .numberPad)
                  settingField(title: "Gateway Token", placeholder: "Optional", text: $openClawGatewayToken, isSecure: true)
                  settingField(title: "WebRTC Signaling URL", placeholder: "wss://...", text: $webrtcSignalingURL)
              }
              .padding()
          }
      }
      .navigationTitle("Connection")
  }

  @ViewBuilder
  private func settingField(title: String, placeholder: String, text: Binding<String>, isSecure: Bool = false, keyboardType: UIKeyboardType = .default) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundColor(.white.opacity(0.6))
        .padding(.leading, 4)
      
      Group {
        if isSecure {
          SecureField(placeholder, text: text)
        } else {
          TextField(placeholder, text: text)
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

  private func loadCurrentValues() {
    geminiAPIKey = settings.geminiAPIKey
    geminiSystemPrompt = settings.geminiSystemPrompt
    openClawHost = settings.openClawHost
    openClawPort = String(settings.openClawPort)
    openClawHookToken = settings.openClawHookToken
    openClawGatewayToken = settings.openClawGatewayToken
    webrtcSignalingURL = settings.webrtcSignalingURL
  }

  private func save() {
    settings.geminiAPIKey = geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
    settings.geminiSystemPrompt = geminiSystemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
    settings.openClawHost = openClawHost.trimmingCharacters(in: .whitespacesAndNewlines)
    if let port = Int(openClawPort.trimmingCharacters(in: .whitespacesAndNewlines)) {
      settings.openClawPort = port
    }
    settings.openClawHookToken = openClawHookToken.trimmingCharacters(in: .whitespacesAndNewlines)
    settings.openClawGatewayToken = openClawGatewayToken.trimmingCharacters(in: .whitespacesAndNewlines)
    settings.webrtcSignalingURL = webrtcSignalingURL.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

struct CategoryRow: View {
    let title: String
    var value: String? = nil
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            if let val = value {
                Text(val)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct CustomInstructionsView: View {
    @Binding var text: String
    var body: some View {
        ZStack {
            AnimatedBackground()
            VStack {
                TextEditor(text: $text)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding()
                Spacer()
            }
        }
        .navigationTitle("Instructions")
    }
}
