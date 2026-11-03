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

    /// Extra, spread-specific guidance for the prompt (used by the longer spreads).
    var promptIntro: String = ""
    /// True for the spreads that need the one-time unlock from the first read (the daily is free).
    var requiresUnlock: Bool = false

    var needsQuestion: Bool { id == "question" }

    /// Only the Year Ahead is date-gated: it opens on December 31 (local time).
    /// DEBUG builds can always open it, so it can be tested any day.
    var isAvailableToday: Bool {
        guard id == "year_ahead" else { return true }
        #if DEBUG
        return true
        #else
        let c = Calendar.current.dateComponents([.month, .day], from: Date())
        return c.month == 12 && c.day == 31
        #endif
    }
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
                         positions: ["Past", "Present", "Future", "Current Situation"]),
        SpreadDefinition(id: "connection", name: "Connection", subtitle: "5 card spread",
                         title: "Connection Spread",
                         blurb: "You, the other person, and what lives between you. For a partner, a friend, or anyone on your mind.",
                         positions: ["You", "Your Challenge", "The Other Person", "Their Challenge", "The Uniting Force"],
                         promptIntro: "This is a Connection Spread about the bond between the seeker and one other person. Card 1 is the seeker, card 2 is the challenge the seeker brings to the bond, card 3 is the other person, card 4 is the challenge the other person brings, and card 5 is the uniting force that holds the two together.",
                         requiresUnlock: true),
        SpreadDefinition(id: "celtic_cross", name: "Celtic Cross", subtitle: "10 card spread",
                         title: "Celtic Cross",
                         blurb: "The classic deep read. Ten cards covering the heart of a matter, what crosses it, and where it lands.",
                         positions: ["Heart of the Matter", "Opposing Factors", "Root Cause", "Past", "Goal",
                                     "Future", "You", "External Influences", "Hopes and Fears", "Final Outcome"],
                         promptIntro: "This is a Celtic Cross. 1 Heart of the Matter is the issue at its center. 2 Opposing Factors is what works against it. 3 Root Cause is the foundation underneath. 4 Past is what is passing out of the picture. 5 Goal is what the seeker is aiming at. 6 Future is what comes next. 7 You is the seeker's own stance. 8 External Influences is the people and conditions around them. 9 Hopes and Fears is what they want and dread, often the same thing. 10 Final Outcome is where it settles.",
                         requiresUnlock: true),
        SpreadDefinition(id: "year_ahead", name: "Year Ahead", subtitle: "13 card spread",
                         title: "Year Ahead",
                         blurb: "One card for each month, and one for the year as a whole. Opens only on New Year's Eve.",
                         positions: ["January", "February", "March", "April", "May", "June",
                                     "July", "August", "September", "October", "November", "December", "Theme of the Year"],
                         promptIntro: "This is a Year Ahead spread. Cards 1 to 12 are the twelve months in order, January through December. Card 13 is the overall theme of the year. Keep each month short and concrete, let the months build a story, and tie it to the theme at the end.",
                         requiresUnlock: true)
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
