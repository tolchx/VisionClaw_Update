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
            HStack(spacing: 0) {
                // Menu Content
                VStack(alignment: .leading, spacing: 30) {
                    HStack {
                        Image(systemName: "visionpro")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("OpenVision")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stream Quality")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Picker("Resolution", selection: Binding(
                            get: { viewModel.selectedResolution },
                            set: { viewModel.updateResolution($0) }
                        )) {
                            Text("Low").tag(StreamingResolution.low)
                            Text("Med").tag(StreamingResolution.medium)
                            Text("High").tag(StreamingResolution.high)
                        }
                        .pickerStyle(.segmented)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    MenuOption(icon: viewModel.streamingMode == .iPhone ? "eyeglasses" : "iphone", 
                               title: viewModel.streamingMode == .iPhone ? "Start Glasses" : "Start iPhone",
                               color: .white) {
                        Task {
                            if viewModel.streamingMode == .iPhone {
                                await viewModel.stopSession()
                                await viewModel.handleStartStreaming()
                            } else {
                                await viewModel.stopSession()
                                await viewModel.handleStartIPhone()
                            }
                            withAnimation { isOpen = false }
                        }
                    }
                    
                    MenuOption(icon: "gearshape.fill", title: "Settings", color: .white) {
                        withAnimation { isOpen = false }
                        showSettings = true
                    }
                    
                    MenuOption(icon: "power", title: "Disconnect", color: .red) {
                        wearablesVM.disconnectGlasses()
                        withAnimation { isOpen = false }
                    }
                    
                    Spacer()
                    
                    Text("v1.0.0")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 30)
                .frame(width: geometry.size.width * 0.75, alignment: .leading)
                .background(
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                        .opacity(0.9)
                        .ignoresSafeArea()
                )
                .offset(x: isOpen ? 0 : -geometry.size.width * 0.75)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isOpen)
                
                // Transparent dismiss area
                if isOpen {
                    Color.black.opacity(0.001)
                        .onTapGesture {
                            withAnimation {
                                isOpen = false
                            }
                        }
                }
            }
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
