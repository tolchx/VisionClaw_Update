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
  @State private var showPiP = true
  @State private var pipPosition = CGPoint(x: UIScreen.main.bounds.width - 90, y: 150)
  @State private var messageInput: String = ""

  var body: some View {
    ZStack {
      backgroundLayers
      
      VStack(spacing: 0) {
        topBar
        chatHistory
        Spacer()
        bottomControls
      }
      
      floatingPiP
      pipToggleButton
    }
    .onDisappear {
      cleanupSessions()
    }
    .sheet(isPresented: $viewModel.showPhotoPreview) {
      photoPreviewSheet
    }
    .alert("AI Assistant", isPresented: alertBinding(for: $geminiVM.errorMessage)) {
      Button("OK") { geminiVM.errorMessage = nil }
    } message: {
      Text(geminiVM.errorMessage ?? "")
    }
    .alert("Live Stream", isPresented: alertBinding(for: $webrtcVM.errorMessage)) {
      Button("OK") { webrtcVM.errorMessage = nil }
    } message: {
      Text(webrtcVM.errorMessage ?? "")
    }
  }

  // MARK: - Subviews

  private var backgroundLayers: some View {
    ZStack {
      AnimatedBackground()
      ParticleEffect(particleCount: 30).opacity(0.5)
      
      if !webrtcVM.isActive || webrtcVM.connectionState != .connected {
          if viewModel.currentVideoFrame == nil || !viewModel.hasReceivedFirstFrame {
              ProgressView()
                  .scaleEffect(1.5)
                  .foregroundColor(.white)
          }
      }
    }
  }

  private var topBar: some View {
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
        
        Color.clear.frame(width: 44, height: 44)
    }
    .padding()
  }

  private var chatHistory: some View {
    ScrollViewReader { proxy in
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(geminiVM.messages) { message in
                    ChatMessageBubble(text: message.text, isUser: message.role == .user)
                }

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
        .onChange(of: geminiVM.messages.count) { _ in
            withAnimation { proxy.scrollTo("bottomSpacer", anchor: .bottom) }
        }
        .onChange(of: geminiVM.userTranscript) { _ in
            withAnimation { proxy.scrollTo("bottomSpacer", anchor: .bottom) }
        }
        .onChange(of: geminiVM.aiTranscript) { _ in
            withAnimation { proxy.scrollTo("bottomSpacer", anchor: .bottom) }
        }
    }
  }

  private var bottomControls: some View {
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

        ControlsView(viewModel: viewModel, geminiVM: geminiVM, webrtcVM: webrtcVM, messageInput: $messageInput)
    }
    .padding(.bottom, 8)
  }

  @ViewBuilder
  private var floatingPiP: some View {
    if showPiP {
        if webrtcVM.isActive && webrtcVM.connectionState == .connected {
            DraggablePiPView(position: $pipPosition, isShowing: $showPiP) {
                PiPVideoView(
                    localFrame: viewModel.currentVideoFrame,
                    remoteVideoTrack: webrtcVM.remoteVideoTrack,
                    hasRemoteVideo: webrtcVM.hasRemoteVideo
                )
            }
        } else if let videoFrame = viewModel.currentVideoFrame, viewModel.hasReceivedFirstFrame {
            DraggablePiPView(position: $pipPosition, isShowing: $showPiP) {
                Image(uiImage: videoFrame)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }
  }

  @ViewBuilder
  private var pipToggleButton: some View {
    if !showPiP && ((viewModel.currentVideoFrame != nil && viewModel.hasReceivedFirstFrame) || (webrtcVM.isActive && webrtcVM.connectionState == .connected)) {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { withAnimation { showPiP = true } }) {
                    Image(systemName: "video.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(.ultraThinMaterial))
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .padding()
            }
        }
    }
  }

  @ViewBuilder
  private var photoPreviewSheet: some View {
    if let photo = viewModel.capturedPhoto {
      PhotoPreviewView(photo: photo, onDismiss: { viewModel.dismissPhotoPreview() })
    }
  }

  private func alertBinding(for message: Binding<String?>) -> Binding<Bool> {
    Binding(
      get: { message.wrappedValue != nil },
      set: { if !$0 { message.wrappedValue = nil } }
    )
  }

  private func cleanupSessions() {
    Task {
      if viewModel.streamingStatus != .stopped { await viewModel.stopSession() }
      if geminiVM.isGeminiActive { geminiVM.stopSession() }
      if webrtcVM.isActive { webrtcVM.stopSession() }
    }
  }
}

