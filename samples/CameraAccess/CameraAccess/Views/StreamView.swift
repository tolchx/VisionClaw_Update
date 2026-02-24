/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// StreamView.swift
//
// Main UI for video streaming from Meta wearable devices using the DAT SDK.
// This view demonstrates the complete streaming API: video streaming with real-time display, photo capture,
// and error handling. Extended with Gemini Live AI assistant and WebRTC live streaming integration.
//

import MWDATCore
import SwiftUI

struct StreamView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var wearablesVM: WearablesViewModel
  @ObservedObject var geminiVM: GeminiSessionViewModel
  @ObservedObject var webrtcVM: WebRTCSessionViewModel
  
  @Binding var isMenuOpen: Bool

  var body: some View {
    ZStack {
      // 1. Backgrounds
      AnimatedBackground()
      ParticleEffect(particleCount: 30).opacity(0.5)

      // Video backdrop: PiP when WebRTC connected, otherwise single local feed
      if webrtcVM.isActive && webrtcVM.connectionState == .connected {
        // Embed PiP inside a container
        VStack {
            Spacer()
            PiPVideoView(
              localFrame: viewModel.currentVideoFrame,
              remoteVideoTrack: webrtcVM.remoteVideoTrack,
              hasRemoteVideo: webrtcVM.hasRemoteVideo
            )
            .frame(height: 300)
            .padding()
        }
      } else if let videoFrame = viewModel.currentVideoFrame, viewModel.hasReceivedFirstFrame {
        GeometryReader { geometry in
          Image(uiImage: videoFrame)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .opacity(0.4) // Dim video to make UI pop
        }
        .edgesIgnoringSafeArea(.all)
      } else {
        ProgressView()
          .scaleEffect(1.5)
          .foregroundColor(.white)
      }

      // 2. Main Interactive UI
      VStack(spacing: 0) {
        // Top Bar
        HStack {
            Button {
                withAnimation { isMenuOpen.toggle() }
            } label: {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.white)
            }
            .glassmorphismPill()
            
            Spacer()
            
            if geminiVM.isGeminiActive {
                GeminiStatusBar(geminiVM: geminiVM)
                    .glassmorphismPill()
            } else if webrtcVM.isActive {
                WebRTCStatusBar(webrtcVM: webrtcVM)
                    .glassmorphismPill()
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear.frame(width: 44, height: 44)
        }
        .padding()

        // Chat History
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if !geminiVM.userTranscript.isEmpty {
                        ChatMessageBubble(text: geminiVM.userTranscript, isUser: true)
                    }
                    if !geminiVM.aiTranscript.isEmpty {
                        ChatMessageBubble(text: geminiVM.aiTranscript, isUser: false)
                    }
                    Color.clear.frame(height: 1).id("bottomSpacer")
                }
                .padding()
            }
            .onChange(of: geminiVM.userTranscript) { _ in
                withAnimation { proxy.scrollTo("bottomSpacer", anchor: .bottom) }
            }
            .onChange(of: geminiVM.aiTranscript) { _ in
                withAnimation { proxy.scrollTo("bottomSpacer", anchor: .bottom) }
            }
        }
        
        Spacer()

        // Text Input Box / Bottom Controls
        VStack(spacing: 12) {
            if geminiVM.isGeminiActive {
                if geminiVM.toolCallStatus != .idle {
                    ToolCallStatusView(status: geminiVM.toolCallStatus)
                }
                
                if geminiVM.isModelSpeaking {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        SpeakingIndicator()
                    }
                    .glassmorphismPill()
                }
            }

            ControlsView(viewModel: viewModel, geminiVM: geminiVM, webrtcVM: webrtcVM)
        }
        .padding()
        .glassPanel()
        .padding()
      }
    }
    .onDisappear {
      Task {
        if viewModel.streamingStatus != .stopped {
          await viewModel.stopSession()
        }
        if geminiVM.isGeminiActive {
          geminiVM.stopSession()
        }
        if webrtcVM.isActive {
          webrtcVM.stopSession()
        }
      }
    }
    // Show captured photos
    .sheet(isPresented: $viewModel.showPhotoPreview) {
      if let photo = viewModel.capturedPhoto {
        PhotoPreviewView(
          photo: photo,
          onDismiss: {
            viewModel.dismissPhotoPreview()
          }
        )
      }
    }
    // Gemini error alert
    .alert("AI Assistant", isPresented: Binding(
      get: { geminiVM.errorMessage != nil },
      set: { if !$0 { geminiVM.errorMessage = nil } }
    )) {
      Button("OK") { geminiVM.errorMessage = nil }
    } message: {
      Text(geminiVM.errorMessage ?? "")
    }
    // WebRTC error alert
    .alert("Live Stream", isPresented: Binding(
      get: { webrtcVM.errorMessage != nil },
      set: { if !$0 { webrtcVM.errorMessage = nil } }
    )) {
      Button("OK") { webrtcVM.errorMessage = nil }
    } message: {
      Text(webrtcVM.errorMessage ?? "")
    }
  }
}

