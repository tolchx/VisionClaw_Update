import SwiftUI

struct HamburgerMenuView: View {
    @Binding var isOpen: Bool
    
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
                    
                    MenuOption(icon: "gearshape.fill", title: "Settings") {
                        // Action for settings
                    }
                    
                    MenuOption(icon: "clock.fill", title: "History") {
                        // Action for history
                    }
                    
                    MenuOption(icon: "ladybug.fill", title: "Debug Logging") {
                        // Action for debug logging
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
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Add slight delay to let menu close if needed, or close it here
            action()
        }) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 30)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}
