//  TarotIntent.swift
//  Tarot

import AppIntents
import SwiftData
import SwiftUI

// MARK: - Daily Card
struct DailyCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Draw Daily Tarot Card"
    static var description = IntentDescription("Draws a daily tarot card and gives you a reading.")
    static var openAppWhenRun: Bool = false
    
    static var suggestedInvocationPhrases: [String] = [
        "tarot daily",
        "daily tarot card",
        "tarot of the day",
        "pull my daily tarot",
        "today's tarot",
        "read my daily tarot",
        "my tarot card"
    ]

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let container = try ModelContainer(for: TarotCard.self, Reading.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<TarotCard>()
        let cards = try context.fetch(descriptor)

        guard !cards.isEmpty else {
            return .result(dialog: IntentDialog(stringLiteral: "I couldn't find enough cards. Please open the app first."))
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
        let body = SpreadRequestBody(spread_type: "daily", cards: [apiCard], question: nil)
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

        return .result(dialog: IntentDialog(stringLiteral: "\(card.name), \(orientation). \(spokenText)"))
    }
}

// MARK: - Three Card Spread
struct ThreeCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Three Card Tarot Reading"
    static var description = IntentDescription("Draws a past, present, and future tarot spread.")
    static var openAppWhenRun: Bool = false

    static var suggestedInvocationPhrases: [String] = [
        "three card tarot",
        "past present future reading",
        "give me a three card spread",
        "tarot spread",
        "pull three cards",
        "three card reading",
        "past present future tarot"
    ]

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let container = try ModelContainer(for: TarotCard.self, Reading.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<TarotCard>()
        let allCards = try context.fetch(descriptor)

        guard allCards.count >= 3 else {
            return .result(dialog: IntentDialog(stringLiteral: "I couldn't find enough cards. Please open the app first."))
        }

        let positions = ["Past", "Present", "Future"]
        let selected = Array(allCards.shuffled().prefix(3))
        
        var cardDescriptions: [String] = []
        var apiCards: [TarotAPICard] = []
        var cardNames: [String] = []
        var cardReversals: [Bool] = []

        for (index, card) in selected.enumerated() {
            let isReversed = Bool.random()
            let orientation = isReversed ? "Reversed" : "Upright"
            cardDescriptions.append("\(positions[index]): \(card.name), \(orientation)")
            cardNames.append(card.name)
            cardReversals.append(isReversed)
            apiCards.append(TarotAPICard(
                name: card.name,
                position: positions[index],
                isReversed: isReversed,
                uprightMeaning: card.uprightMeaning,
                reversedMeaning: card.reversedMeaning,
                suit: card.suit,
                arcana: card.arcana
            ))
        }

        let body = SpreadRequestBody(spread_type: "three_card", cards: apiCards, question: nil)
        let service = TarotService()
        let response = try await service.interpretSpread(body)

        let spokenText = response.interpretation
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")

        let reading = Reading(
            spreadType: "three_card",
            cardNames: cardNames,
            cardPositions: positions,
            cardReversals: cardReversals,
            interpretation: response.interpretation
        )
        context.insert(reading)
        try context.save()

        return .result(dialog: IntentDialog(stringLiteral: spokenText))
    }
}

