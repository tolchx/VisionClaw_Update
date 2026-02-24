import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  private let settings = SettingsManager.shared

  @State private var geminiAPIKey: String = ""
  @State private var openClawHost: String = ""
  @State private var openClawPort: String = ""
  @State private var openClawHookToken: String = ""
  @State private var openClawGatewayToken: String = ""
  @State private var geminiSystemPrompt: String = ""
  @State private var webrtcSignalingURL: String = ""
  @State private var showResetConfirmation = false
  
  @State private var activeTab: SettingsTab = .ai

  enum SettingsTab: String, CaseIterable {
    case ai = "AI Assistant"
    case openClaw = "OpenClaw"
    case connection = "Connection"
    
    var icon: String {
        switch self {
        case .ai: return "sparkles"
        case .openClaw: return "terminal"
        case .connection: return "link"
        }
    }
  }

  var body: some View {
    ZStack {
      AnimatedBackground()
      
      VStack(spacing: 0) {
        // Custom Header
        headerView
        
        // Tab Switcher
        tabSwitcher
        
        // Content Area
        ScrollView {
          VStack(spacing: 20) {
            switch activeTab {
            case .ai: aiSection
            case .openClaw: openClawSection
            case .connection: connectionSection
            }
            
            Spacer(minLength: 40)
          }
          .padding()
        }
      }
    }
    .navigationBarHidden(true)
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

  // MARK: - Subviews

  private var headerView: some View {
    HStack {
      Button("Cancel") { dismiss() }
        .foregroundColor(.white.opacity(0.8))
      
      Spacer()
      
      Text("Settings")
        .font(.headline)
        .foregroundColor(.white)
      
      Spacer()
      
      Button("Save") {
        save()
        dismiss()
      }
      .fontWeight(.bold)
      .foregroundColor(.white)
    }
    .padding()
    .background(Color.black.opacity(0.2))
  }

  private var tabSwitcher: some View {
    HStack(spacing: 0) {
      ForEach(SettingsTab.allCases, id: \.self) { tab in
        Button(action: { withAnimation(.spring()) { activeTab = tab } }) {
          VStack(spacing: 8) {
            Image(systemName: tab.icon)
              .font(.system(size: 18))
            Text(tab.rawValue)
              .font(.caption2)
          }
          .foregroundColor(activeTab == tab ? .white : .white.opacity(0.4))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(activeTab == tab ? Color.white.opacity(0.1) : Color.clear)
        }
      }
    }
    .background(Color.black.opacity(0.1))
    .overlay(
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1),
        alignment: .bottom
    )
  }

  private var aiSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      settingField(title: "Gemini API Key", placeholder: "Enter API key", text: $geminiAPIKey, isSecure: true)
      
      VStack(alignment: .leading, spacing: 8) {
        Text("System Prompt")
          .font(.caption)
          .foregroundColor(.white.opacity(0.6))
          .padding(.leading, 4)
        
        TextEditor(text: $geminiSystemPrompt)
          .font(.system(.body, design: .monospaced))
          .frame(minHeight: 250)
          .padding(12)
          .background(Color.black.opacity(0.3))
          .cornerRadius(12)
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        
        Text("Customize the AI assistant's behavior. Takes effect on next session.")
          .font(.caption2)
          .foregroundColor(.white.opacity(0.4))
          .padding(.leading, 4)
      }
    }
    .glassPanel()
  }

  private var openClawSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      settingField(title: "Host", placeholder: "http://your-mac.local", text: $openClawHost)
      settingField(title: "Port", placeholder: "18789", text: $openClawPort, keyboardType: .numberPad)
      settingField(title: "Hook Token", placeholder: "Enter hook token", text: $openClawHookToken, isSecure: true)
      settingField(title: "Gateway Token", placeholder: "Enter gateway token", text: $openClawGatewayToken, isSecure: true)
      
      Text("Connect to an OpenClaw gateway running on your Mac for agentic tool-calling.")
        .font(.caption2)
        .foregroundColor(.white.opacity(0.4))
        .padding(.top, 4)
    }
    .glassPanel()
  }

  private var connectionSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      settingField(title: "WebRTC Signaling URL", placeholder: "wss://...", text: $webrtcSignalingURL)
      
      Divider().background(Color.white.opacity(0.1))
      
      Button(action: { showResetConfirmation = true }) {
        HStack {
          Spacer()
          Text("Reset to Defaults")
            .foregroundColor(.red)
            .fontWeight(.semibold)
          Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
      }
    }
    .glassPanel()
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
      .font(.system(.body, design: .monospaced))
      .padding(12)
      .background(Color.black.opacity(0.3))
      .cornerRadius(12)
      .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
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
