//
//  TarotIntent.swift
//  Tarot
//
//  Created by Elijah Hudlow on 3/18/26.
//

import AppIntents
import SwiftData
import SwiftUI

struct DailyCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Draw Daily Tarot Card"
    static var description = IntentDescription("Draws a daily tarot card and gives you a reading.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let container = try ModelContainer(for: TarotCard.self, Reading.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<TarotCard>()
        let cards = try context.fetch(descriptor)

        guard !cards.isEmpty else {
            return .result(dialog: "I couldn't find any tarot cards. Please open the app first.")
        }

        let card = cards.randomElement()!
        let isReversed = Bool.random()
        let orientation = isReversed ? "Reversed" : "Upright"

        let service = TarotService()
        let apiCard = TarotAPICard(
            name: card.name,
            position: "Daily Card",
            isReversed: isReversed,
            uprightMeaning: card.uprightMeaning,
            reversedMeaning: card.reversedMeaning,
            suit: card.suit,
            arcana: card.arcana
        )
        let body = SpreadRequestBody(spread_type: "daily", cards: [apiCard])
        let response = try await service.interpretSpread(body)

        let spokenText = response.interpretation
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")

        let reading = Reading(
            spreadType: "daily",
            cardNames: [card.name],
            cardPositions: ["Daily Card"],
            cardReversals: [isReversed],
            interpretation: response.interpretation
        )
        context.insert(reading)
        try context.save()

        return .result(dialog: "\(card.name), \(orientation). \(spokenText)")
    }
}
