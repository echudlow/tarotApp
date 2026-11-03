//  ContentView.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/10/25.
//
//  The app shell: four tabs. Each tab owns its own screen.
//  (Kept as ContentView so TarotApp and TarotSeed.swift need no changes.)

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
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var announcement: AnnouncementItem?

    var body: some View {
        TabView(selection: $selection) {
            TodayView(path: $todayPath, goToRead: { selection = .read })
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)

            ReadView(path: $readPath)
                .tabItem { Label("Read", systemImage: "sparkles") }
                .tag(AppTab.read)

            NavigationStack {
                JournalRoot(goToRead: { selection = .read })
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
        .animation(.easeInOut(duration: 0.2), value: selection)
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { _ in })) {
            OnboardingView {
                hasOnboarded = true
            }
        }
        .preferredColorScheme(.dark)
        // "It's open" page for limited-time reads. On its own background view so it never
        // competes with the onboarding cover.
        .background(
            Color.clear.fullScreenCover(item: $announcement) { item in
                SpecialDayAnnouncement(spreadID: item.id) {
                    SpecialDays.markAnnounced(item.id)
                    announcement = nil
                } onBegin: {
                    SpecialDays.markAnnounced(item.id)
                    announcement = nil
                    selection = .read
                    if PurchaseStore.shared.isUnlocked {
                        readPath = [ReadingRoute(spreadID: item.id)]
                    }
                }
            }
        )
        .onChange(of: hasOnboarded) { _, _ in checkAnnouncement() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkAnnouncement() }
        }
        .task {
            checkAnnouncement()
            seedTarotDeckIfNeeded()
            if UserDefaults.standard.bool(forKey: "pendingDailyDraw") {
                openDailyFromNotification()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .drawDailyFromNotification)) { _ in
            openDailyFromNotification()
        }
    }

    private func checkAnnouncement() {
        guard hasOnboarded, announcement == nil, let id = SpecialDays.unseenAnnouncement() else { return }
        announcement = AnnouncementItem(id: id)
    }

    /// Tapping the morning reminder lands on Today with the daily reading open.
    private func openDailyFromNotification() {
        UserDefaults.standard.set(false, forKey: "pendingDailyDraw")
        selection = .today
        todayPath = [ReadingRoute(spreadID: "daily")]
    }
}

struct AnnouncementItem: Identifiable {
    let id: String
}
