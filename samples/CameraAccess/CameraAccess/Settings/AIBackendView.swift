import SwiftUI

struct AIBackendView: View {
    @ObservedObject private var settings = SettingsManager.shared
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
                    Text("AI Backend")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Section: Choose Your AI
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CHOOSE YOUR AI")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 1) {
                                BackendSelectionRow(title: "OpenClaw", 
                                                   description: "Wake word activation, 56+ tools, task execution", 
                                                   icon: "terminal", 
                                                   isSelected: settings.activeAIBackend == "OpenClaw") {
                                    settings.activeAIBackend = "OpenClaw"
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                BackendSelectionRow(title: "Gemini Live", 
                                                   description: "Real-time voice + vision, continuous conversation", 
                                                   icon: "waveform", 
                                                   isSelected: settings.activeAIBackend == "Gemini Live") {
                                    settings.activeAIBackend = "Gemini Live"
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(15)
                            
                            Text("OpenClaw offers more tools and privacy. Gemini Live has lower latency.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                        }
                        
                        // Section: Configuration status
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CONFIGURATION")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 1) {
                                NavigationLink(destination: Text("OpenClaw Config Detail")) { // Placeholder for now or link to main settings sections
                                    ConfigStatusRow(title: "OpenClaw Settings", 
                                                   isConfigured: GeminiConfig.isOpenClawConfigured)
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                NavigationLink(destination: Text("Gemini Config Detail")) {
                                    ConfigStatusRow(title: "Gemini Settings", 
                                                   isConfigured: GeminiConfig.isConfigured)
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(15)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct BackendSelectionRow: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
}

struct ConfigStatusRow: View {
    let title: String
    let isConfigured: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(isConfigured ? "Configured" : "Not configured")
                    .font(.caption)
                    .foregroundColor(isConfigured ? .green : .orange)
                Image(systemName: isConfigured ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(isConfigured ? .green : .orange)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding()
    }
}
