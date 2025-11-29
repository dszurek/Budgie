//
//  OptionButton.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/6/25.
//

import SwiftUI
import FloatingButton

struct OptionButton: View {
    
    var imageName: String
    var buttonText: String
    let imageWidth: CGFloat = 22
    
    var body: some View {
        ZStack {
            // Liquid Glass background
            Color.white.opacity(0.9)
            
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .foregroundColor(Color(hex: "778ca3"))
                    .frame(width: imageWidth, height: imageWidth)
                    .clipped()
                Spacer()
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(Color(hex: "4b6584"))
                Spacer()
            }
            .padding(.horizontal, 15)
        }
        .frame(width: 160, height: 45)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}
