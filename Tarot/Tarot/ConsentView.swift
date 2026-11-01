//
//  ConsentView.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI

struct ConsentView: View {
    var onAgree: () -> Void
    var onDecline: () -> Void

    private let privacyURL = URL(string: "https://the-read-proxy.theread-app.workers.dev/privacy")!

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .ultraLight))
                    .foregroundStyle(Theme.gold.opacity(0.7))

                Text("BEFORE YOUR FIRST READING")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .kerning(3)

                Text("How your readings are made")
                    .font(.system(size: 26, weight: .light, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    Text("Each reading is written by an AI service. To write it, the cards you draw and any question you ask are sent securely to Anthropic, the company behind Claude.")
                    Text("Nothing else leaves your phone, and your journal stays on this device.")
                }
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.65))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                Link("Read the privacy policy", destination: privacyURL)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Theme.gold.opacity(0.8))

                Spacer()

                Button {
                    Haptics.tap()
                    onAgree()
                } label: {
                    Text("I UNDERSTAND AND AGREE")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .kerning(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.gold.opacity(0.35), lineWidth: 0.5))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Button(action: onDecline) {
                    Text("NOT NOW")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .kerning(3)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
    }
}
