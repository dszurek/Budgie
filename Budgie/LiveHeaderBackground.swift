//
//  LiveHeaderBackground.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import SwiftUI

struct LiveHeaderBackground: View {
    var color: Color
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Strong Gradient Background (for contrast)
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.9),           // Very strong at top
                    color.opacity(0.5),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Animated Blobs (Overlay)
            GeometryReader { geometry in
                ZStack {
                    // Blob 1
                    Circle()
                        .fill(Color.white.opacity(0.25)) // More visible
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6) // Smaller
                        .blur(radius: 30)
                        .offset(x: animate ? -30 : 30, y: animate ? -30 : 30)
                        .scaleEffect(animate ? 1.1 : 0.9)
                    
                    // Blob 2
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4) // Smaller
                        .blur(radius: 25)
                        .offset(x: animate ? 40 : -40, y: animate ? 20 : -50)
                        .scaleEffect(animate ? 0.8 : 1.2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: 400)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

#Preview {
    LiveHeaderBackground(color: .purple)
}
