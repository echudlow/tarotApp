//
//  Todayview.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Binding var path: [ReadingRoute]
    var goToRead: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \TarotCard.name) private var cards: [TarotCard]
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    @State private var previewCards: [DrawnCard] = []
    @State private var showingSettings = false
    @State private var dayStamp = Date()

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        header

                        if !previewCards.isEmpty {
                            CardFanView(spread: previewCards, isHomePreview: true, spreadType: "")
                                .padding(.vertical, 8)
                        }

                        dailyModule

                        links
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }

                TopFade()
                settingsButton
            }
            .navigationBarHidden(true)
            .navigationDestination(for: ReadingRoute.self) { route in
                ReadingView(route: route)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
                .presentationDetents([.medium, .large])
        }
        .task(id: cards.count) {
            seedPreview()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { dayStamp = Date() }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(dayStamp.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(4)
            Text("The Read")
                .font(.system(size: 34, weight: .light, design: .serif))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var settingsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    Haptics.tap()
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            Spacer()
        }
    }

    /// Today's daily card. Three states: not drawn, drawn but not turned, turned.
    @ViewBuilder
    private var dailyModule: some View {
        let daily = dailyCard
        let started = DailyCardStore.startedToday || todaysReading != nil
        let turned = DailyCardStore.turnedToday && daily != nil

        Button {
            Haptics.tap()
            path.append(ReadingRoute(spreadID: "daily"))
        } label: {
            HStack(alignment: .center, spacing: 16) {
                FlipCard(imageName: daily?.card.imageName,
                         isReversed: daily?.reversed ?? false,
                         width: 54,
                         revealed: turned,
                         cornerRadius: 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S CARD")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.gold.opacity(0.7))
                        .kerning(2)

                    if turned, let daily {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(daily.card.name)
                                .font(.system(size: 18, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                            if daily.reversed {
                                Text("reversed")
                                    .font(.system(size: 11, weight: .light, design: .serif))
                                    .italic()
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                        Text(excerpt ?? "Your reading is on its way.")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineSpacing(2)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(started ? "Your card is waiting" : "Draw your daily card")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                        Text(started ? "Turn it over to see what it says." : "One card, once a day.")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.gold.opacity(0.25), lineWidth: 0.5)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var links: some View {
        VStack(spacing: 0) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
            Button {
                Haptics.tap()
                goToRead()
            } label: {
                LinkRow(title: "CHOOSE A READ")
            }
            .buttonStyle(.plain)
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

    // MARK: - Daily state

    private var todaysReading: Reading? {
        readings.first {
            $0.spreadType == "daily" && Calendar.current.isDate($0.date, inSameDayAs: dayStamp)
        }
    }

    /// Prefer the saved reading, then the card that was drawn but not finished.
    private var dailyCard: (card: TarotCard, reversed: Bool)? {
        if let reading = todaysReading,
           let name = reading.cardNames.first,
           let card = cards.first(where: { $0.name == name }) {
            return (card, reading.cardReversals.first ?? false)
        }
        return DailyCardStore.today(from: cards)
    }

    /// The short closing paragraph of today's reading (or its first paragraph).
    private var excerpt: String? {
        guard let text = todaysReading?.interpretation, !text.isEmpty else { return nil }
        let sections = parseInterpretationSections(text)
        let body = sections.count > 1 ? sections.last?.body : sections.first?.body
        let clean = (body ?? text)
            .replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }

    private func seedPreview() {
        guard previewCards.isEmpty, cards.count >= 5 else { return }
        previewCards = Array(cards.shuffled().prefix(5)).map { card in
            DrawnCard(card: card, isReversed: Bool.random(), position: "")
        }
    }
}
