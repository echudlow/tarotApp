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
    @State private var currentSpreadType: String = ""
    @State private var shareItems: ShareItems? = nil
    @State private var detailCard: TarotCard? = nil
    @State private var focusedIndex: Int? = nil
    @State private var showFullReading = false
    // TODO: set to the App Store link once the app is published
    private let shareLink: String? = nil
    
    private let tarotService = TarotService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Header
                        VStack(alignment: .center, spacing: 4) {
                            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                                .kerning(4)
                            Text("Choose A Read")
                                .font(.system(size: 34, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        
                        // MARK: - Spread Buttons
                        VStack(spacing: 10) {
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
                            }
                            HStack(spacing: 10) {
                                SpreadButton(label: "Clarity", sublabel: "4 card spread") {
                                    drawSpread(spreadType: "clarity", positions: ["The Situation", "Factor One", "Factor Two", "Factor Three"])
                                }
                                SpreadButton(label: "Ask", sublabel: "5 card spread") {
                                    showingQuestionInput = true
                                }
                                SpreadButton(label: "Read Me", sublabel: "Don't hold back") {
                                    drawSpread(spreadType: "read_me", positions: ["Past", "Present", "Future", "Current Situation"])
                                }
                            }
                        }
                        
                        // MARK: - Current Spread
                        if spread.isEmpty {
                            if !previewCards.isEmpty {
                                CardFanView(spread: previewCards, isHomePreview: true, spreadType: "")
                                    .padding(.vertical, 24)
                            }
                            Text("Choose a spread to begin")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 24)
                        } else {
                            CardFanView(spread: spread, isHomePreview: false, spreadType: currentSpreadType,
                                        revealedCards: revealedCards,
                                        focusedIndex: showFullReading ? nil : focusedIndex,
                                        interactive: true, onTap: handleCardTap)
                            .id(spread.map(\.id))
                            
                            if !allRevealed {
                                Text(revealedCards.isEmpty ? "TAP THE FIRST CARD" : "TAP THE NEXT CARD")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .kerning(3)
                                    .frame(maxWidth: .infinity)
                                    .fadeSlideIn(delay: Double(spread.count) * 0.25 + 0.2)
                                    .id(spread.map(\.id))
                            }
                            
                            // Only the card you're on
                            if (!showFullReading || isSingleCard), let i = focusedIndex, spread.indices.contains(i) {
                                CardRow(drawn: spread[i],
                                        reading: section(for: spread[i])?.body,
                                        isLoadingReading: isLoadingInterpretation,
                                        onImageTap: { detailCard = spread[i].card })
                                .id(spread[i].id)
                                .transition(.opacity)
                            }
                            
                            if interpretationError != nil {
                                VStack(spacing: 14) {
                                    Text("The cards went quiet.")
                                        .font(.system(size: 17, weight: .light, design: .serif))
                                        .foregroundStyle(.white)
                                    Text("Check your connection and try again.")
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundStyle(.white.opacity(0.4))
                                    Button {
                                        retryInterpretation()
                                    } label: {
                                        Text("Try again")
                                            .font(.system(size: 13, weight: .light, design: .serif))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(.white.opacity(0.08))
                                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.15), lineWidth: 0.5))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            } else if allRevealed {
                                if isLoadingInterpretation {
                                    Text("Reading the cards…")
                                        .font(.system(size: 11, weight: .light, design: .monospaced))
                                        .foregroundStyle(.white.opacity(loadingPulse ? 0.5 : 0.2))
                                        .kerning(3)
                                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: loadingPulse)
                                        .onAppear { loadingPulse = true }
                                        .onDisappear { loadingPulse = false }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                } else if interpretation != nil {
                                    if closingVisible {
                                        VStack(alignment: .leading, spacing: 28) {
                                            Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                                            
                                            if parsedSections.count == closingSections.count, let text = interpretation {
                                                VStack(alignment: .leading, spacing: 10) {
                                                    Text("INTERPRETATION")
                                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                        .foregroundStyle(.white.opacity(0.35))
                                                        .kerning(3)
                                                    Text(parseMarkdown(text))
                                                        .font(.system(size: 15, weight: .light, design: .serif))
                                                        .foregroundStyle(.white.opacity(0.85))
                                                        .lineSpacing(6)
                                                }
                                            } else {
                                                ForEach(closingSections) { s in
                                                    VStack(alignment: .leading, spacing: 10) {
                                                        Text(s.header.uppercased())
                                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                            .foregroundStyle(.white.opacity(0.35))
                                                            .kerning(3)
                                                        Text(parseMarkdown(s.body))
                                                            .font(.system(size: 15, weight: .light, design: .serif))
                                                            .foregroundStyle(.white.opacity(0.85))
                                                            .lineSpacing(6)
                                                    }
                                                }
                                            }
                                            
                                            Button {
                                                prepareShare()
                                            } label: {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "square.and.arrow.up")
                                                        .font(.system(size: 12, weight: .light))
                                                        .foregroundStyle(Color(red: 0.94, green: 0.90, blue: 0.78))
                                                    Text("SHARE")
                                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                        .foregroundStyle(.white.opacity(0.7))
                                                        .kerning(3)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(.white.opacity(0.06))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .stroke(Color(red: 0.94, green: 0.90, blue: 0.78).opacity(0.25), lineWidth: 0.5)
                                                        )
                                                )
                                            }
                                            .buttonStyle(.plain)
                                            if !isSingleCard {
                                                VStack(alignment: .leading, spacing: 16) {
                                                    Text("THE FULL READING")
                                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                        .foregroundStyle(.white.opacity(0.35))
                                                        .kerning(3)
                                                    ForEach(spread) { drawn in
                                                        CardRow(drawn: drawn,
                                                                reading: section(for: drawn)?.body,
                                                                onImageTap: { detailCard = drawn.card })
                                                    }
                                                }
                                            }
                                        }
                                        .transition(.opacity)
                                    } else {
                                        Button {
                                            Haptics.success()
                                            withAnimation(.easeOut(duration: 0.4)) { showFullReading = true }
                                        } label: {
                                            Text("PUT IT ALL TOGETHER")
                                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                .foregroundStyle(.white.opacity(0.8))
                                                .kerning(3)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(.white.opacity(0.06))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .stroke(Color(red: 0.94, green: 0.90, blue: 0.78).opacity(0.3), lineWidth: 0.5)
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.top, 8)
                                        .transition(.opacity)
                                    }
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
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingQuestionInput) {
            QuestionInputSheet(questionText: $questionText) { question in
                drawQuestionSpread(question: question)
            }
        }
        .sheet(item: $shareItems) { share in
            ActivityView(items: share.items)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $detailCard) { card in
            CardDetailSheet(card: card)
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
            if UserDefaults.standard.bool(forKey: "pendingDailyDraw") {
                drawDailyFromNotification()
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
        .onReceive(NotificationCenter.default.publisher(for: .drawDailyFromNotification)) { _ in
            drawDailyFromNotification()
        }
    }
    
    // MARK: - Markdown parser
    func parseMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
    
    private func trimPartialHeader(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        if let last = lines.last {
            let t = last.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("**") && !(t.hasSuffix("**") && t.count > 4) {
                lines.removeLast()
            }
        }
        return lines.joined(separator: "\n")
    }
    
    private var parsedSections: [InterpretationSection] {
        guard let text = interpretation else { return [] }
        return parseInterpretationSections(text)
    }

    private func section(for drawn: DrawnCard) -> InterpretationSection? {
        parsedSections.first { $0.header.localizedCaseInsensitiveContains(drawn.card.name) }
    }

    private var closingSections: [InterpretationSection] {
        parsedSections.filter { s in
            !spread.contains { s.header.localizedCaseInsensitiveContains($0.card.name) }
        }
    }
    
    // MARK: - Spread logic
    private func drawSpread(spreadType: String, positions: [String]) {
        guard cards.count >= positions.count else { return }
        
        let selected = Array(cards.shuffled().prefix(positions.count))
        let newSpread: [DrawnCard] = selected.enumerated().map { index, card in
            DrawnCard(card: card, isReversed: Bool.random(), position: positions[index])
        }
        
        spread = newSpread
        Haptics.tap()
        currentSpreadType = spreadType
        interpretation = nil
        interpretationError = nil
        isLoadingInterpretation = true
        resetReveal()
        dealHaptics(newSpread.count)
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
        
        let started = Date()
        do {
            let response: SpreadResponseBody
            do {
                response = try await tarotService.streamSpread(body) { partial in
                    guard activeRequestID == requestID else { return }
                    interpretation = trimPartialHeader(partial)
                }
            } catch {
                if Task.isCancelled { throw error }
                // Stream failed, fall back to the normal call
                interpretation = nil
                response = try await tarotService.interpretSpread(body)
            }
            recordTiming(spreadType, Date().timeIntervalSince(started))
            guard activeRequestID == requestID else { return }
            interpretation = response.interpretation
            Haptics.success()
            let reading = Reading(
                spreadType: spreadType,
                cardNames: spreadSnapshot.map { $0.card.name },
                cardPositions: spreadSnapshot.map { $0.position },
                cardReversals: spreadSnapshot.map { $0.isReversed },
                interpretation: response.interpretation,
                question: question
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
    
    private func retryInterpretation() {
        guard !spread.isEmpty else { return }
        interpretationError = nil
        isLoadingInterpretation = true
        interpretTask?.cancel()

        let requestID = UUID()
        activeRequestID = requestID
        let snapshot = spread
        let type = currentSpreadType
        let question: String? = type == "question" ? questionText : nil

        interpretTask = Task {
            await interpretSpreadSnapshot(spreadType: type, spreadSnapshot: snapshot, requestID: requestID, question: question)
        }
    }
    
    private func drawDailyFromNotification() {
        UserDefaults.standard.set(false, forKey: "pendingDailyDraw")
        drawSpread(spreadType: "daily", positions: ["Daily Card"])
    }
    
    private var spreadTitle: String {
        switch currentSpreadType {
        case "daily": return "Daily Card"
        case "three_card": return "Three Card Spread"
        case "four_card": return "Four Card Spread"
        case "clarity": return "Clarity Spread"
        case "question": return "Question Spread"
        case "read_me": return "Read Me"
        default: return "Reading"
        }
    }

    @MainActor
    private func prepareShare() {
        guard let text = interpretation else { return }
        Haptics.tap()

        let hasClosing = parsedSections.count != closingSections.count
        let closing = hasClosing ? closingSections.first : nil
        let question: String? = currentSpreadType == "question" ? questionText : nil

        let card = ShareCardView(
            spreadName: spreadTitle,
            spreadType: currentSpreadType,
            cards: spread,
            question: question,
            closingHeader: closing?.header,
            closingText: closing?.body ?? String(text.replacingOccurrences(of: "**", with: "").prefix(420))
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3

        var items: [Any] = []
        if let image = renderer.uiImage, let data = image.pngData() {
            let tmp = FileManager.default.temporaryDirectory

            // Clear out earlier share images
            if let old = try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil) {
                for f in old where f.lastPathComponent.hasPrefix("The Read - ") {
                    try? FileManager.default.removeItem(at: f)
                }
            }

            // Unique name every time, so nothing can reuse a stale copy
            let name = "The Read - \(spreadTitle) \(UUID().uuidString.prefix(8)).png"
            let url = tmp.appendingPathComponent(name)
            if (try? data.write(to: url)) != nil {
                items.append(url)
            } else {
                items.append(image)
            }
        } else {
            print("Share image failed to render")
        }
        if let shareLink { items.append(shareLink) }
        guard !items.isEmpty else { return }
        shareItems = ShareItems(items: items)
    }
    
    private func recordTiming(_ type: String, _ seconds: Double) {
        let key = "timing_\(type)"
        var samples = UserDefaults.standard.array(forKey: key) as? [Double] ?? []
        samples.append(seconds)
        samples = Array(samples.suffix(20))
        UserDefaults.standard.set(samples, forKey: key)
        let avg = samples.reduce(0, +) / Double(samples.count)
        print("[timing] \(type): \(String(format: "%.1f", seconds))s, avg \(String(format: "%.1f", avg))s over \(samples.count)")
    }
    
    private func dealHaptics(_ count: Int) {
        Task { @MainActor in
            for _ in 0..<count {
                Haptics.soft()
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
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
        Haptics.tap()
        currentSpreadType = "question"
        interpretation = nil
        interpretationError = nil
        isLoadingInterpretation = true
        resetReveal()
        dealHaptics(newSpread.count)
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
    
    private func resetReveal() {
        revealedCards.removeAll()
        focusedIndex = nil
        showFullReading = false
    }
    
    private var isSingleCard: Bool { spread.count == 1 }

    private var closingVisible: Bool {
        showFullReading || (isSingleCard && allRevealed)
    }

    private var allRevealed: Bool {
        !spread.isEmpty && revealedCards.count >= spread.count
    }

    private func handleCardTap(_ index: Int) {
        guard spread.indices.contains(index) else { return }

        // Once the full reading is up, tapping a card opens its detail sheet
        if showFullReading {
            if revealedCards.contains(index) {
                Haptics.tap()
                detailCard = spread[index].card
            }
            return
        }

        let next = (0..<spread.count).first { !revealedCards.contains($0) }

        if revealedCards.contains(index) {
            Haptics.tap()
        } else if index == next {
            Haptics.soft()
            revealedCards.insert(index)
        } else {
            return   // out of order, ignore
        }
        withAnimation(.easeOut(duration: 0.3)) { focusedIndex = index }
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
                        .onTapGesture {
                            onImageTap?()
                        }
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
        
        #Preview {
            ContentView()
                .modelContainer(for: TarotCard.self, inMemory: true)
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
}
