//  ContentView.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/10/25.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case today, read, journal, deck
}

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \TarotCard.name) var cards: [TarotCard]

    @State private var selection: AppTab = .today
    @State private var todayPath: [ReadingRoute] = []
    @State private var readPath: [ReadingRoute] = []

    var body: some View {
        TabView(selection: $selection) {
            TodayView(path: $todayPath, goToRead: { selection = .read })
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)

            ReadView(path: $readPath)
                .tabItem { Label("Read", systemImage: "sparkles") }
                .tag(AppTab.read)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("Journal", systemImage: "book.closed") }
            .tag(AppTab.journal)

            NavigationStack {
                AllCardsView()
            }
            .tabItem { Label("Deck", systemImage: "square.grid.2x2") }
            .tag(AppTab.deck)
        }
        .tint(Theme.gold)
        .preferredColorScheme(.dark)
        .task {
            seedTarotDeckIfNeeded()
            if UserDefaults.standard.bool(forKey: "pendingDailyDraw") {
                openDailyFromNotification()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .drawDailyFromNotification)) { _ in
            openDailyFromNotification()
        }
    }

    /// Tapping the morning reminder lands on Today with the daily reading open.
    private func openDailyFromNotification() {
        UserDefaults.standard.set(false, forKey: "pendingDailyDraw")
        selection = .today
        todayPath = [ReadingRoute(spreadID: "daily")]
    }
}
