import SwiftUI

struct OfflineModelView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var errorMessage: String? = nil
    
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
                    Text("Offline AI Model")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Offline Inference Engine Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("OFFLINE INFERENCE ENGINE")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Smart glasses need a local Small Language Model (SLM) to function in subway tunnels, elevators, and remote areas without Wi-Fi.")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("HuggingFace Model URL (GGUF or MLX)")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    
                                    TextField("https://...", text: $settings.offlineModelURL)
                                        .padding()
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: simulateDownload) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle")
                                        Text(isDownloading ? "Downloading..." : "Download Model")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                }
                                .disabled(isDownloading)
                                
                                if let error = errorMessage {
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .padding(.top, 4)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(15)
                        }
                        
                        // Active Local Model Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACTIVE LOCAL MODEL")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            Text("No local model downloaded yet.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func simulateDownload() {
        isDownloading = true
        errorMessage = nil
        
        // Simulating the error shown in the user's screenshot
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isDownloading = false
            errorMessage = "Error: Failed to save file: \"CFNetworkDownload_vZTgmW.tmp\" couldn't be moved to \"Documents\" because either the former doesn't exist, or the folder containing the latter doesn't exist."
        }
    }
}
