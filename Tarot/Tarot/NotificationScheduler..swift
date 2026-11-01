//
//  NotificationScheduler..swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import Foundation
import UserNotifications

enum NotificationScheduler {
    static let identifier = "dailyTarot"

    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "reminderEnabled") as? Bool ?? true
    }
    static var hour: Int {
        UserDefaults.standard.object(forKey: "reminderHour") as? Int ?? 8
    }
    static var minute: Int {
        UserDefaults.standard.object(forKey: "reminderMinute") as? Int ?? 0
    }

    /// Clears any scheduled reminder, then schedules a new one at the saved time (if enabled).
    static func refresh() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "The cards are ready."
        content.body = "Take a moment. Draw your daily card."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("Reminder scheduling error: \(error)") }
        }
    }

    static func timeString(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