// Extracted controls for clarity
struct ControlsView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var geminiVM: GeminiSessionViewModel
  @ObservedObject var webrtcVM: WebRTCSessionViewModel

  private var micColor: Color {
      if webrtcVM.isActive { return .gray }
      if !geminiVM.isGeminiActive { return .gray }
      
      switch geminiVM.connectionState {
      case .connecting: return .orange
      case .ready:
          if geminiVM.isModelSpeaking {
              return .green
          } else {
              // Simple heuristic for thinking/listening
              return geminiVM.toolCallStatus != .idle ? .purple : .blue
          }
      default: return .gray
      }
  }

  var body: some View {
    HStack(spacing: 20) {
      Button(action: {
          Task { await viewModel.stopSession() }
      }) {
          Image(systemName: "stop.fill")
              .foregroundColor(.red)
              .font(.title2)
              .frame(width: 50, height: 50)
              .background(Circle().fill(.ultraThinMaterial))
              .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
      }

      if viewModel.streamingMode == .glasses {
        Button(action: {
            viewModel.capturePhoto()
        }) {
            Image(systemName: "camera.fill")
                .foregroundColor(.white)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
      }

      // Gemini AI Button
      Button(action: {
        Task {
          if geminiVM.isGeminiActive {
            geminiVM.stopSession()
          } else {
            await geminiVM.startSession()
          }
        }
      }) {
          Image(systemName: geminiVM.isGeminiActive ? "waveform" : "mic.fill")
              .foregroundColor(.white)
              .font(.title)
              .frame(width: 65, height: 65)
              .background(Circle().fill(micColor))
              .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
              .shadow(color: micColor.opacity(0.5), radius: 10, x: 0, y: 0)
      }
      .opacity(webrtcVM.isActive ? 0.4 : 1.0)
      .disabled(webrtcVM.isActive)

      // WebRTC Live Stream button
      Button(action: {
        Task {
          if webrtcVM.isActive {
            webrtcVM.stopSession()
          } else {
            await webrtcVM.startSession()
          }
        }
      }) {
          Image(systemName: "antenna.radiowaves.left.and.right")
              .foregroundColor(.white)
              .font(.title2)
              .frame(width: 50, height: 50)
              .background(Circle().fill(webrtcVM.isActive ? AnyShapeStyle(Color.blue) : AnyShapeStyle(.ultraThinMaterial)))
              .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
      }
      .opacity(geminiVM.isGeminiActive ? 0.4 : 1.0)
      .disabled(geminiVM.isGeminiActive)
    }
  }
}

// MARK: - Appended Views for compilation

struct AnimatedBackground: View {
    @State private var animateGradient = false
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2), // Dark Slate
                Color(red: 0.05, green: 0.3, blue: 0.4), // Deep Teal
                Color(red: 0.2, green: 0.1, blue: 0.3)  // Deep Purple
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var speedX: CGFloat
    var speedY: CGFloat
}

struct ParticleEffect: View {
    let particleCount: Int
    @State private var particles: [Particle] = []
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
            .onReceive(timer) { _ in
                updateParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                scale: CGFloat.random(in: 0.2...1.5),
                opacity: Double.random(in: 0.1...0.5),
                speedX: CGFloat.random(in: -1...1),
                speedY: CGFloat.random(in: -1...1)
            )
        }
    }
    
    private func updateParticles(in size: CGSize) {
        for index in particles.indices {
            var particle = particles[index]
            particle.x += particle.speedX
            particle.y += particle.speedY
            if particle.x < 0 { particle.x = size.width }
            else if particle.x > size.width { particle.x = 0 }
            if particle.y < 0 { particle.y = size.height }
            else if particle.y > size.height { particle.y = 0 }
            particles[index] = particle
        }
    }
}

struct ChatMessageBubble: View {
    let text: String
    let isUser: Bool
    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .background(isUser ? Color.blue.opacity(0.3) : Color.clear)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            if !isUser { Spacer() }
        }
    }
}

struct GlassmorphismPill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassmorphismPill() -> some View {
        modifier(GlassmorphismPill())
    }
}

struct GlassmorphismPanel: ViewModifier {
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassmorphismPanel(cornerRadius: cornerRadius))
    }
}
