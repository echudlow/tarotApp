//
//  NotificationHandler.swift
//  The Read
//
//  Created by Elijah Hudlow on 10/31/26.
//

import UserNotifications

extension Notification.Name {
    static let drawDailyFromNotification = Notification.Name("drawDailyFromNotification")
}

final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()

    // Tapping the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "dailyTarot" {
            UserDefaults.standard.set(true, forKey: "pendingDailyDraw")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .drawDailyFromNotification, object: nil)
            }
        }
        completionHandler()
    }

    // Show the banner even if the app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
