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
    @State private var showingQuestionInput = false
    @State private var questionText = ""
    @State private var previewCards: [DrawnCard] = []
    @State private var revealedCards: Set<Int> = []
    @State private var loadingPulse: Bool = false
    
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
                            SpreadButton(label: "Three", sublabel: "3 cards") {
                                drawSpread(spreadType: "three_card", positions: ["Past", "Present", "Future"])
                            }
                            SpreadButton(label: "Four", sublabel: "Situation spread") {
                                drawSpread(spreadType: "four_card", positions: ["Past", "Present", "Future", "Current Situation"])
                            }
                            SpreadButton(label: "Ask", sublabel: "5 card spread") {
                                showingQuestionInput = true
                            }
                        }
                        
                        // MARK: - Current Spread
                        if spread.isEmpty {
                            if !previewCards.isEmpty {
                                CardFanView(spread: previewCards, isHomePreview: true)
                                    .padding(.vertical, 24)
                            }
                            Text("Choose a spread to begin")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 24)
                        } else {
                            // Card an display
                            if spread.count > 1 {
                                CardFanView(spread: spread, isHomePreview: false)
                            }
                            
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
                                    VStack(spacing: 20) {
                                        HStack(spacing: 8) {
                                            ForEach(Array(spread.enumerated()), id: \.offset) { index, drawn in
                                                ZStack {
                                                    Image("CardBacks")
                                                        .resizable()
                                                        .aspectRatio(2/3, contentMode: .fit)
                                                        .frame(width: spread.count == 1 ? 120 : 58)
                                                        .cornerRadius(6)
                                                        .rotation3DEffect(
                                                            .degrees(revealedCards.contains(index) ? 90 : 0),
                                                            axis: (x: 0, y: 1, z: 0)
                                                        )
                                                        .opacity(revealedCards.contains(index) ? 0 : 1)
                                                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.4), value: revealedCards.contains(index))

                                                    if let imageName = drawn.card.imageName {
                                                        Image(imageName)
                                                            .resizable()
                                                            .aspectRatio(2/3, contentMode: .fit)
                                                            .frame(width: spread.count == 1 ? 120 : 58)
                                                            .cornerRadius(6)
                                                            .rotationEffect(drawn.isReversed ? .degrees(180) : .degrees(0))
                                                            .rotation3DEffect(
                                                                .degrees(revealedCards.contains(index) ? 0 : -90),
                                                                axis: (x: 0, y: 1, z: 0)
                                                            )
                                                            .opacity(revealedCards.contains(index) ? 1 : 0)
                                                            .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.4 + 0.3), value: revealedCards.contains(index))
                                                    }
                                                }
                                            }
                                        }
                                        .onAppear {
                                            for i in 0..<spread.count {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.2) {
                                                    revealedCards.insert(i)
                                                }
                                            }
                                        }
                                        .onDisappear {
                                            revealedCards.removeAll()
                                        }

                                        Text("Reading the cards…")
                                            .font(.system(size: 11, weight: .light, design: .monospaced))
                                            .foregroundStyle(.white.opacity(loadingPulse ? 0.5 : 0.2))
                                            .kerning(3)
                                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: loadingPulse)
                                            .onAppear { loadingPulse = true }
                                            .onDisappear { loadingPulse = false }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    
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
        .sheet(isPresented: $showingQuestionInput) {
            QuestionInputSheet(questionText: $questionText) { question in
                drawQuestionSpread(question: question)
            }
        }
        .task {
            seedTarotDeckIfNeeded()
            try? await Task.sleep(nanoseconds: 500_000_000)
            print("Cards count: \(cards.count), previewCards count: \(previewCards.count)")
            if previewCards.isEmpty && cards.count >= 5 {
                let selected = Array(cards.shuffled().prefix(5))
                previewCards = selected.map { card in
                    DrawnCard(card: card, isReversed: Bool.random(), position: "")
                }
                print("Seeded preview with \(previewCards.count) cards")
            }
        }
        .onChange(of: cards.count, initial: false) { _, count in
            if previewCards.isEmpty && count >= 5 {
                let selected = Array(cards.shuffled().prefix(5))
                previewCards = selected.map { card in
                    DrawnCard(card: card, isReversed: Bool.random(), position: "")
                }
            }
        }
    }
    
    // MARK: - Markdown parser
    func parseMarkdown(_ text: String) -> AttributedString {
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
    
    private func interpretSpreadSnapshot(spreadType: String, spreadSnapshot: [DrawnCard], requestID: UUID, question: String? = nil) async {
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
        
        let body = SpreadRequestBody(spread_type: spreadType, cards: apiCards, question: question)
        
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
    private func drawQuestionSpread(question: String) {
        guard cards.count >= 5 else { return }
        
        let positions = [
            "The Question",
            "The Background",
            "The Seeker",
            "The Environment",
            "The Answer"
        ]
        
        let selected = Array(cards.shuffled().prefix(5))
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
            await interpretSpreadSnapshot(
                spreadType: "question",
                spreadSnapshot: newSpread,
                requestID: requestID,
                question: question
            )
        }
    }
    
    // MARK: - Subviews
    
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
                        .aspectRatio(2/3,contentMode: .fit)
                        .rotationEffect(drawn.isReversed ? .degrees(180) : .degrees(0))
                        .cornerRadius(6)
                        .opacity(0.9)
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
    struct CardFanView: View {
        let spread: [DrawnCard]
        let isHomePreview: Bool
        
        var body: some View {
            let count = spread.count
            let _ = print("CardFanView count: \(count), isHomePreview: \(isHomePreview)")
            if count == 1 {
                // Single card — centered, no rotation
                if let imageName = spread[0].card.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fit)
                        .frame(width: 80)
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            } else if count <= 4 {
                // Straight line, evenly spaced
                HStack(spacing: 12) {
                    ForEach(Array(spread.enumerated()), id: \.offset) { _, drawn in
                        if let imageName = drawn.card.imageName {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(2/3, contentMode: .fit)
                                .frame(width: count == 3 ? 90 : 78)
                                .cornerRadius(6)
                                .rotationEffect(.degrees(drawn.isReversed ? 180 : 0))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                if isHomePreview {
                    let arcAngles: [Double] = [-20, -10, 0, 10, 20]
                    let arcOffsets: [CGFloat] = [-85, -42, 0, 42, 85]
                    let arcVertical: [CGFloat] = [20, 8, 0, 8, 20]
                    
                    ZStack {
                        ForEach(Array(spread.enumerated()), id: \.offset) { index, drawn in
                            if let imageName = drawn.card.imageName {
                                Image(imageName)
                                    .resizable()
                                    .aspectRatio(2/3, contentMode: .fit)
                                    .frame(width: 72)
                                    .cornerRadius(6)
                                    .rotationEffect(.degrees(drawn.isReversed ? 180 : 0))
                                    .rotationEffect(.degrees(arcAngles[index]))
                                    .offset(x: arcOffsets[index], y: arcVertical[index])
                                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    // V-shape layout for active 5-card spread
                        let vOffsets: [CGFloat] = [-30, -15, 0, -15, -30]
                        let spacing: CGFloat = 58
                        let totalWidth = spacing * 4
                        let startX: CGFloat = -(totalWidth / 2)
                        
                        ZStack {
                            ForEach(Array(spread.enumerated()), id: \.offset) { index, drawn in
                                if let imageName = drawn.card.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(2/3, contentMode: .fit)
                                        .frame(width: 58)
                                        .cornerRadius(5)
                                        .rotationEffect(.degrees(drawn.isReversed ? 180 : 0))
                                        .offset(x: startX + CGFloat(index) * spacing, y: vOffsets[index])
                                }
                            }
                        }
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
            }
        }
    }
}
