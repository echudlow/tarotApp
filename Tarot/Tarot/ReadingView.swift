//
//  ReadingView.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI
import SwiftData

struct ReadingView: View {
    let route: ReadingRoute

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TarotCard.name) private var cards: [TarotCard]
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    @State private var spread: [DrawnCard] = []
    @State private var hasDrawn = false
    @State private var interpretation: String? = nil
    @State private var isLoadingInterpretation = false
    @State private var interpretationError: String? = nil
    @State private var interpretTask: Task<Void, Never>? = nil
    @State private var activeRequestID = UUID()
    @State private var revealedCards: Set<Int> = []
    @State private var loadingPulse = false
    @State private var shareItems: ShareItems? = nil
    @State private var detailCard: TarotCard? = nil
    @State private var focusedIndex: Int? = nil
    @State private var showFullReading = false

    // TODO: set to the App Store link once the app is published
    private let shareLink: String? = nil
    private let gold = Theme.gold
    private let tarotService = TarotService()

    private var definition: SpreadDefinition { SpreadDefinition.with(id: route.spreadID) }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        header

                        if !spread.isEmpty {
                            fanSection
                            promptLine
                            focusedRow
                            resultSection(proxy: proxy)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $shareItems) { share in
            ActivityView(items: share.items)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $detailCard) { card in
            CardDetailSheet(card: card)
        }
        .task(id: cards.count) {
            guard !hasDrawn, cards.count >= definition.positions.count else { return }
            hasDrawn = true
            draw()
        }
        // No cancel on disappear: switching tabs also fires it, and a reading that is
        // cancelled halfway is never saved. A reading you leave finishes and lands in the Journal.
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 6) {
            Text(definition.title.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(4)
            Text(Date().formatted(.dateTime.month(.wide).day()))
                .font(.system(size: 26, weight: .light, design: .serif))
                .foregroundStyle(.white)
            if let question = route.question, !question.isEmpty {
                Text("\"\(question)\"")
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var fanSection: some View {
        VStack(spacing: 0) {
            CardFanView(spread: spread, isHomePreview: false, spreadType: definition.id,
                        revealedCards: revealedCards,
                        focusedIndex: showFullReading ? nil : focusedIndex,
                        interactive: true, onTap: handleCardTap)
                .id(spread.map(\.id))
        }
        .id("spreadTop")
    }

    @ViewBuilder
    private var promptLine: some View {
        if !allRevealed {
            Text(revealedCards.isEmpty ? "TAP THE FIRST CARD" : "TAP THE NEXT CARD")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
                .kerning(3)
                .frame(maxWidth: .infinity)
                .fadeSlideIn(delay: Double(spread.count) * 0.25 + 0.2)
                .id(spread.map(\.id))
        }
    }

    // Only the card you're on
    @ViewBuilder
    private var focusedRow: some View {
        if (!showFullReading || isSingleCard), let i = focusedIndex, spread.indices.contains(i) {
            CardRow(drawn: spread[i],
                    reading: section(for: spread[i])?.body,
                    isLoadingReading: isLoadingInterpretation,
                    onImageTap: { detailCard = spread[i].card })
                .id(spread[i].id)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private func resultSection(proxy: ScrollViewProxy) -> some View {
        if interpretationError != nil {
            errorView
        } else if allRevealed {
            if isLoadingInterpretation {
                loadingLine
            } else if interpretation != nil {
                if closingVisible {
                    closingBlock
                } else {
                    putTogetherButton(proxy: proxy)
                }
            }
        }
    }

    private var errorView: some View {
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
    }

    private var loadingLine: some View {
        Text("Reading the cards…")
            .font(.system(size: 11, weight: .light, design: .monospaced))
            .foregroundStyle(.white.opacity(loadingPulse ? 0.5 : 0.2))
            .kerning(3)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: loadingPulse)
            .onAppear { loadingPulse = true }
            .onDisappear { loadingPulse = false }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    private func putTogetherButton(proxy: ScrollViewProxy) -> some View {
        Button {
            Haptics.success()
            withAnimation(.easeOut(duration: 0.4)) { showFullReading = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    proxy.scrollTo("spreadTop", anchor: UnitPoint(x: 0.5, y: 0.14))
                }
            }
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
                                .stroke(gold.opacity(0.3), lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .transition(.opacity)
    }

    private var closingBlock: some View {
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
                        .foregroundStyle(gold)
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
                                .stroke(gold.opacity(0.25), lineWidth: 0.5)
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
    }

    // MARK: - State helpers

    private var isSingleCard: Bool { spread.count == 1 }

    private var allRevealed: Bool {
        !spread.isEmpty && revealedCards.count >= spread.count
    }

    private var closingVisible: Bool {
        showFullReading || (isSingleCard && allRevealed)
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

    private func parseMarkdown(_ text: String) -> AttributedString {
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

    // MARK: - Daily card (once per day)

    /// Today's saved daily reading, if there is one.
    private var savedDailyToday: Reading? {
        guard definition.id == "daily" else { return nil }
        return readings.first {
            $0.spreadType == "daily" && Calendar.current.isDateInToday($0.date)
        }
    }

    /// Reopen the daily card that was already drawn today, with its saved reading.
    private func restoreDaily(_ saved: Reading) -> Bool {
        guard let name = saved.cardNames.first,
              let card = cards.first(where: { $0.name == name }) else { return false }

        let reversed = saved.cardReversals.first ?? false
        let position = saved.cardPositions.first ?? definition.positions[0]

        spread = [DrawnCard(card: card, isReversed: reversed, position: position)]
        interpretation = saved.interpretation
        interpretationError = nil
        isLoadingInterpretation = false
        resetReveal()
        if DailyCardStore.turnedToday {
            revealedCards = [0]
            focusedIndex = 0
        }
        return true
    }

    private func dailyAlreadySaved() -> Bool {
        let start = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<Reading>(
            predicate: #Predicate { $0.spreadType == "daily" && $0.date >= start }
        )
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    // MARK: - Drawing and reading

    private func draw() {
        let positions = definition.positions
        guard cards.count >= positions.count else { return }

        // Today's daily card was already read: show it again instead of drawing
        if let saved = savedDailyToday, restoreDaily(saved) { return }

        let isDaily = definition.id == "daily"
        let selected: [TarotCard]
        let flags: [Bool]

        if isDaily, let stored = DailyCardStore.today(from: cards) {
            // Drawn earlier today but never finished: same card again
            selected = [stored.card]
            flags = [stored.reversed]
        } else {
            selected = Array(cards.shuffled().prefix(positions.count))
            flags = selected.map { _ in Bool.random() }
            if isDaily, let first = selected.first {
                DailyCardStore.save(card: first, reversed: flags[0])
            }
        }

        let newSpread: [DrawnCard] = selected.enumerated().map { index, card in
            DrawnCard(card: card, isReversed: flags[index], position: positions[index])
        }

        spread = newSpread
        interpretation = nil
        interpretationError = nil
        isLoadingInterpretation = true
        resetReveal()
        if isDaily && DailyCardStore.turnedToday {
            revealedCards = [0]
            focusedIndex = 0
        }
        dealHaptics(newSpread.count)
        interpretTask?.cancel()

        let requestID = UUID()
        activeRequestID = requestID
        let type = definition.id
        let question = route.question

        interpretTask = Task {
            await interpretSpreadSnapshot(spreadType: type, spreadSnapshot: newSpread,
                                          requestID: requestID, question: question)
        }
    }

    private func interpretSpreadSnapshot(spreadType: String, spreadSnapshot: [DrawnCard],
                                         requestID: UUID, question: String? = nil) async {
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

            // One saved daily reading per day, even if the screen was opened twice mid-load
            if !(spreadType == "daily" && dailyAlreadySaved()) {
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
            }
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
        let type = definition.id
        let question = route.question

        interpretTask = Task {
            await interpretSpreadSnapshot(spreadType: type, spreadSnapshot: snapshot,
                                          requestID: requestID, question: question)
        }
    }

    private func resetReveal() {
        revealedCards.removeAll()
        focusedIndex = nil
        showFullReading = false
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
            if definition.id == "daily" {
                DailyCardStore.markTurned(card: spread[index].card, reversed: spread[index].isReversed)
            }
        } else {
            return   // out of order, ignore
        }
        withAnimation(.easeOut(duration: 0.3)) { focusedIndex = index }
    }

    private func dealHaptics(_ count: Int) {
        Task { @MainActor in
            for _ in 0..<count {
                Haptics.soft()
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
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

    // MARK: - Share

    @MainActor
    private func prepareShare() {
        guard let text = interpretation else { return }
        Haptics.tap()

        let hasClosing = parsedSections.count != closingSections.count
        let closing = hasClosing ? closingSections.first : nil
        let question: String? = definition.needsQuestion ? route.question : nil

        let card = ShareCardView(
            spreadName: definition.title,
            spreadType: definition.id,
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
            let name = "The Read - \(definition.title) \(UUID().uuidString.prefix(8)).png"
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
}
