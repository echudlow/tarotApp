//
//  SpecialDayAnnouncement.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/3/26.
//
//  A full page shown when a limited-time read opens: what it is, when it closes,
//  and how to approach it. Shown once per opening.

import SwiftUI

struct SpecialDayAnnouncement: View {
    let spreadID: String
    var onDismiss: () -> Void
    var onBegin: () -> Void

    private var spread: SpreadDefinition { SpreadDefinition.with(id: spreadID) }

    private var copy: (eyebrow: String, title: String, intro: String, steps: [String]) {
        switch spreadID {
        case "full_moon":
            return ("THE MOON IS FULL", "A read for seeing clearly",
                    "At its brightest, the moon lights up what is usually in shadow. This read looks at you: your gifts, what fills you up, and what you have not noticed yet.",
                    ["Find a quiet moment, ideally tonight.",
                     "Take a breath and think about how you see yourself right now.",
                     "Turn the five cards one at a time, and let each one settle before the next."])
        case "new_moon":
            return ("A NEW MOON", "A read for beginnings",
                    "The dark of the moon is a good time to plant something. This read looks at what you want to bring in, and where to put your attention.",
                    ["Think of one thing you want to begin or invite in.",
                     "Keep it simple and honest. One wish is enough.",
                     "Turn the five cards in order. Each one shows part of the way toward it."])
        case "year_ahead":
            return ("THE YEAR TURNS", "A read for the year ahead",
                    "Thirteen cards: one for each month, and one for the year as a whole. It only opens around New Year's Eve.",
                    ["Take a quiet moment and let the old year go.",
                     "Turn the cards slowly, January first, one month at a time.",
                     "The last card, in the middle, is the theme of the year. Save it for the end."])
        default:
            return ("OPEN NOW", spread.title, spread.blurb, [])
        }
    }

    var body: some View {
        let c = copy
        ZStack {
            Color.black.ignoresSafeArea()

            // a soft gold glow behind the glyph
            RadialGradient(colors: [Theme.gold.opacity(0.16), .clear],
                           center: .center, startRadius: 4, endRadius: 220)
                .frame(width: 440, height: 440)
                .offset(y: -190)
                .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 22) {
                    SpreadGlyph(spreadID: spreadID)
                        .scaleEffect(1.7)
                        .frame(width: 110, height: 100)
                        .padding(.top, 64)
                        .padding(.bottom, 8)

                    Text(c.eyebrow)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.gold)
                        .kerning(4)

                    Text(c.title)
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(SpecialDays.closesLabel(spreadID))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .kerning(2)

                    Text(c.intro)
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)

                    if !c.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("HOW TO DO IT")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                                .kerning(3)
                            ForEach(Array(c.steps.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .firstTextBaseline, spacing: 14) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 13, weight: .light, design: .serif))
                                        .foregroundStyle(Theme.gold)
                                        .frame(width: 14)
                                    Text(step)
                                        .font(.system(size: 14, weight: .light, design: .serif))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.gold.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.gold.opacity(0.3), lineWidth: 0.6))
                        )
                        .padding(.top, 8)
                    }

                    Button {
                        Haptics.tap()
                        onBegin()
                    } label: {
                        Text("BEGIN THE READ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.9))
                            .kerning(3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Theme.gold.opacity(0.14))
                                    .overlay(RoundedRectangle(cornerRadius: 6)
                                        .stroke(Theme.gold.opacity(0.6), lineWidth: 0.7))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)

                    Button {
                        Haptics.tap()
                        onDismiss()
                    } label: {
                        Text("NOT NOW")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .kerning(3)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
    }
}
