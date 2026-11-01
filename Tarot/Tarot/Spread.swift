//
//  Spread.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import Foundation

/// One definition per spread. Adding a spread means adding an entry to `all`
/// (plus its prompt in TarotAPI.buildPrompt and, if it needs one, a layout in CardFanView).
struct SpreadDefinition: Identifiable, Hashable {
    /// The spread_type sent to the prompt builder and saved on each Reading.
    let id: String
    let name: String
    let subtitle: String
    let title: String
    /// One or two sentences shown on the Read page.
    let blurb: String
    let positions: [String]

    var needsQuestion: Bool { id == "question" }
    var cardCount: Int { positions.count }

    static let all: [SpreadDefinition] = [
        SpreadDefinition(id: "daily", name: "Daily", subtitle: "1 card",
                         title: "Daily Card",
                         blurb: "One card to set the tone for your day. Draw it once, and it stays yours until tomorrow.",
                         positions: ["Daily Card"]),
        SpreadDefinition(id: "three_card", name: "Three", subtitle: "3 cards",
                         title: "Three Card Spread",
                         blurb: "Past, present and future. A quick look at where something has been and where it is heading.",
                         positions: ["Past", "Present", "Future"]),
        SpreadDefinition(id: "four_card", name: "Four", subtitle: "Situation spread",
                         title: "Four Card Spread",
                         blurb: "Past, present and future, plus the situation as it stands right now.",
                         positions: ["Past", "Present", "Future", "Current Situation"]),
        SpreadDefinition(id: "clarity", name: "Clarity", subtitle: "4 card spread",
                         title: "Clarity Spread",
                         blurb: "One central card and three factors behind it. For when something feels tangled.",
                         positions: ["The Situation", "Factor One", "Factor Two", "Factor Three"]),
        SpreadDefinition(id: "question", name: "Ask", subtitle: "5 card spread",
                         title: "Question Spread",
                         blurb: "Ask a question and get a five card answer, from the background to what to do next.",
                         positions: ["The Question", "The Background", "The Seeker", "The Environment", "The Answer"]),
        SpreadDefinition(id: "read_me", name: "Read Me", subtitle: "Don't hold back",
                         title: "Read Me",
                         blurb: "Four cards, no filter. Direct, dramatic, and on your side.",
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
