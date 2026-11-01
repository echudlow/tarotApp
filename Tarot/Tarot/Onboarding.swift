//
//  Onboarding.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let pages: [(eyebrow: String, title: String, body: String)] = [
        ("WELCOME", "The Read",
         "Tarot for reflection. Draw cards, turn them one at a time, and get a reading written around what you drew."),
        ("EVERY DAY", "One card, once a day",
         "Your daily card is drawn once and stays yours until midnight. Turn it over when you are ready."),
        ("WHEN YOU WANT MORE", "Pick a read",
         "Three cards, four, a clarity spread, or ask a question of your own. Every reading is saved to your Journal.")
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 16) {
                            Spacer()
                            Text(pages[i].eyebrow)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.gold.opacity(0.7))
                                .kerning(4)
                            Text(pages[i].title)
                                .font(.system(size: 34, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(pages[i].body)
                                .font(.system(size: 15, weight: .light, design: .serif))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineSpacing(6)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                            Spacer()
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Theme.gold : .white.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 24)

                Button {
                    Haptics.tap()
                    if page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.35)) { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "NEXT" : "BEGIN")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                        .kerning(3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.gold.opacity(0.3), lineWidth: 0.5))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                Text("For reflection and entertainment. Readings are written by AI.")
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
    }
}
