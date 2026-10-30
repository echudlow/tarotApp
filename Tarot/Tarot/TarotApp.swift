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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestNotificationPermission()
                }
        }
        .modelContainer(for: [TarotCard.self, Reading.self])
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                scheduleDailyNotification()
            }
        }
    }
    
    private func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Remove any existing scheduled notifications
        center.removePendingNotificationRequests(withIdentifiers: ["dailyTarot"])
        
        let content = UNMutableNotificationContent()
        content.title = "The cards are ready."
        content.body = "Take a moment. Draw your daily card."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyTarot", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            } else {
                print("Notification scheduled for 11:20")
            }
        }
    }
}
