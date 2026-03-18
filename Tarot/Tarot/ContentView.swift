//  ContentView.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/10/25.
//

import SwiftUI
import SwiftData

struct DrawnCard: Identifiable {
    let id = UUID()
    let card: TarotCard
    let isReversed: Bool
    let position: String
}

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \TarotCard.name) var cards: [TarotCard]
    
    @State private var spread: [DrawnCard] = []
    @State private var interpretation: String? = nil
    @State private var isLoadingInterpretation: Bool = false
    @State private var interpretationError: String? = nil
    @State private var interpretTask: Task<Void, Never>? = nil
    @State private var activeRequestID = UUID()
    
    private let tarotService = TarotService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TAROT")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                                .kerning(4)
                            Text("The Reading")
                                .font(.system(size: 34, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 8)
                        
                        // MARK: - Spread Buttons
                        HStack(spacing: 10) {
                            SpreadButton(label: "Daily", sublabel: "1 card") {
                                drawSpread(spreadType: "daily", positions: ["Daily Card"])
                            }
                            SpreadButton(label: "Three", sublabel: "Past · Present · Future") {
                                drawSpread(spreadType: "three_card", positions: ["Past", "Present", "Future"])
                            }
                            SpreadButton(label: "Four", sublabel: "Situation spread") {
                                drawSpread(spreadType: "four_card", positions: ["Past", "Present", "Future", "Current Situation"])
                            }
                        }
                        
                        // MARK: - Current Spread
                        if spread.isEmpty {
                            VStack(spacing: 12) {
                                Text("✦")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.2))
                                Text("Choose a spread to begin")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(spread) { drawn in
                                    CardRow(drawn: drawn)
                                }
                            }
                            
                            // MARK: - Interpretation
                            VStack(alignment: .leading, spacing: 16) {
                                Rectangle()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 1)
                                
                                if isLoadingInterpretation {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                            .tint(.white.opacity(0.5))
                                        Text("Reading the cards…")
                                            .font(.system(size: 13, weight: .light))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    .padding(.vertical, 8)
                                    
                                } else if let error = interpretationError {
                                    Text("Could not interpret this spread: \(error)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.red.opacity(0.7))
                                    
                                } else if let text = interpretation {
                                    Text("INTERPRETATION")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.35))
                                        .kerning(3)
                                    
                                    Text(parseMarkdown(text))
                                        .font(.system(size: 15, weight: .light, design: .serif))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .lineSpacing(6)
                                }
                            }
                        }
                        
                        // MARK: - Deck Link
                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(height: 1)
                        NavigationLink(destination: HistoryView()) {
                            HStack {
                                Text("READING HISTORY")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .kerning(3)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                        }

                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(height: 1)
                        NavigationLink(destination: AllCardsView()) {
                            HStack {
                                Text("VIEW ALL CARDS")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .kerning(3)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .task {
            seedTarotDeckIfNeeded()
        }
    }
    
    // MARK: - Markdown parser
    private func parseMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
    
    // MARK: - Spread logic
    private func drawSpread(spreadType: String, positions: [String]) {
        guard cards.count >= positions.count else { return }
        
        let selected = Array(cards.shuffled().prefix(positions.count))
        let newSpread: [DrawnCard] = selected.enumerated().map { index, card in
            DrawnCard(card: card, isReversed: Bool.random(), position: positions[index])
        }
        
        spread = newSpread
        interpretation = nil
        interpretationError = nil
        isLoadingInterpretation = true
        interpretTask?.cancel()
        
        let requestID = UUID()
        activeRequestID = requestID
        
        interpretTask = Task {
            await interpretSpreadSnapshot(spreadType: spreadType, spreadSnapshot: newSpread, requestID: requestID)
        }
    }
    
    private func interpretSpreadSnapshot(spreadType: String, spreadSnapshot: [DrawnCard], requestID: UUID) async {
        defer {
            if activeRequestID == requestID {
                isLoadingInterpretation = false
            }
        }
        if Task.isCancelled { return }
        
        let apiCards: [TarotAPICard] = spreadSnapshot.map { drawn in
            TarotAPICard(
                name: drawn.card.name,
                position: drawn.position,
                isReversed: drawn.isReversed,
                uprightMeaning: drawn.card.uprightMeaning,
                reversedMeaning: drawn.card.reversedMeaning,
                suit: drawn.card.suit,
                arcana: drawn.card.arcana
            )
        }
        
        let body = SpreadRequestBody(spread_type: spreadType, cards: apiCards)
        
        do {
            let response = try await tarotService.interpretSpread(body)
            guard activeRequestID == requestID else { return }
            interpretation = response.interpretation
            // Save to history
            let reading = Reading(
                spreadType: spreadType,
                cardNames: spreadSnapshot.map { $0.card.name },
                cardPositions: spreadSnapshot.map { $0.position },
                cardReversals: spreadSnapshot.map { $0.isReversed },
                interpretation: response.interpretation
            )
            modelContext.insert(reading)
            try? modelContext.save()
        } catch {
            guard !Task.isCancelled else { return }
            guard activeRequestID == requestID else { return }
            interpretationError = error.localizedDescription
            print("Interpretation error:", error)
        }
    }
    // MARK: - Subviews
    
    struct SpreadButton: View {
        let label: String
        let sublabel: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(.white)
                    Text(sublabel)
                        .font(.system(size: 9, weight: .light))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                        .frame(maxWidth: .infinity)
                        .aspectRatio(2/3,contentMode: .fit)
                        .rotationEffect(drawn.isReversed ? .degrees(180) : .degrees(0))
                        .cornerRadius(6)
                        .opacity(0.9)
                        .clipped()
                }
                
                Text(drawn.isReversed ? drawn.card.reversedMeaning : drawn.card.uprightMeaning)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineSpacing(3)
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
        
        #Preview {
            ContentView()
                .modelContainer(for: TarotCard.self, inMemory: true)
        }
    }
}
