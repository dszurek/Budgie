//
//  TabHeaderView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/6/25.
//

import SwiftUI

struct TabHeaderView: ViewModifier {
    let title: String
    let backgroundColor: Color
    let subTab: Bool
    var onHeaderTap: (() -> Void)? = nil  // New optional tap action

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            // 1) Header background
            backgroundColor
                .ignoresSafeArea(edges: .top)
                .frame(height: 200)
            
            // 2) Title text – if onHeaderTap is provided, attach a tap gesture.
            Text(title)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.top, subTab ? 0 : 50)
                .onTapGesture {
                    onHeaderTap?()
                }
            
            // 3) Content area, offset below header.
            VStack {
                Spacer(minLength: subTab ? 60 : 120)
                content
                    .background(Color(.systemBackground))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
            }
        }
        .animation(.easeInOut, value: subTab)
    }
}

// Helper to round only top corners
 struct RoundedCorner: Shape {
    var radius: CGFloat = 20
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    func tabHeader(
        title: String,
        backgroundColor: Color = .blue,
        subTab: Bool = false,
        onHeaderTap: (() -> Void)? = nil) -> some View {
            self.modifier(TabHeaderView(
                            title: title,
                            backgroundColor: backgroundColor,
                            subTab: subTab,
                            onHeaderTap: onHeaderTap))
        }
}


