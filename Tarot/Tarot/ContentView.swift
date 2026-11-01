//  ContentView.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \TarotCard.name) var cards: [TarotCard]

    @State private var path: [ReadingRoute] = []
    @State private var showingQuestionInput = false
    @State private var questionText = ""
    @State private var previewCards: [DrawnCard] = []
    @State private var showingReminderSettings = false
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0

    var body: some View {
        NavigationStack(path: $path) {
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
                                ForEach(SpreadDefinition.all.prefix(3)) { spread in
                                    SpreadButton(label: spread.name, sublabel: spread.subtitle) {
                                        start(spread)
                                    }
                                }
                            }
                            HStack(spacing: 10) {
                                ForEach(SpreadDefinition.all.suffix(3)) { spread in
                                    SpreadButton(label: spread.name, sublabel: spread.subtitle) {
                                        start(spread)
                                    }
                                }
                            }
                        }

                        // MARK: - Preview fan
                        if !previewCards.isEmpty {
                            CardFanView(spread: previewCards, isHomePreview: true, spreadType: "")
                                .padding(.vertical, 24)
                        }
                        Text("Choose a spread to begin")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 24)

                        // MARK: - Links
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

                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(height: 1)
                        Button {
                            showingReminderSettings = true
                        } label: {
                            HStack {
                                Text("DAILY REMINDER")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .kerning(3)
                                Spacer()
                                Text(reminderEnabled
                                     ? NotificationScheduler.timeString(hour: reminderHour, minute: reminderMinute)
                                     : "OFF")
                                    .font(.system(size: 11, weight: .light, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.3))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                        }
                        .buttonStyle(.plain)
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
            .navigationDestination(for: ReadingRoute.self) { route in
                ReadingView(route: route)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingQuestionInput) {
            QuestionInputSheet(questionText: $questionText) { question in
                questionText = ""
                // Let the sheet finish dismissing before pushing the reading
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    path.append(ReadingRoute(spreadID: "question", question: question))
                }
            }
        }
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsSheet()
                .presentationDetents([.height(480), .large])
        }
        .task {
            seedTarotDeckIfNeeded()
            try? await Task.sleep(nanoseconds: 500_000_000)
            seedPreview()
            if UserDefaults.standard.bool(forKey: "pendingDailyDraw") {
                drawDailyFromNotification()
            }
        }
        .onChange(of: cards.count, initial: false) { _, _ in
            seedPreview()
        }
        .onReceive(NotificationCenter.default.publisher(for: .drawDailyFromNotification)) { _ in
            drawDailyFromNotification()
        }
    }

    // MARK: - Actions

    private func start(_ spread: SpreadDefinition) {
        if spread.needsQuestion {
            showingQuestionInput = true
        } else {
            path.append(ReadingRoute(spreadID: spread.id))
        }
    }

    private func drawDailyFromNotification() {
        UserDefaults.standard.set(false, forKey: "pendingDailyDraw")
        path = [ReadingRoute(spreadID: "daily")]
    }

    private func seedPreview() {
        guard previewCards.isEmpty, cards.count >= 5 else { return }
        let selected = Array(cards.shuffled().prefix(5))
        previewCards = selected.map { card in
            DrawnCard(card: card, isReversed: Bool.random(), position: "")
        }
    }
}
