//
//  Readvew.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

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
        if spread.id == "daily" {
            return dailyDrawn ? "ONE CARD · DRAWN TODAY" : "ONE CARD · ONCE A DAY"
        }
        if store.isUnlocked { return "\(spread.cardCount) CARDS" }
        let left = FreeSampleStore.remaining
        return left > 0 ? "FREE SAMPLE · \(left) LEFT" : "UNLOCK TO READ"
    }

    /// Everything except the daily card needs the unlock once the free samples are used.
    private func isLocked(_ spread: SpreadDefinition) -> Bool {
        spread.id != "daily" && !store.isUnlocked && FreeSampleStore.remaining == 0
    }

    private func start(_ spread: SpreadDefinition) {
        Haptics.tap()
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
        default:
            row(4)
        }
    }
}
