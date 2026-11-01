//
//  TarotApp.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/10/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct TarotApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationHandler.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { setUpNotifications() }
        }
        .modelContainer(for: [TarotCard.self, Reading.self])
    }

    private func setUpNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { NotificationScheduler.refresh() }
        }
    }
}
