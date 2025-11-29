//
//  AboutView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/26/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var contentBackground: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var body: some View {
        ZStack {
            contentBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Icon / Logo Placeholder
                Image(systemName: "bird.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.pink.opacity(0.1))
                            .frame(width: 160, height: 160)
                    )
                    .padding(.top, 60)
                
                VStack(spacing: 8) {
                    Text("Budgie")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Big expense budgeting, simplified.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Created by")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text("Daniel Szurek")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Link(destination: URL(string: "https://www.danielszurek.com")!) {
                        HStack {
                            Image(systemName: "globe")
                            Text("www.danielszurek.com")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.pink)
                        .cornerRadius(15)
                        .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .tint(.white) // Ensure link text is white
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}
