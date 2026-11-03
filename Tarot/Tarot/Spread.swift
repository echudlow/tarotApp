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

    /// The moon spreads and the Year Ahead only open on certain days (see SpecialDays.swift).
    /// Debug builds are always open, so they can be tested any day.
    var isAvailableToday: Bool { SpecialDays.isOpen(id) }
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
        SpreadDefinition(id: "new_moon", name: "New Moon", subtitle: "5 card spread",
                         title: "New Moon",
                         blurb: "A spread for setting intentions. What the moon holds, what to stay open to, and where to put your focus. Opens around each new moon.",
                         positions: ["What This Moon Holds", "Your Energy", "Stay Open To", "Ready to Manifest", "Where to Focus"],
                         promptIntro: "This is a New Moon spread, for setting intentions and beginning something. Card 1 is what this new moon holds for the seeker. Card 2 is the seeker's own energy during it. Card 3 is what they need to stay open to. Card 4 is something that wants to come into being now. Card 5 is where to put their attention to bring their desires into reality. Keep the tone hopeful and practical, and about beginnings.",
                         requiresUnlock: true),
        SpreadDefinition(id: "full_moon", name: "Full Moon", subtitle: "5 card spread",
                         title: "Full Moon",
                         blurb: "A spread for seeing yourself clearly, at the moon's brightest. Your gifts, what fills you up, and what you have not yet noticed. Opens around each full moon.",
                         positions: ["How You See Yourself", "Your Gifts", "What You Offer Others", "What Fills You Up", "Hidden Potential"],
                         promptIntro: "This is a Full Moon spread, about illumination and self-knowledge. Card 1 is how the seeker sees themselves. Card 2 is their best qualities. Card 3 is what they give to others. Card 4 is what fulfills them. Card 5 is potential they have not recognized yet. Keep the tone clear and affirming, and about what is now visible.",
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
                         blurb: "One card for each month, and one for the year as a whole. Opens for a few days around New Year's Eve.",
                         positions: ["January", "February", "March", "April", "May", "June",
                                     "July", "August", "September", "October", "November", "December", "Theme of the Year"],
                         promptIntro: "This is a Year Ahead spread. Cards 1 to 12 are the twelve months in order, January through December. Card 13 is the overall theme of the year. Keep each month short and concrete, let the months build a story, and tie it to the theme at the end.",
                         requiresUnlock: true),
        SpreadDefinition(id: "yule", name: "Yule", subtitle: "6 card spread",
                         title: "Yule",
                         blurb: "A read for the longest night of the year: rest, release, and the slow return of the light. Opens for a few days around the winter solstice.",
                         positions: ["What Hides in the Dark", "Strength for the Shadow", "What to Release",
                                     "What Needs Rest", "How Rest Helps", "The Season's Lesson"],
                         promptIntro: "This is a Yule spread for the winter solstice, the longest night, about rest and the return of the light. Card 1 is what hides in the dark right now. Card 2 is the strength the seeker has for getting through the shadow. Card 3 is what to release. Card 4 is what needs rest. Card 5 is how that rest will help them. Card 6 is the lesson of the season. Keep the tone quiet, warm and patient.",
                         requiresUnlock: true),
        SpreadDefinition(id: "ostara", name: "Ostara", subtitle: "6 card spread",
                         title: "Ostara",
                         blurb: "A read for the spring equinox, when day and night are equal. Balance, waking up, and what is ready to grow. Opens for a few days around the equinox.",
                         positions: ["Welcoming Change", "Restoring Balance", "What Is Awakening",
                                     "What to Let Go", "Where to Grow", "Spring's Theme"],
                         promptIntro: "This is an Ostara spread for the spring equinox, about balance and new growth. Card 1 is how the seeker can welcome change. Card 2 is how to restore balance. Card 3 is what is waking up in them. Card 4 is what to let go of. Card 5 is where to put their energy to grow. Card 6 is the theme of the season. Keep the tone fresh, hopeful and grounded.",
                         requiresUnlock: true),
        SpreadDefinition(id: "litha", name: "Litha", subtitle: "6 card spread",
                         title: "Litha",
                         blurb: "A read for midsummer, the brightest day. Your inner fire, what you have planted, and what the light shows. Opens for a few days around the summer solstice.",
                         positions: ["Staying Grounded", "Keeping the Flame", "Your Inner Fire",
                                     "Tending Your Seeds", "What to Release", "What Gets Illuminated"],
                         promptIntro: "This is a Litha spread for the summer solstice, the height of the light, about energy, growth and honest seeing. Card 1 is how the seeker stays grounded. Card 2 is how to keep their flame going. Card 3 is their inner fire. Card 4 is the seeds they planted and need to tend. Card 5 is what to release. Card 6 is what the light is showing. Keep the tone warm, vivid and confident.",
                         requiresUnlock: true),
        SpreadDefinition(id: "samhain", name: "Samhain", subtitle: "7 card spread",
                         title: "Samhain",
                         blurb: "A read for the thin veil at the end of October. A message from a spirit, three ways. Opens for a few days around Halloween.",
                         positions: ["The Spirit", "Message One", "Message Two", "Message Three",
                                     "Why Now", "Direct Message", "What to Take Away"],
                         promptIntro: "This is a Samhain spread, for the time when the veil between the seen and unseen feels thin. Card 1 is the spirit coming forward to speak. Cards 2, 3 and 4 are three messages from it, in order. Card 5 is why the message arrives now. Card 6 is the most direct message. Card 7 is what to take away. Treat the spirit as a symbol for an ancestor, a memory, a past self, or the seeker's own intuition. Keep it grounded and reflective, not spooky.",
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
