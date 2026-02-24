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

  init(wearables: WearablesInterface, wearablesVM: WearablesViewModel) {
    self.wearables = wearables
    self.wearablesViewModel = wearablesVM
    self._viewModel = StateObject(wrappedValue: StreamSessionViewModel(wearables: wearables))
  }

  var body: some View {
    ZStack {
      // 1. Main View (Background)
      Group {
        if viewModel.isStreaming {
          StreamView(viewModel: viewModel, wearablesVM: wearablesViewModel, geminiVM: geminiVM, webrtcVM: webrtcVM, isMenuOpen: $isMenuOpen)
        } else {
          NonStreamView(viewModel: viewModel, wearablesVM: wearablesViewModel)
            .overlay(
              // Allow menu button even in NonStreamView if desired, or keep it strictly for StreamView
              VStack {
                HStack {
                  Button {
                    withAnimation { isMenuOpen.toggle() }
                  } label: {
                    Image(systemName: "line.horizontal.3")
                      .font(.title2)
                      .foregroundColor(.white)
                  }
                  .padding()
                  Spacer()
                }
                Spacer()
              }
            )
        }
      }
      .scaleEffect(isMenuOpen ? 0.95 : 1.0)
      .blur(radius: isMenuOpen ? 2 : 0)
      .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isMenuOpen)
      .disabled(isMenuOpen)
      
      // 2. Lateral Menu (Overlay)
      HamburgerMenuView(isOpen: $isMenuOpen)
    }
    .task {
      viewModel.geminiSessionVM = geminiVM
      viewModel.webrtcSessionVM = webrtcVM
      geminiVM.streamingMode = viewModel.streamingMode
    }
    .onChange(of: viewModel.streamingMode) { newMode in
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
  }
}
