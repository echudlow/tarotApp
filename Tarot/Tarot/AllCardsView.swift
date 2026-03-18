//  AllCardsView.swift
//  Tarot

import SwiftUI
import SwiftData

struct AllCardsView: View {
    @Query private var cards: [TarotCard]
    @State private var selectedCard: TarotCard? = nil
    @State private var searchText = ""

    // MARK: - Grouping logic
    var majorArcana: [TarotCard] {
        cards.filter { $0.arcana == "Major" }
             .sorted { ($0.number ?? 0) < ($1.number ?? 0) }
    }

    func minorSuit(_ suit: String) -> [TarotCard] {
        cards.filter { $0.suit == suit }
             .sorted { cardRank($0) < cardRank($1) }
    }

    func cardRank(_ card: TarotCard) -> Int {
        if let number = card.number { return number }
        // Court cards have nil number — rank by name prefix
        if card.name.hasPrefix("Page")   { return 11 }
        if card.name.hasPrefix("Knight") { return 12 }
        if card.name.hasPrefix("Queen")  { return 13 }
        if card.name.hasPrefix("King")   { return 14 }
        return 99
    }

    var sections: [(title: String, cards: [TarotCard])] {
        var result: [(String, [TarotCard])] = []
        let major = majorArcana
        if !major.isEmpty { result.append(("Major Arcana", major)) }
        for suit in ["Cups", "Wands", "Swords", "Pentacles"] {
            let s = minorSuit(suit)
            if !s.isEmpty { result.append((suit, s)) }
        }
        return result
    }

    var filteredSections: [(title: String, cards: [TarotCard])] {
        if searchText.isEmpty { return sections }
        return sections.compactMap { section in
            let filtered = section.cards.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
            return filtered.isEmpty ? nil : (section.title, filtered)
        }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DECK")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .kerning(4)
                        Text("All 78 Cards")
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.3))
                            .font(.system(size: 13))
                        TextField("Search cards...", text: $searchText)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.white)
                            .tint(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )

                    // Sections
                    ForEach(filteredSections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 14) {

                            // Section header
                            HStack {
                                Text(section.title.uppercased())
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .kerning(3)
                                Spacer()
                                Text("\(section.cards.count) cards")
                                    .font(.system(size: 10, weight: .light, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.2))
                            }

                            Rectangle()
                                .fill(.white.opacity(0.08))
                                .frame(height: 0.5)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(section.cards) { card in
                                    CardGridItem(card: card)
                                        .onTapGesture {
                                            selectedCard = card
                                        }
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
        .sheet(item: $selectedCard) { card in
            CardDetailSheet(card: card)
        }
    }
}

// MARK: - Grid Item
struct CardGridItem: View {
    let card: TarotCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let imageName = card.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .cornerRadius(6)
                    .frame(maxWidth: .infinity)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.06))
                    .aspectRatio(2/3, contentMode: .fit)
                    .overlay(
                        Text("?")
                            .foregroundStyle(.white.opacity(0.2))
                            .font(.system(size: 20, weight: .light))
                    )
            }

            Text(card.name)
                .font(.system(size: 10, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Card Detail Sheet
struct CardDetailSheet: View {
    let card: TarotCard
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Dismiss handle
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.2))
                            .frame(width: 36, height: 4)
                        Spacer()
                    }
                    .padding(.top, 12)

                    // Card image
                    if let imageName = card.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(maxWidth: 200)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                    }

                    // Card info
                    VStack(alignment: .leading, spacing: 6) {
                        if let arcana = card.arcana {
                            Text(arcana == "Major" ? "MAJOR ARCANA" : "MINOR ARCANA · \((card.suit ?? "").uppercased())")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                                .kerning(2)
                        }
                        Text(card.name)
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                    }

                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("UPRIGHT")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                                .kerning(2)
                            Text(card.uprightMeaning)
                                .font(.system(size: 14, weight: .light, design: .serif))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineSpacing(4)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("REVERSED")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                                .kerning(2)
                            Text(card.reversedMeaning)
                                .font(.system(size: 14, weight: .light, design: .serif))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineSpacing(4)
                        }

                        if !card.keywords.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("KEYWORDS")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .kerning(2)
                                FlowLayout(spacing: 8) {
                                    ForEach(card.keywords, id: \.self) { keyword in
                                        Text(keyword)
                                            .font(.system(size: 11, weight: .light))
                                            .foregroundStyle(.white.opacity(0.6))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(.white.opacity(0.06))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Flow Layout for keywords
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0) { $0 + $1 + spacing }
        return CGSize(width: proposal.width ?? 0, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(subview)
            x += size.width + spacing
        }
        return rows
    }
}

#Preview("All Cards") {
    NavigationStack {
        AllCardsView()
            .modelContainer(for: TarotCard.self, inMemory: true)
    }
}
