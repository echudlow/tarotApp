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
        SpreadDefinition(id: "star", name: "Star", subtitle: "6 card spread",
                         title: "Star Spread",
                         blurb: "Hold one clear question in mind. Six cards cover where you are, what caused it, and the likely way through.",
                         positions: ["Present Situation", "The Cause", "Needed Changes", "Your Strengths", "Other Challenges", "Likely Solution"],
                         promptIntro: "This is a Star Spread for one specific question or issue. Card 1 is the present situation. Card 2 is the cause of the issue. Card 3 is the change needed to resolve it. Card 4 is the strength the seeker needs to draw on. Card 5 is the other challenges still to overcome. Card 6, in the center, is the likely solution.",
                         requiresUnlock: true),
        SpreadDefinition(id: "healing", name: "Healing", subtitle: "6 card spread",
                         title: "Healing Spread",
                         blurb: "A gentle look inward at something you are carrying, from where it began to how to keep it from returning.",
                         positions: ["The Issue Within", "Its Past Effects", "Its Present Effects", "The Source", "Steps to Resolve", "Keeping It Away"],
                         promptIntro: "This is a Healing Spread, a reflective look at an inner issue. Card 1 is the issue inside the seeker. Card 2 is the effect it has had on them and others in the past. Card 3 is the effect it is having now. Card 4 is the source of the issue and what feeds it. Card 5 is the steps that would help resolve it. Card 6 is the habits that would keep it from coming back. Be warm, steady, and honest. This is for reflection and is not therapy or medical advice, so do not diagnose anything.",
                         requiresUnlock: true),
        SpreadDefinition(id: "elements", name: "Elements", subtitle: "5 card spread",
                         title: "Elements Spread",
                         blurb: "Earth, air, fire and water, plus intuition. Five angles on one situation.",
                         positions: ["Earth", "Air", "Fire", "Water", "Intuition"],
                         promptIntro: "This is an Elements Spread about one situation in the seeker's life. Card 1 is Earth: where they can find nourishment and what resources they start with. Card 2 is Air: what ideas might inspire them and how they can communicate better. Card 3 is Fire: what moves them, their passion and creative drive. Card 4 is Water: their emotions and how to manage them well. Card 5 is Intuition: the message from the cards for the whole situation.",
                         requiresUnlock: true),
        SpreadDefinition(id: "tree_of_life", name: "Tree of Life", subtitle: "10 card spread",
                         title: "Tree of Life",
                         blurb: "Ten cards for a deep look at one issue: its force and form, who helps and who resists, and what it asks of you.",
                         positions: ["Force", "Form", "Helping Forces", "Opposing Forces", "Feelings", "Thoughts",
                                     "Body and Belongings", "Persona", "Intuition", "Spirit"],
                         promptIntro: "This is a Tree of Life spread about one issue. 1 Force is the drive behind the issue. 2 Form is the shape it takes. 3 Helping Forces are the people or forces on the seeker's side. 4 Opposing Forces are those working against them. 5 Feelings are what they feel about it. 6 Thoughts are what they think about it. 7 Body and Belongings covers the physical and material side, including their body and possessions. 8 Persona is who they are and how they present, combined. 9 Intuition is what their inner self advises. 10 Spirit is the spiritual growth the issue and its resolution can bring.",
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
