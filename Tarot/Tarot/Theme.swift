//
//  Theme.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI

enum Theme {
    static let gold = Color(red: 0.94, green: 0.90, blue: 0.78)
}

/// Soft black fade at the top of a screen so scrolling content does not run into the status bar.
struct TopFade: View {
    var body: some View {
        VStack {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0.0),
                    .init(color: .black.opacity(0.92), location: 0.35),
                    .init(color: .black.opacity(0.6), location: 0.6),
                    .init(color: .black.opacity(0.2), location: 0.85),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .ignoresSafeArea(edges: .top)
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

/// A quiet row with a label, an optional value, and a chevron.
struct LinkRow: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(3)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}
