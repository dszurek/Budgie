//
//  CustomLoadingView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import SwiftUI

struct CustomLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 20, height: 20)
                .scaleEffect(isAnimating ? 1.2 : 0.4)
                .opacity(isAnimating ? 1.0 : 0.3)
                .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .scaleEffect(isAnimating ? 1.2 : 0.4)
                .opacity(isAnimating ? 1.0 : 0.3)
                .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2), value: isAnimating)
            
            Circle()
                .fill(Color.purple)
                .frame(width: 20, height: 20)
                .scaleEffect(isAnimating ? 1.2 : 0.4)
                .opacity(isAnimating ? 1.0 : 0.3)
                .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4), value: isAnimating)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        CustomLoadingView()
    }
}
