import SwiftUI

struct ChatMessageBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if !isUser {
                // AI Icon (Sparkle)
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .shadow(color: .purple.opacity(0.5), radius: 4)
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.bottom, 4)
            } else {
                Spacer()
            }
            
            Text(text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .background(
                    Group {
                        if isUser {
                            Color.blue.opacity(0.25)
                        } else {
                            Color.purple.opacity(0.15)
                                .shadow(color: .purple.opacity(0.3), radius: 8)
                        }
                    }
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isUser ? Color.white.opacity(0.15) : Color.purple.opacity(0.3), lineWidth: 1)
                )
            
            if isUser {
                // Potential user avatar space or just spacer
            } else {
                Spacer()
            }
        }
    }
}
