//
//  HisotryView.swift
//  Tarot
//
//  Created by Elijah Hudlow on 3/18/26.
//
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]
    @Query private var cards: [TarotCard]
    @State private var selectedReading: Reading? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HISTORY")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .kerning(4)
                        Text("Past Readings")
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)

                    if readings.isEmpty {
                        VStack(spacing: 12) {
                            Text("✦")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.2))
                            Text("No readings yet")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(readings) { reading in
                                ReadingHistoryRow(reading: reading, cards: cards)
                                    .onTapGesture {
                                        selectedReading = reading
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedReading) { reading in
            ReadingDetailSheet(reading: reading, cards: cards)
        }
    }
}

// MARK: - History Row
struct ReadingHistoryRow: View {
    let reading: Reading
    let cards: [TarotCard]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: reading.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reading.spreadDisplayName.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .kerning(2)
                    Text(formattedDate)
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.2))
            }

            // Card thumbnails
            HStack(spacing: 8) {
                ForEach(Array(reading.cardNames.enumerated()), id: \.offset) { index, name in
                    let card = cards.first(where: { $0.name == name })
                    let isReversed = reading.cardReversals.indices.contains(index) ? reading.cardReversals[index] : false

                    if let imageName = card?.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(width: 44)
                            .cornerRadius(4)
                            .rotationEffect(isReversed ? .degrees(180) : .degrees(0))
                            .opacity(0.85)
                    }
                }
                Spacer()
            }

            // Interpretation preview
            Text(reading.interpretation.replacingOccurrences(of: "**", with: ""))
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
                .lineLimit(2)
                .lineSpacing(2)
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

// MARK: - Reading Detail Sheet
struct ReadingDetailSheet: View {
    let reading: Reading
    let cards: [TarotCard]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: reading.date)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Handle
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.2))
                            .frame(width: 36, height: 4)
                        Spacer()
                    }
                    .padding(.top, 12)

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reading.spreadDisplayName.uppercased())
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                            .kerning(3)
                        Text(formattedDate)
                            .font(.system(size: 22, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                    }

                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(height: 1)

                    // Cards
                    VStack(spacing: 16) {
                        ForEach(Array(reading.cardNames.enumerated()), id: \.offset) { index, name in
                            let card = cards.first(where: { $0.name == name })
                            let position = reading.cardPositions.indices.contains(index) ? reading.cardPositions[index] : ""
                            let isReversed = reading.cardReversals.indices.contains(index) ? reading.cardReversals[index] : false

                            HStack(spacing: 14) {
                                if let imageName = card?.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(2/3, contentMode: .fit)
                                        .frame(width: 60)
                                        .cornerRadius(6)
                                        .rotationEffect(isReversed ? .degrees(180) : .degrees(0))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(position.uppercased())
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.35))
                                        .kerning(2)
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text(name)
                                            .font(.system(size: 16, weight: .light, design: .serif))
                                            .foregroundStyle(.white)
                                        if isReversed {
                                            Text("reversed")
                                                .font(.system(size: 11, weight: .light, design: .serif))
                                                .foregroundStyle(.white.opacity(0.4))
                                                .italic()
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                    }

                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(height: 1)

                    // Interpretation
                    VStack(alignment: .leading, spacing: 10) {
                        Text("INTERPRETATION")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                            .kerning(3)

                        Text(parseMarkdown(reading.interpretation))
                            .font(.system(size: 15, weight: .light, design: .serif))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineSpacing(6)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func parseMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
}
