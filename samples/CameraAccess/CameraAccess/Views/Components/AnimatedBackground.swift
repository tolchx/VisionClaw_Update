import SwiftUI

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
