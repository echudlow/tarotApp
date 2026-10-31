//
//  ShareCardView.swift
//  The Read
//
//  Created by Elijah Hudlow on 10/31/26.
//

import SwiftUI

struct ShareCardView: View {
    let spreadName: String
    let spreadType: String
    let cards: [DrawnCard]
    let question: String?
    let closingHeader: String?
    let closingText: String
    var date: Date = Date()
    var sections: [InterpretationSection] = []   // when set, shown instead of just the closing text
    var fillWidth: Bool = false                  // true in the app, false when rendering the share image
    var showFooter: Bool = true
    var onCardTap: ((DrawnCard) -> Void)? = nil

    private let contentWidth: CGFloat = 390 - 48

    private func meaning(for drawn: DrawnCard) -> String {
        drawn.isReversed ? drawn.card.reversedMeaning : drawn.card.uprightMeaning
    }

    private func markdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    private func cardTile(_ drawn: DrawnCard, width: CGFloat, nameSize: CGFloat = 10) -> some View {
        VStack(spacing: 6) {
            if let name = drawn.card.imageName {
                Image(name)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(width: width)
                    .cornerRadius(5)
                    .rotationEffect(.degrees(drawn.isReversed ? 180 : 0))
            }
            Text(drawn.card.name)
                .font(.system(size: nameSize, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .frame(width: width)
            if drawn.isReversed {
                Text("reversed")
                    .font(.system(size: nameSize - 1, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onCardTap?(drawn)
        }
    }

    @ViewBuilder
    private var spreadLayout: some View {
        if cards.count == 1, let drawn = cards.first {
            VStack(spacing: 12) {
                if let name = drawn.card.imageName {
                    Image(name)
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fit)
                        .frame(width: 120)
                        .cornerRadius(6)
                        .rotationEffect(.degrees(drawn.isReversed ? 180 : 0))
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(drawn.card.name)
                        .font(.system(size: 18, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                    if drawn.isReversed {
                        Text("reversed")
                            .font(.system(size: 12, weight: .light, design: .serif))
                            .italic()
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                Text(meaning(for: drawn))
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onCardTap?(drawn)
            }
        } else if spreadType == "clarity", cards.count == 4 {
            VStack(spacing: 16) {
                cardTile(cards[0], width: 92)
                HStack(alignment: .top, spacing: 14) {
                    ForEach(1..<4, id: \.self) { i in
                        cardTile(cards[i], width: 92)
                    }
                }
            }
        } else if cards.count == 5 {
            let drops: [CGFloat] = [0, 20, 40, 20, 0]
            HStack(alignment: .top, spacing: 10) {
                ForEach(0..<5, id: \.self) { i in
                    cardTile(cards[i], width: 60, nameSize: 8)
                        .padding(.top, drops[i])
                }
            }
        } else {
            let n = CGFloat(max(cards.count, 1))
            let w = min(96, (contentWidth - 10 * (n - 1)) / n)
            HStack(alignment: .top, spacing: 10) {
                ForEach(Array(cards.enumerated()), id: \.offset) { _, drawn in
                    cardTile(drawn, width: w)
                }
            }
        }
    }

    private var closingBlock: some View {
        VStack(alignment: .center, spacing: 8) {
            if let closingHeader {
                Text(closingHeader.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .kerning(3)
            }
            Text(markdown(closingText))
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text(spreadName.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .kerning(4)
                Text(date.formatted(.dateTime.month(.wide).day().year()))
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundStyle(.white)
                if let question, !question.isEmpty {
                    Text("\"\(question)\"")
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }

            spreadLayout

            Rectangle().fill(.white.opacity(0.12)).frame(height: 1)

            if sections.isEmpty {
                closingBlock
            } else {
                VStack(spacing: 26) {
                    ForEach(sections) { s in
                        VStack(alignment: .center, spacing: 8) {
                            Text(s.header.uppercased())
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                                .kerning(3)
                                .multilineTextAlignment(.center)
                            Text(markdown(s.body))
                                .font(.system(size: 14, weight: .light, design: .serif))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineSpacing(5)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            if showFooter {
                Text("THE READ")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
                    .kerning(4)
            }
        }
        .padding(24)
        .frame(width: fillWidth ? nil : CGFloat(390))
        .frame(maxWidth: fillWidth ? CGFloat.infinity : nil)
        .background(Color.black)
    }
}
