//
//  StandardFloatingButton.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import SwiftUI

struct StandardFloatingButton: View {
    var icon: String
    var color: Color = .blue
    var action: () -> Void
    
    // For expandable menu support
    var isOpen: Binding<Bool>? = nil
    var menuItems: [StandardFloatingMenuItem] = []
    
    var accessibilityIdentifier: String? = nil
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                ZStack(alignment: .bottomTrailing) {
                    // Menu Items (if any)
                    if let isOpenBinding = isOpen, isOpenBinding.wrappedValue {
                        VStack(alignment: .trailing, spacing: 12) {
                            ForEach(menuItems) { item in
                                Button(action: {
                                    item.action()
                                    withAnimation {
                                        isOpenBinding.wrappedValue = false
                                    }
                                }) {
                                    HStack {
                                        Text(item.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(UIColor.systemBackground))
                                            .cornerRadius(8)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        
                                        ZStack {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 44, height: 44)
                                                .shadow(color: item.color.opacity(0.3), radius: 4, x: 0, y: 2)
                                            
                                            Image(systemName: item.icon)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.bottom, 70) // Space for main button
                    }
                    
                    // Main Button
                    Button(action: {
                        if isOpen != nil {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isOpen?.wrappedValue.toggle()
                            }
                        } else {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            action()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 56, height: 56)
                                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(isOpen?.wrappedValue == true ? 45 : 0))
                        }
                    }
                    .accessibilityIdentifier(accessibilityIdentifier ?? icon)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 130) // Increased for better separation from BottomBar
        }
    }
}

struct StandardFloatingMenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
}
