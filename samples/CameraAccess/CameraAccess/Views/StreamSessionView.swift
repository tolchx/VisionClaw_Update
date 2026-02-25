/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// StreamSessionView.swift
//
//

import MWDATCamera
import MWDATCore
import SwiftUI
import UIKit

struct StreamSessionView: View {
  let wearables: WearablesInterface
  @ObservedObject private var wearablesViewModel: WearablesViewModel
  @StateObject private var viewModel: StreamSessionViewModel
  @StateObject private var geminiVM = GeminiSessionViewModel()
  @StateObject private var webrtcVM = WebRTCSessionViewModel()
  @State private var isMenuOpen: Bool = false
  @State private var showSettings: Bool = false

  init(wearables: WearablesInterface, wearablesVM: WearablesViewModel) {
    self.wearables = wearables
    self.wearablesViewModel = wearablesVM
    self._viewModel = StateObject(wrappedValue: StreamSessionViewModel(wearables: wearables))
  }

  var body: some View {
    ZStack {
      // 1. Main View (Background)
      Group {
          StreamView(viewModel: viewModel, wearablesVM: wearablesViewModel, geminiVM: geminiVM, webrtcVM: webrtcVM, isMenuOpen: $isMenuOpen)
      }
      .scaleEffect(isMenuOpen ? 0.95 : 1.0)
      .blur(radius: isMenuOpen ? 2 : 0)
      .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isMenuOpen)
      .disabled(isMenuOpen)
      
      // 2. Lateral Menu (Overlay)
      HamburgerMenuView(isOpen: $isMenuOpen, showSettings: $showSettings, viewModel: viewModel, wearablesVM: wearablesViewModel)
    }
    .task {
      viewModel.geminiSessionVM = geminiVM
      viewModel.webrtcSessionVM = webrtcVM
      geminiVM.streamingMode = viewModel.streamingMode
      
      // Auto-start streaming on load if not already started
      if !viewModel.isStreaming {
          await viewModel.handleStartStreaming()
      }
    }
    .onChange(of: viewModel.streamingMode) { _, newMode in
      geminiVM.streamingMode = newMode
    }
    .onAppear {
      UIApplication.shared.isIdleTimerDisabled = true
    }
    .onDisappear {
      UIApplication.shared.isIdleTimerDisabled = false
    }
    .alert("Error", isPresented: $viewModel.showError) {
      Button("OK") {
        viewModel.dismissError()
      }
    } message: {
      Text(viewModel.errorMessage)
    }
    .sheet(isPresented: $showSettings) {
      SettingsView()
    }
  }
}

// MARK: - Appended Views for compilation

struct HamburgerMenuView: View {
    @Binding var isOpen: Bool
    @Binding var showSettings: Bool
    @ObservedObject var viewModel: StreamSessionViewModel
    @ObservedObject var wearablesVM: WearablesViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Dimmed background
                if isOpen {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { isOpen = false } }
                }
                
                // Menu Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Header
                        HStack {
                            Image(systemName: "visionpro")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                            Text("VisionClaw")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.top, 60)
                        
                        // Connection Status Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CONNECTION")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                            
                            StatusRow(title: "Meta AI Registration", 
                                      status: wearablesVM.registrationState == .registered ? "Connected" : (wearablesVM.registrationState == .registering ? "Connecting..." : "Not Connected"),
                                      icon: wearablesVM.registrationState == .registered ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                                      color: wearablesVM.registrationState == .registered ? .green : .orange)
                            
                            StatusRow(title: "Device Availability", 
                                      status: viewModel.hasActiveDevice ? "Glasses Found" : "Searching...",
                                      icon: viewModel.hasActiveDevice ? "eyeglasses" : "antenna.radiowaves.left.and.right",
                                      color: viewModel.hasActiveDevice ? .green : .gray)
                            
                            if wearablesVM.registrationState != .registered {
                                Button(action: {
                                    wearablesVM.connectGlasses()
                                    withAnimation { isOpen = false }
                                }) {
                                    HStack {
                                        Image(systemName: "link.badge.plus")
                                        Text("Connect My Glasses")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        
                        // Streaming Controls
                        VStack(alignment: .leading, spacing: 15) {
                            Text("STREAMING")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                            
                            // Glasses Control
                            ControlRow(title: "Glasses Stream",
                                       icon: "eyeglasses",
                                       isActive: viewModel.streamingMode == .glasses && viewModel.isStreaming,
                                       isDisabled: wearablesVM.registrationState != .registered) {
                                Task {
                                    if viewModel.streamingMode == .glasses && viewModel.isStreaming {
                                        await viewModel.stopSession()
                                    } else {
                                        await viewModel.handleStartStreaming()
                                    }
                                    withAnimation { isOpen = false }
                                }
                            }
                            
                            // iPhone Control
                            ControlRow(title: "iPhone Camera",
                                       icon: "iphone",
                                       isActive: viewModel.streamingMode == .iPhone && viewModel.isStreaming) {
                                Task {
                                    if viewModel.streamingMode == .iPhone && viewModel.isStreaming {
                                        await viewModel.stopSession()
                                    } else {
                                        await viewModel.handleStartIPhone()
                                    }
                                    withAnimation { isOpen = false }
                                }
                            }
                        }
                        
                        // App Features (Restored from Home)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("FEATURES")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                            
                            FeatureMiniItem(icon: "video.fill", title: "Video Point-of-View")
                            FeatureMiniItem(icon: "waveform", title: "Open-Ear Assistant")
                            FeatureMiniItem(icon: "figure.walk", title: "Hands-Free Mobility")
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Common Options
                        VStack(alignment: .leading, spacing: 20) {
                            MenuOption(icon: "gearshape.fill", title: "Settings", color: .white) {
                                withAnimation { isOpen = false }
                                showSettings = true
                            }
                            
                            MenuOption(icon: "power", title: "Unregister Device", color: .red) {
                                wearablesVM.disconnectGlasses()
                                withAnimation { isOpen = false }
                            }
                        }
                        
                        Spacer()
                        
                        Text("VisionClaw v1.1.0")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 25)
                }
                .frame(width: geometry.size.width * 0.85)
                .background(
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                        .ignoresSafeArea()
                )
                .offset(x: isOpen ? 0 : -geometry.size.width * 0.85)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isOpen)
            }
        }
    }
}

struct StatusRow: View {
    let title: String
    let status: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(status)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            Spacer()
            Image(systemName: icon)
                .foregroundColor(color)
        }
    }
}

struct ControlRow: View {
    let title: String
    let icon: String
    let isActive: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 30)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(isActive ? "STOP" : "START")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isActive ? Color.red : Color.blue)
                    .cornerRadius(8)
            }
            .foregroundColor(isDisabled ? .gray : .white)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

struct FeatureMiniItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 14))
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue.opacity(0.1)))
            Text(title)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct MenuOption: View {
    let icon: String
    let title: String
    var color: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
        }
    }
}
