//
//  ReadingComponents.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//


import SwiftUI

struct DrawnCard: Identifiable {
    let id = UUID()
    let card: TarotCard
    let isReversed: Bool
    let position: String
}

struct SpreadButton: View {
    let label: String
    let sublabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 4) {
                Text(label)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                Text(sublabel)
                    .font(.system(size: 9, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct CardRow: View {
    let drawn: DrawnCard
    var reading: String? = nil
    var isLoadingReading: Bool = false
    var onImageTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(drawn.position.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .kerning(2)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(drawn.card.name)
                            .font(.system(size: 17, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                        if drawn.isReversed {
                            Text("reversed")
                                .font(.system(size: 11, weight: .light, design: .serif))
                                .foregroundStyle(.white.opacity(0.4))
                                .italic()
                        }
                    }
                }
                Spacer()
                if let arcana = drawn.card.arcana {
                    Text(arcana == "Major" ? "★" : "·")
                        .font(.system(size: arcana == "Major" ? 14 : 20))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }

            if let imageName = drawn.card.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .aspectRatio(2/3, contentMode: .fit)
                    .rotationEffect(drawn.isReversed ? .degrees(180) : .degrees(0))
                    .cornerRadius(6)
                    .opacity(0.9)
                    .contentShape(Rectangle())
                    .onTapGesture { onImageTap?() }
            }

            Text(drawn.isReversed ? drawn.card.reversedMeaning : drawn.card.uprightMeaning)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.white.opacity(0.4))
                .lineSpacing(3)

            if let reading, !reading.isEmpty {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.top, 4)
                Text((try? AttributedString(markdown: reading, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(reading))
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(6)
            } else if isLoadingReading {
                Text("Reading the cards…")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .kerning(2)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

struct CardFanView: View {
    let spread: [DrawnCard]
    let isHomePreview: Bool
    let spreadType: String
    var revealedCards: Set<Int> = []
    var focusedIndex: Int? = nil
    var interactive: Bool = false
    var onTap: (Int) -> Void = { _ in }

    private func revealed(_ index: Int) -> Bool {
        !interactive || revealedCards.contains(index)
    }

    private var nextIndex: Int? {
        (0..<spread.count).first { !revealedCards.contains($0) }
    }

    private func tile(_ i: Int, width: CGFloat, cornerRadius: CGFloat = 6) -> some View {
        let isRevealed = revealed(i)
        let locked = interactive && !isRevealed && i != nextIndex
        let dimmed = interactive && isRevealed && focusedIndex != nil && focusedIndex != i

        return FlipCard(imageName: spread[i].card.imageName, isReversed: spread[i].isReversed,
                        width: width, revealed: isRevealed, cornerRadius: cornerRadius)
            .saturation(locked ? 0.35 : 1)
            .opacity(locked ? 0.45 : (dimmed ? 0.6 : 1))
            .animation(.easeInOut(duration: 0.25), value: focusedIndex)
            .animation(.easeInOut(duration: 0.25), value: revealedCards)
            .contentShape(Rectangle())
            .onTapGesture { if interactive { onTap(i) } }
            .fadeSlideIn(delay: Double(i) * 0.25)
    }

    var body: some View {
        let count = spread.count
        if count == 1 {
            tile(0, width: 120)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else if count <= 4 {
            if spreadType == "clarity" {
                VStack(spacing: 12) {
                    tile(0, width: 78)
                    HStack(spacing: 12) {
                        ForEach(1..<count, id: \.self) { i in
                            tile(i, width: 78)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 12) {
                    ForEach(0..<count, id: \.self) { i in
                        tile(i, width: count == 3 ? 90 : 78)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        } else {
            if isHomePreview {
                let arcAngles: [Double] = [-20, -10, 0, 10, 20]
                let arcOffsets: [CGFloat] = [-85, -42, 0, 42, 85]
                let arcVertical: [CGFloat] = [20, 8, 0, 8, 20]

                ZStack {
                    ForEach(Array(spread.enumerated()), id: \.offset) { index, drawn in
                        FlipCard(imageName: drawn.card.imageName, isReversed: drawn.isReversed,
                                 width: 72, revealed: true)
                            .rotationEffect(.degrees(arcAngles[index]))
                            .offset(x: arcOffsets[index], y: arcVertical[index])
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                let drops: [CGFloat] = [0, 19, 38, 19, 0]

                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        tile(i, width: 58, cornerRadius: 5)
                            .padding(.top, drops[i])
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
}