// MARK: - Four Card Spread
struct FourCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Four Card Tarot Reading"
    static var description = IntentDescription("Draws a four card situation spread.")
    static var openAppWhenRun: Bool = false

    static var suggestedInvocationPhrases: [String] = [
        "four card tarot",
        "situation spread",
        "give me a four card reading",
        "pull four cards",
        "four card spread",
        "tarot situation reading"
    ]

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let container = try ModelContainer(for: TarotCard.self, Reading.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<TarotCard>()
        let allCards = try context.fetch(descriptor)

        guard allCards.count >= 4 else {
            return .result(dialog: IntentDialog(stringLiteral: "I couldn't find enough cards. Please open the app first."))
        }

        let positions = ["Past", "Present", "Future", "Current Situation"]
        let selected = Array(allCards.shuffled().prefix(4))

        var apiCards: [TarotAPICard] = []
        var cardNames: [String] = []
        var cardReversals: [Bool] = []

        for (index, card) in selected.enumerated() {
            let isReversed = Bool.random()
            cardNames.append(card.name)
            cardReversals.append(isReversed)
            apiCards.append(TarotAPICard(
                name: card.name,
                position: positions[index],
                isReversed: isReversed,
                uprightMeaning: card.uprightMeaning,
                reversedMeaning: card.reversedMeaning,
                suit: card.suit,
                arcana: card.arcana
            ))
        }

        let body = SpreadRequestBody(spread_type: "four_card", cards: apiCards, question: nil)
        let service = TarotService()
        let response = try await service.interpretSpread(body)

        let spokenText = response.interpretation
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")

        let reading = Reading(
            spreadType: "four_card",
            cardNames: cardNames,
            cardPositions: positions,
            cardReversals: cardReversals,
            interpretation: response.interpretation
        )
        context.insert(reading)
        try context.save()

        return .result(dialog: IntentDialog(stringLiteral: spokenText))
    }
}

// MARK: - Ask the Cards
struct AskTheCardsIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask the Tarot Cards"
    static var description = IntentDescription("Ask the tarot cards a specific question.")
    static var openAppWhenRun: Bool = false

    static var suggestedInvocationPhrases: [String] = [
        "ask the tarot",
        "ask the cards",
        "tarot question",
        "I have a question for the cards",
        "ask tarot a question",
        "give me a tarot answer"
    ]

    @Parameter(title: "Your Question", description: "What would you like to ask the cards?")
    var question: String

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let container = try ModelContainer(for: TarotCard.self, Reading.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<TarotCard>()
        let allCards = try context.fetch(descriptor)

        guard allCards.count >= 5 else {
            return .result(dialog: IntentDialog(stringLiteral: "I couldn't find enough cards. Please open the app first."))
        }

        let positions = ["The Question", "The Background", "The Seeker", "The Environment", "The Answer"]
        let selected = Array(allCards.shuffled().prefix(5))

        var apiCards: [TarotAPICard] = []
        var cardNames: [String] = []
        var cardReversals: [Bool] = []

        for (index, card) in selected.enumerated() {
            let isReversed = Bool.random()
            cardNames.append(card.name)
            cardReversals.append(isReversed)
            apiCards.append(TarotAPICard(
                name: card.name,
                position: positions[index],
                isReversed: isReversed,
                uprightMeaning: card.uprightMeaning,
                reversedMeaning: card.reversedMeaning,
                suit: card.suit,
                arcana: card.arcana
            ))
        }

        let body = SpreadRequestBody(spread_type: "question", cards: apiCards, question: question)
        let service = TarotService()
        let response = try await service.interpretSpread(body)

        let spokenText = response.interpretation
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")

        let reading = Reading(
            spreadType: "question",
            cardNames: cardNames,
            cardPositions: positions,
            cardReversals: cardReversals,
            interpretation: response.interpretation,
            question: question
        )
        context.insert(reading)
        try context.save()

        return .result(dialog: IntentDialog(stringLiteral: spokenText))
    }
}

struct TarotShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DailyCardIntent(),
            phrases: [
                "tarot daily with \(.applicationName)",
                "daily tarot card with \(.applicationName)",
                "today's tarot with \(.applicationName)",
                "my tarot card with \(.applicationName)",
                "tarot of the day with \(.applicationName)"
            ],
            shortTitle: "Daily Tarot",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: ThreeCardIntent(),
            phrases: [
                "three card tarot with \(.applicationName)",
                "tarot spread with \(.applicationName)",
                "past present future with \(.applicationName)"
            ],
            shortTitle: "Three Card Reading",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: FourCardIntent(),
            phrases: [
                "four card tarot with \(.applicationName)",
                "situation spread with \(.applicationName)"
            ],
            shortTitle: "Four Card Reading",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: AskTheCardsIntent(),
            phrases: [
                "ask the tarot with \(.applicationName)",
                "ask the cards with \(.applicationName)",
                "tarot question with \(.applicationName)"
            ],
            shortTitle: "Ask the Cards",
            systemImageName: "sparkles"
        )
    }
}
