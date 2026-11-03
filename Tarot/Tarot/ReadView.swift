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

    // The daily card lives on the Today tab, so it is not listed here.
    private var readable: [SpreadDefinition] { SpreadDefinition.all.filter { $0.id != "daily" } }
    private var openNow: [SpreadDefinition] {
        readable.filter { SpecialDays.isGated($0.id) && $0.isAvailableToday }
    }
    private var anytime: [SpreadDefinition] { readable.filter { !SpecialDays.isGated($0.id) } }
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        VStack(spacing: 4) {
                            Text("\(readable.filter { $0.isAvailableToday }.count) SPREADS")
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

                        // Limited-time reads come first, set apart in gold
                        if !openNow.isEmpty {
                            SectionLabel(text: "OPEN NOW", gold: true)
                            ForEach(openNow) { spread in
                                SpreadRow(spread: spread, note: note(for: spread), locked: isLocked(spread), featured: true) {
                                    start(spread)
                                }
                            }
                            SectionLabel(text: "ANYTIME", gold: false)
                                .padding(.top, 10)
                        }

                        ForEach(anytime) { spread in
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
        if SpecialDays.isGated(spread.id) { return SpecialDays.closesLabel(spread.id) }
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
    var featured: Bool = false      // open for a limited time: gold
    var upcoming: Bool = false      // not open yet: quiet, with a clock
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
                        .foregroundStyle(featured ? Theme.gold : .white.opacity(0.3))
                        .kerning(2)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                Image(systemName: upcoming ? "clock" : (locked ? "lock" : "chevron.right"))
                    .font(.system(size: 11))
                    .foregroundStyle((locked || featured) ? Theme.gold.opacity(0.7) : .white.opacity(0.25))
            }
            .opacity(upcoming ? 0.5 : (locked && !featured ? 0.7 : 1))
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(featured
                          ? AnyShapeStyle(LinearGradient(colors: [Theme.gold.opacity(0.13), Theme.gold.opacity(0.03)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color.white.opacity(0.04)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(featured ? Theme.gold.opacity(0.6) : .white.opacity(0.08),
                                    lineWidth: featured ? 0.8 : 0.5)
                    )
            )
            .shadow(color: featured ? Theme.gold.opacity(0.18) : .clear, radius: 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A small heading with a thin line, used to group the Read page.
struct SectionLabel: View {
    let text: String
    var gold: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Text(text)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(gold ? Theme.gold : .white.opacity(0.35))
                .kerning(3)
            Rectangle()
                .fill(gold ? Theme.gold.opacity(0.35) : .white.opacity(0.08))
                .frame(height: 1)
        }
        .padding(.top, 4)
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
        case "new_moon":
            VStack(spacing: 2) {
                HStack(spacing: 5) { ForEach(0..<3, id: \.self) { _ in card.scaleEffect(0.62).frame(width: 6, height: 10) } }
                HStack(spacing: 5) { ForEach(0..<2, id: \.self) { _ in card.scaleEffect(0.62).frame(width: 6, height: 10) } }
            }
        case "full_moon":
            VStack(spacing: 3) {
                HStack(alignment: .top, spacing: 2) {
                    card.scaleEffect(0.6).frame(width: 6, height: 10).rotationEffect(.degrees(-25)).padding(.top, 3)
                    card.scaleEffect(0.6).frame(width: 6, height: 10).rotationEffect(.degrees(-8))
                    card.scaleEffect(0.6).frame(width: 6, height: 10).rotationEffect(.degrees(8))
                    card.scaleEffect(0.6).frame(width: 6, height: 10).rotationEffect(.degrees(25)).padding(.top, 3)
                }
                card.scaleEffect(0.6).frame(height: 10)
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
        case "yule", "ostara", "litha", "samhain":
            mini
        default:
            row(4)
        }
    }

    /// A small copy of the real layout, drawn from the same geometry.
    private var mini: some View {
        let count = SpreadDefinition.with(id: spreadID).cardCount
        let g = SpreadGeometry.make(spreadType: spreadID, count: count, tileW: 10, tileH: 15, gap: 3)
        let size = g?.size ?? CGSize(width: 10, height: 15)
        let scale = min(1, 54 / size.height, 62 / size.width)
        return ZStack(alignment: .topLeading) {
            if let g {
                ForEach(0..<g.centers.count, id: \.self) { i in
                    card
                        .rotationEffect(.degrees(g.rotations[i]))
                        .position(g.centers[i])
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(scale)
        .frame(width: 62, height: 54)
    }
}
