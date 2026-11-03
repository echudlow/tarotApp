//  ReadView.swift
//  Tarot
//
//  The "Read" tab: pick a spread.

import SwiftUI
import SwiftData

struct ReadView: View {
    @Binding var path: [ReadingRoute]

    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    @State private var showingQuestionInput = false
    @State private var showingPaywall = false
    private var store: PurchaseStore { PurchaseStore.shared }
    @State private var questionText = ""
    @State private var dayStamp = Date()

    private var dailyDrawn: Bool {
        DailyCardStore.startedToday
            || readings.contains { $0.spreadType == "daily" && Calendar.current.isDate($0.date, inSameDayAs: dayStamp) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        VStack(spacing: 4) {
                            Text("\(SpreadDefinition.all.count) SPREADS")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                                .kerning(4)
                            Text("Choose A Read")
                                .font(.system(size: 34, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .padding(.bottom, 14)

                        ForEach(SpreadDefinition.all) { spread in
                            SpreadRow(spread: spread, note: note(for: spread), locked: isLocked(spread)) {
                                start(spread)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }

                TopFade()
            }
            .navigationBarHidden(true)
            .navigationDestination(for: ReadingRoute.self) { route in
                ReadingView(route: route)
            }
        }
        .sheet(isPresented: $showingQuestionInput) {
            QuestionInputSheet(questionText: $questionText) { question in
                questionText = ""
                // Let the sheet finish dismissing before pushing the reading
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    path.append(ReadingRoute(spreadID: "question", question: question))
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { dayStamp = Date() }
        }
    }

    private func note(for spread: SpreadDefinition) -> String {
        if !spread.isAvailableToday { return "AVAILABLE DECEMBER 31" }
        if spread.id == "daily" {
            return dailyDrawn ? "ONE CARD · DRAWN TODAY" : "ONE CARD · ONCE A DAY"
        }
        if store.isUnlocked { return "\(spread.cardCount) CARDS" }
        if spread.requiresUnlock { return "UNLOCK TO READ" }
        let left = FreeSampleStore.remaining
        return left > 0 ? "FREE SAMPLE · \(left) LEFT" : "UNLOCK TO READ"
    }

    /// Everything except the daily card needs the unlock once the free samples are used.
    private func isLocked(_ spread: SpreadDefinition) -> Bool {
        if spread.id == "daily" || store.isUnlocked { return false }
        return spread.requiresUnlock || FreeSampleStore.remaining == 0
    }

    private func start(_ spread: SpreadDefinition) {
        Haptics.tap()
        if !spread.isAvailableToday { return }
        if isLocked(spread) {
            showingPaywall = true
            return
        }
        if spread.needsQuestion {
            questionText = ""
            showingQuestionInput = true
        } else {
            path.append(ReadingRoute(spreadID: spread.id))
        }
    }
}

// MARK: - Row

struct SpreadRow: View {
    let spread: SpreadDefinition
    var note: String? = nil
    var locked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                SpreadGlyph(spreadID: spread.id)
                    .frame(width: 64, height: 56)

                VStack(alignment: .leading, spacing: 5) {
                    Text(spread.name)
                        .font(.system(size: 18, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                    Text(spread.blurb)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(note ?? "\(spread.cardCount) CARDS")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                        .kerning(2)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                Image(systemName: locked ? "lock" : "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(locked ? Theme.gold.opacity(0.6) : .white.opacity(0.25))
            }
            .opacity(locked ? 0.7 : 1)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Layout glyph

/// A tiny diagram of how the cards sit in a spread.
struct SpreadGlyph: View {
    let spreadID: String

    private let w: CGFloat = 10
    private let drops: [CGFloat] = [0, 5, 10, 5, 0]

    private var card: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Theme.gold.opacity(0.55), lineWidth: 0.8)
            )
            .frame(width: w, height: w * 1.5)
    }

    private func row(_ count: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { _ in
                card
            }
        }
    }

    var body: some View {
        switch spreadID {
        case "daily":
            card
        case "clarity":
            VStack(spacing: 4) {
                card
                row(3)
            }
        case "question":
            HStack(alignment: .top, spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    card.padding(.top, drops[i])
                }
            }
        case "three_card":
            row(3)
        case "connection":
            // 5 on top, then 2, 1, 3, 4 along the bottom
            VStack(spacing: 2) {
                card.scaleEffect(0.8).frame(height: 12)
                HStack(alignment: .top, spacing: 3) {
                    card.scaleEffect(0.8).padding(.top, 0)
                    card.scaleEffect(0.8).padding(.top, 6)
                    card.scaleEffect(0.8).padding(.top, 6)
                    card.scaleEffect(0.8).padding(.top, 0)
                }
            }
        case "star":
            ZStack {
                ForEach(Array([(0.0, -17.0), (-16.0, -5.0), (16.0, -5.0), (-10.0, 14.0), (10.0, 14.0)].enumerated()), id: \.offset) { _, o in
                    card.scaleEffect(0.6).offset(x: o.0, y: o.1)
                }
                card.scaleEffect(0.6)
            }
            .frame(width: 56, height: 56)
        case "healing":
            VStack(spacing: 2) {
                card.scaleEffect(0.62).frame(height: 10)
                HStack(spacing: 3) { card.scaleEffect(0.62).frame(width: 6, height: 10); card.scaleEffect(0.62).frame(width: 6, height: 10) }
                HStack(spacing: 3) { ForEach(0..<3, id: \.self) { _ in card.scaleEffect(0.62).frame(width: 6, height: 10) } }
            }
        case "elements":
            VStack(spacing: 2) {
                card.scaleEffect(0.55).frame(height: 9)
                HStack(spacing: 2) { ForEach(0..<3, id: \.self) { _ in card.scaleEffect(0.55).frame(width: 6, height: 9) } }
                card.scaleEffect(0.55).frame(height: 9)
            }
        case "tree_of_life":
            VStack(spacing: 1) {
                card.scaleEffect(0.42).frame(height: 7)
                HStack(spacing: 10) { card.scaleEffect(0.42).frame(width: 4, height: 7); card.scaleEffect(0.42).frame(width: 4, height: 7) }
                HStack(spacing: 4) { ForEach(0..<3, id: \.self) { _ in card.scaleEffect(0.42).frame(width: 4, height: 7) } }
                HStack(spacing: 4) { ForEach(0..<3, id: \.self) { _ in card.scaleEffect(0.42).frame(width: 4, height: 7) } }
                card.scaleEffect(0.42).frame(height: 7)
            }
        case "celtic_cross":
            HStack(alignment: .center, spacing: 6) {
                VStack(spacing: 2) {
                    card.scaleEffect(0.6).frame(height: 11)
                    HStack(spacing: 2) { card.scaleEffect(0.6).frame(width: 7, height: 11); card.scaleEffect(0.6).frame(width: 7, height: 11); card.scaleEffect(0.6).frame(width: 7, height: 11) }
                    card.scaleEffect(0.6).frame(height: 11)
                }
                VStack(spacing: 2) { ForEach(0..<4, id: \.self) { _ in card.scaleEffect(0.45).frame(width: 5, height: 9) } }
            }
        case "year_ahead":
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    card.scaleEffect(0.4)
                        .offset(y: -20)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                card.scaleEffect(0.5)
            }
            .frame(width: 56, height: 56)
        default:
            row(4)
        }
    }
}