// Extracted controls for clarity
struct ControlsView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var geminiVM: GeminiSessionViewModel
  @ObservedObject var webrtcVM: WebRTCSessionViewModel
  @Binding var messageInput: String

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
    VStack(spacing: 16) {
      // 1. Utility Buttons Row (Secondary actions)
      HStack(spacing: 25) {
        // Stop Button
        Button(action: {
            Task { await viewModel.stopSession() }
        }) {
            Image(systemName: "stop.fill")
                .foregroundColor(.red)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }

        // Camera Button (if using glasses)
        if viewModel.streamingMode == .glasses {
          Button(action: {
              viewModel.capturePhoto()
          }) {
              Image(systemName: "camera.fill")
                  .foregroundColor(.white)
                  .font(.title3)
                  .frame(width: 44, height: 44)
                  .background(Circle().fill(.ultraThinMaterial))
                  .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
          }
        }

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
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(Circle().fill(webrtcVM.isActive ? AnyShapeStyle(Color.blue) : AnyShapeStyle(.ultraThinMaterial)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .opacity(geminiVM.isGeminiActive ? 0.4 : 1.0)
        .disabled(geminiVM.isGeminiActive)
      }
      .padding(.top, 8)

      // 2. Chat Interaction Row (Main action)
      HStack(spacing: 12) {
        // Gemini AI / Mic Button
        Button(action: {
          Task {
            if geminiVM.isGeminiActive {
              geminiVM.stopSession()
            } else {
              await geminiVM.startSession()
            }
          }
        }) {
            ZStack {
                Circle()
                    .fill(micColor)
                    .frame(width: 48, height: 48)
                
                Image(systemName: geminiVM.isGeminiActive ? "waveform" : "mic.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
            .shadow(color: micColor.opacity(0.3), radius: 6)
        }
        .opacity(webrtcVM.isActive ? 0.4 : 1.0)
        .disabled(webrtcVM.isActive)

        // Full-Width Text Input Box
        HStack {
            TextField("Type message...", text: $messageInput)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }
            
            if !messageInput.isEmpty {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 32))
                        .padding(.trailing, 8)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.15), lineWidth: 1))
        )
        .animation(.spring(), value: messageInput.isEmpty)
      }
      .padding(.horizontal)
    }
  }
  
  private func sendMessage() {
      let text = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !text.isEmpty else { return }
      messageInput = ""
      geminiVM.sendTextMessage(text)
  }
}

// MARK: - Appended Views for compilation

struct DraggablePiPView<Content: View>: View {
    @Binding var position: CGPoint
    @Binding var isShowing: Bool
    let content: Content
    
    init(position: Binding<CGPoint>, isShowing: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._position = position
        self._isShowing = isShowing
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .frame(width: 120, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Button(action: {
                withAnimation { isShowing = false }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding(6)
        }
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    position = value.location
                }
                .onEnded { value in
                    // Basic bounds clamping so it doesn't get lost off-screen
                    let screen = UIScreen.main.bounds
                    let newX = max(60, min(value.location.x, screen.width - 60))
                    let newY = max(100, min(value.location.y, screen.height - 100))
                    withAnimation(.spring()) {
                        position = CGPoint(x: newX, y: newY)
                    }
                }
        )
    }
}

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
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer() }
            
            // AI Sparkles Avatar
            if !isUser {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .purple.opacity(0.5), radius: 4)
            }
            
            Text(text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(isUser ? 0.2 : 0.1))
                )
                .background(isUser ? Color.blue.opacity(0.1) : Color.purple.opacity(0.05))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isUser ? Color.blue.opacity(0.3) : Color.purple.opacity(0.3), lineWidth: 1)
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
