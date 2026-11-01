//
//  Spread.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import Foundation

/// One definition per spread. Adding a spread means adding an entry to `all`
/// (plus its prompt in TarotAPI.buildPrompt).
struct SpreadDefinition: Identifiable, Hashable {
    /// The spread_type sent to the prompt builder and saved on each Reading.
    let id: String
    let name: String
    let subtitle: String
    let title: String
    let positions: [String]

    var needsQuestion: Bool { id == "question" }

    static let all: [SpreadDefinition] = [
        SpreadDefinition(id: "daily", name: "Daily", subtitle: "1 card",
                         title: "Daily Card",
                         positions: ["Daily Card"]),
        SpreadDefinition(id: "three_card", name: "Three", subtitle: "3 cards",
                         title: "Three Card Spread",
                         positions: ["Past", "Present", "Future"]),
        SpreadDefinition(id: "four_card", name: "Four", subtitle: "Situation spread",
                         title: "Four Card Spread",
                         positions: ["Past", "Present", "Future", "Current Situation"]),
        SpreadDefinition(id: "clarity", name: "Clarity", subtitle: "4 card spread",
                         title: "Clarity Spread",
                         positions: ["The Situation", "Factor One", "Factor Two", "Factor Three"]),
        SpreadDefinition(id: "question", name: "Ask", subtitle: "5 card spread",
                         title: "Question Spread",
                         positions: ["The Question", "The Background", "The Seeker", "The Environment", "The Answer"]),
        SpreadDefinition(id: "read_me", name: "Read Me", subtitle: "Don't hold back",
                         title: "Read Me",
                         positions: ["Past", "Present", "Future", "Current Situation"])
    ]

    static func with(id: String) -> SpreadDefinition {
        all.first { $0.id == id } ?? all[0]
    }
}

/// A navigation request to open a reading. The token makes every draw a fresh screen,
/// even for the same spread.
struct ReadingRoute: Hashable {
    let spreadID: String
    var question: String? = nil
    let token = UUID()
}
