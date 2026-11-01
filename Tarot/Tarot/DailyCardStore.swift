//
//  DailyCardStore.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import Foundation

/// Remembers today's daily card, so it stays the same if you leave mid-reading,
/// retry, or relaunch. Everything resets at midnight.
enum DailyCardStore {
    private static let dayKey = "dailyCardDay"
    private static let nameKey = "dailyCardName"
    private static let reversedKey = "dailyCardReversed"
    private static let turnedKey = "dailyCardTurned"

    private static var todayStamp: Double {
        Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    }

    /// True once today's card has been drawn, even if it was never turned over.
    static var startedToday: Bool {
        let defaults = UserDefaults.standard
        return defaults.double(forKey: dayKey) == todayStamp
            && defaults.string(forKey: nameKey) != nil
    }

    /// True once the person has turned today's card face-up.
    static var turnedToday: Bool {
        startedToday && UserDefaults.standard.bool(forKey: turnedKey)
    }

    static func today(from cards: [TarotCard]) -> (card: TarotCard, reversed: Bool)? {
        let defaults = UserDefaults.standard
        guard startedToday,
              let name = defaults.string(forKey: nameKey),
              let card = cards.first(where: { $0.name == name }) else { return nil }
        return (card, defaults.bool(forKey: reversedKey))
    }

    static func save(card: TarotCard, reversed: Bool, turned: Bool = false) {
        let defaults = UserDefaults.standard
        defaults.set(todayStamp, forKey: dayKey)
        defaults.set(card.name, forKey: nameKey)
        defaults.set(reversed, forKey: reversedKey)
        defaults.set(turned, forKey: turnedKey)
    }

    static func markTurned(card: TarotCard, reversed: Bool) {
        save(card: card, reversed: reversed, turned: true)
    }
}
