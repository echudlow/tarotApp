//  ContentView.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/10/25.
//

import SwiftUI
import SwiftData

struct DrawnCard: Identifiable {
    let id = UUID()
    let card: TarotCard
    let isReversed: Bool
    let position: String      // Past / Present / etc
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TarotCard.name) private var cards: [TarotCard]

    @State private var spread: [DrawnCard] = []
    
    @State private var interpretation: String? = nil
    @State private var isLoadingINterpretation: Bool = false
    @State private var interpretationError: String? = nil
    @State private var interpretTask: Task<Void, Never>? = nil
    @State private var activeRequestID = UUID()

    
    private let tarotService = TarotService()

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Buttons row
                Section {
                    HStack {
                        Button("Daily Card") {
                            drawSpread(spreadType: "daily",
                                       positions: ["Daily Card"])
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("3-Card Spread") {
                            drawSpread(spreadType: "three_card",
                                       positions: ["Past", "Present", "Future"])
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("4-Card Spread") {
                            drawSpread(spreadType: "four_card",
                                       positions: ["Past", "Present", "Future", "Current Situation"])
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // MARK: - Current Spread
                Section("Current Spread") {
                    if spread.isEmpty {
                        Text("Tap a button above to draw a spread.")
                            .foregroundStyle(.secondary)
                    } else {

                        // 1. Show each card individually
                        ForEach(spread) { drawn in
                            let card = drawn.card

                            VStack(alignment: .leading, spacing: 6) {

                                // Position label (Past, Present, etc)
                                Text(drawn.position)
                                    .font(.caption)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)

                                // Card name + reversed tag
                                HStack {
                                    Text(card.name)
                                        .font(.headline)
                                    if drawn.isReversed {
                                        Text("(Reversed)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                // Image
                                if let imageName = card.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                        .rotationEffect(drawn.isReversed ? .degrees(180) : .degrees(0))
                                        .cornerRadius(8)
                                }

                                // Upright or Reversed meaning
                                Text(drawn.isReversed
                                     ? "Reversed: \(card.reversedMeaning)"
                                     : "Upright: \(card.uprightMeaning)"
                                )
                                .font(.body)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }

                        // 2. Single interpretation block at the end
                        VStack(alignment: .leading, spacing: 8) {

                            if isLoadingINterpretation {
                                ProgressView("Interpreting your spread…")
                                    .padding(.top, 8)

                            } else if let error = interpretationError {
                                Text("Could not interpret this spread: \(error)")
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                                    .padding(.top, 8)

                            } else if let text = interpretation {
                                Divider()
                                    .padding(.top, 8)

                                Text("Interpretation")
                                    .font(.headline)

                                Text(text)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                }


                // MARK: - Deck navigation
                Section("Deck") {
                    NavigationLink("View All Cards") {
                        AllCardsView()
                    }
                }
            }
            .navigationTitle("Tarot Deck")
        }
        // Seed deck automatically in the background
        .task {
            seedTarotDeckIfNeeded()
        }
    }

    // MARK: - Spread logic

    private func drawSpread(spreadType: String, positions: [String]) {
        guard cards.count >= positions.count else { return }

        let selected = Array(cards.shuffled().prefix(positions.count))

        let newSpread: [DrawnCard] = selected.enumerated().map { index, card in
            DrawnCard(card: card,
                      isReversed: Bool.random(),
                      position: positions[index])
        }

        // Update UI immediately
        spread = newSpread

        // Reset interpretation state
        interpretation = nil
        interpretationError = nil
        isLoadingINterpretation = true

        // Cancel any in-flight interpretation
        interpretTask?.cancel()

        // New request ID for this draw
        let requestID = UUID()
        activeRequestID = requestID

        interpretTask = Task {
            await interpretSpreadSnapshot(
                spreadType: spreadType,
                spreadSnapshot: newSpread,
                requestID: requestID
            )
        }

    }
    
    private func interpretSpreadSnapshot(
        spreadType: String,
        spreadSnapshot: [DrawnCard],
        requestID: UUID
    ) async {
        defer {
            if activeRequestID == requestID {
                isLoadingINterpretation = false
            }
        }

        // If we were cancelled, stop immediately
        if Task.isCancelled { return }

        let apiCards: [TarotAPICard] = spreadSnapshot.map { drawn in
            TarotAPICard(
                name: drawn.card.name,
                position: drawn.position,
                isReversed: drawn.isReversed,
                uprightMeaning: drawn.card.uprightMeaning,
                reversedMeaning: drawn.card.reversedMeaning,
                suit: drawn.card.suit,
                arcana: drawn.card.arcana
            )
        }

        let body = SpreadRequestBody(spread_type: spreadType, cards: apiCards)

        do {
            let response = try await tarotService.interpretSpread(body)

            // Ignore stale responses
            guard activeRequestID == requestID else { return }

            interpretation = response.interpretation
        } catch {
            guard !Task.isCancelled else { return }
            guard activeRequestID == requestID else { return }

            interpretationError = error.localizedDescription
            print("Interpretation error:", error)
        }
    }

    
    private func seedTarotDeckIfNeeded() {
        guard cards.isEmpty else { return }

        let fool = TarotCard(
            name: "The Fool",
            suit: nil,
            number: 0,
            uprightMeaning: "Thoughtlessness, folly, lightheartedness, innocence. Purity of heart. Lack of discipline. One seeking fulfillment and experience. Freedom, lack of restraint.",
            reversedMeaning: "Carelessness, vanity, indecision, poor judgement, apathy. Lack of control.",
            keywords: ["Innocence", "Beginnings", "Freedom"],
            imageName: "00_the_fool",
            arcana: "Major"
        )

        let magician = TarotCard(
            name: "The Magician",
            suit: nil,
            number: 1,
            uprightMeaning: "Opportunities to use talents. Skill, self reliance, orginality, creativity, imagination, diplomacy. The merging of the four elements.",
            reversedMeaning: "Unskilled, clumsy, insecure, disgrace, bad judgemnet causes loss.",
            keywords: ["Skill", "Manifestation", "Action"],
            imageName: "01_the_magician",
            arcana: "Major"
        )

        let highPriestess = TarotCard(
            name: "The High Priestess",
            suit: nil,
            number: 2,
            uprightMeaning: "Practicality, good judgement, wisdom, mystery, the clouded future. A woman of interest to the seeker, or the seeker herself.",
            reversedMeaning: "Passion, conceit, lack of sense, poor intuition, ignorance, bad judgement.",
            keywords: ["Intuition", "Mystery", "Wisdom"],
            imageName: "02_the_high_priestess",
            arcana: "Major"
        )

        let empress = TarotCard(
            name: "The Empress",
            suit: nil,
            number: 3,
            uprightMeaning: "Pregnancy, fertility, good advice, safety, security, hidden actions. A competent woman, safe and secure, who is building a future for herself and her family.",
            reversedMeaning: "Lack of satisfaction. The unraveling of involved matters. Uncertainty, infedelity, infertility.",
            keywords: ["Fertility", "Nurturing", "Abundance"],
            imageName: "03_the_empress",
            arcana: "Major"
        )

        let emperor = TarotCard(
            name: "The Emperor",
            suit: nil,
            number: 4,
            uprightMeaning: "A father figure, secure and successful. A stable, authoratative, powerful leader. A person with the qualities of reason and conviction.",
            reversedMeaning: "Confusion, obstruction, immaturity, ineffectiveness, weakness of character, megalomania.",
            keywords: ["Authority", "Structure", "Leadership"],
            imageName: "04_the_emperor",
            arcana: "Major"
        )

        let hierophant = TarotCard(
            name: "The Hierophant",
            suit: nil,
            number: 5,
            uprightMeaning: "Tradition, captivity, servitude, ritual, inactivity, retention, timidity. A desire to hold onto old thoughts and ways even if they are outdated. Concern for form over function.",
            reversedMeaning: "A foolish exercise in generosity, eccentricity, intrigue, weakness.",
            keywords: ["Tradition", "Spirituality", "Conformity"],
            imageName: "05_the_hierophant",
            arcana: "Major"
        )

        let lovers = TarotCard(
            name: "The Lovers",
            suit: nil,
            number: 6,
            uprightMeaning: "Love, respect, partnership, trust, communication, perfection, honor, romance, beauty. A couple that has worked together to overcome trials.",
            reversedMeaning: "Failure, unreliability, separation, frustration in marriage, instability, confusion, silence. The inability or disinclination to share thoughts.",
            keywords: ["Partnership", "Choice", "Union"],
            imageName: "06_the_lovers",
            arcana: "Major"
        )

        let chariot = TarotCard(
            name: "The Chariot",
            suit: nil,
            number: 7,
            uprightMeaning: "Work and travel, purpose, trouble or problems fall behind, triumph, harmony, balance. Controlling forces which might conflict and bringing them together to form a working whole.",
            reversedMeaning: "Quarrels, trouble, defeat, failure, the collapse of hopes or dreams, unfavorable legal proceedings.",
            keywords: ["Willpower", "Victory", "Control"],
            imageName: "07_the_chariot",
            arcana: "Major"
        )

        let strength = TarotCard(
            name: "Strength",
            suit: nil,
            number: 8,
            uprightMeaning: "Power, energy, strength, courage, conviction. The gift to soothe others' grief or to help solve their problems.",
            reversedMeaning: "Weakness, sickness, lack of faith, despotism, discord, abuse of power, a fear of loneliness.",
            keywords: ["Courage", "Inner Strength", "Compassion"],
            imageName: "08_strength",
            arcana: "Major"
        )

        let hermit = TarotCard(
            name: "The Hermit",
            suit: nil,
            number: 9,
            uprightMeaning: "Meditation, the search for the truth, good counsel, wisdom, prudence. A withdrawal from life is needed to find one's center.",
            reversedMeaning: "Hastiness, imprudence, unreasoning caution or fear, emotional immaturity. Withdrawal from one's problems with no contructive plans.",
            keywords: ["Solitude", "Reflection", "Wisdom"],
            imageName: "09_the_hermit",
            arcana: "Major"
        )

        let wheelOfFortune = TarotCard(
            name: "Wheel of Fortune",
            suit: nil,
            number: 10,
            uprightMeaning: "Change, destiny, fortune, good luck, the end of troubles in sight. Moving ahead for better or worse.",
            reversedMeaning: "Reversal of fortunes, failure, bad luck, unexpected interference.",
            keywords: ["Cycles", "Fate", "Change"],
            imageName: "10_wheel_of_fortune",
            arcana: "Major"
        )

        let justice = TarotCard(
            name: "Justice",
            suit: nil,
            number: 11,
            uprightMeaning: "Fairness, balance, equality, rightness, legal matters, negotiations.",
            reversedMeaning: "Bias, prejudice, intolerance, cruel punishment, a bad judgement(legal).",
            keywords: ["Fairness", "Truth", "Law"],
            imageName: "11_justice",
            arcana: "Major"
        )

        let hangedMan = TarotCard(
            name: "The Hanged Man",
            suit: nil,
            number: 12,
            uprightMeaning: "Suspense, life interrupted, chagne. Wisdom in occult matters. Sacrifice for wisdom. Inner serach for turth. Change in your point of view.",
            reversedMeaning: "A wasteful search, selfishness. Lack of effort needed to achieve a goal. A useless gesture.",
            keywords: ["Surrender", "Perspective", "Pause"],
            imageName: "12_the_hanged_man",
            arcana: "Major"
        )

        let death = TarotCard(
            name: "Death",
            suit: nil,
            number: 13,
            uprightMeaning: "The end of an era(and a beginning). A reminder of mortality. A grea change. A discovery that changes the seeker's life direction.",
            reversedMeaning: "Lethargy, great inertia, depression, slow or ponderous change. Resisting the innevitable.",
            keywords: ["Transformation", "Endings", "Release"],
            imageName: "13_death",
            arcana: "Major"
        )

        let temperance = TarotCard(
            name: "Temperance",
            suit: nil,
            number: 14,
            uprightMeaning: "Economy, patience, a moderate lifestyle. Obtaining security through frugal managemnt of means. Meditation. All things in moderation---including moderation.",
            reversedMeaning: "Competitive interests. Hostility. Too much caution. A person with whom it is impossbile to work. Misunderstanding others.",
            keywords: ["Balance", "Moderation", "Harmony"],
            imageName: "14_temperance",
            arcana: "Major"
        )

        let devil = TarotCard(
            name: "The Devil",
            suit: nil,
            number: 15,
            uprightMeaning: "Greed, the monkey trap. Vehement desires, lust. Bondage to an ideal. Bad or evil influence or advice. Dissolution. A choice upon which your fate depends.",
            reversedMeaning: "A release from bondage. A rest. A new life's direction.",
            keywords: ["Bondage", "Temptation", "Shadow"],
            imageName: "15_the_devil",
            arcana: "Major"
        )

        let tower = TarotCard(
            name: "The Tower",
            suit: nil,
            number: 16,
            uprightMeaning: "Sudden chagne, broken friendships, destruction, security lost, a disgrace. Catastrophic transformation.",
            reversedMeaning: "Tyranny, continued oppression. Lack of change, monetary losses.",
            keywords: ["Upheaval", "Shock", "Revelation"],
            imageName: "16_the_tower",
            arcana: "Major"
        )

        let star = TarotCard(
            name: "The Star",
            suit: nil,
            number: 17,
            uprightMeaning: "Hope and faith. A blending of the best of the past and present. Bright prospects. Mastering the occult arts. An awareness of two worlds.",
            reversedMeaning: "Laziness and indifference. Unrealized hopes. Arrogance, pride. Delays, loss of hope or faith.",
            keywords: ["Hope", "Renewal", "Guidance"],
            imageName: "17_the_star",
            arcana: "Major"
        )

        let moon = TarotCard(
            name: "The Moon",
            suit: nil,
            number: 18,
            uprightMeaning: "A warning, deception. Enemies who are out of sight. A caution to stay on your path for safety. Darkness, companions out of their element.",
            reversedMeaning: "A white lie, a trick, a tiny mistake. Silence, stillness. Unexpected gain with no cost exacted.",
            keywords: ["Illusion", "Uncertainty", "Subconscious"],
            imageName: "18_the_moon",
            arcana: "Major"
        )

        let sun = TarotCard(
            name: "The Sun",
            suit: nil,
            number: 19,
            uprightMeaning: "Accomplishment, success, material happiness. A good marriage, pleasure, joy. Liberation, freedom, contentment.",
            reversedMeaning: "Lesser joys. A separation from loved ones. Delayed success or postponed security. An uncertain future.",
            keywords: ["Joy", "Vitality", "Success"],
            imageName: "19_the_sun",
            arcana: "Major"
        )

        let judgement = TarotCard(
            name: "Judgement",
            suit: nil,
            number: 20,
            uprightMeaning: "A change of position, rejuvenation, rebirth. Reward, acquiring a purpose. Atonement, paying the piper, accoutning for one's actions.",
            reversedMeaning: "Weakness. Lost affections, separation, divorce. Confrontation, indecision. Avoidance of obligations.",
            keywords: ["Rebirth", "Awakening", "Accountability"],
            imageName: "20_judgement",
            arcana: "Major"
        )

        let world = TarotCard(
            name: "The World",
            suit: nil,
            number: 21,
            uprightMeaning: "Completion, the end of a way of life, success. A new beginning, a change of location, hope for the future. Triumph in the end. The admiration of friends. The breadth of possibilties.",
            reversedMeaning: "Disappointment. Discouragingly tiny advance. Failure, inability to finish what you have started. Permanence, stagnation.",
            keywords: ["Completion", "Integration", "Fulfillment"],
            imageName: "21_the_world",
            arcana: "Major"
        )
        
        let pentaclesCards: [TarotCard] = [
            TarotCard(
                name: "King of Pentacles",
                suit: "Pentacles",
                number: nil,
                uprightMeaning: "A rich man(materially and spiritually), steady reliable, earthy, helpful, sensual.",
                reversedMeaning: "Too materialistic. A tendency toward stupidity and stubbornness. Perverse use of talents. A dangerous man when angry. Addiction to physical comfort.",
                keywords: [],
                imageName: "king_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Queen of Pentacles",
                suit: "Pentacles",
                number: nil,
                uprightMeaning: "A warm, generous woman who has the seeker's best interest at heart. No fear of hard work. Monetary gifts, intelligence, thoughtfulness.",
                reversedMeaning: "Too dependent, duties negelected. Unetrusting, false prosperity. Changeable nature due to fear of failure.",
                keywords: [],
                imageName: "queen_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Knight of Pentacles",
                suit: "Pentacles",
                number: nil,
                uprightMeaning: "A mature man, responsible, reliable, utilitarian. A person who will help the seeker. Honorable. Solid. Travel is possible.",
                reversedMeaning: "Problems at work. A warning against travel. The seeker should guard against deceity, carelessness, intertia, laziness.",
                keywords: [],
                imageName: "knight_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Page of Pentacles",
                suit: "Pentacles",
                number: nil,
                uprightMeaning: "A careful child. Deep concentration. Scholarship news, bringer of messages. A young person who makes the seeker proud.",
                reversedMeaning: "Bad news, delinquency, illogical thoughts, wastefulness.",
                keywords: [],
                imageName: "page_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ten of Pentacles",
                suit: "Pentacles",
                number: 10,
                uprightMeaning: "Prospertity - Riches. Home adn family matters. Positive domestic changes.",
                reversedMeaning: "Loss of belongings. An emotional loss or a death. Gambling, a bad risk.",
                keywords: [],
                imageName: "ten_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Nine of Pentacles",
                suit: "Pentacles",
                number: 9,
                uprightMeaning: "Solitary wealth and luxury - Accomplishment, discretion, safety, security, femininity, material comfort, love of nature, solitary achievements, working alone.",
                reversedMeaning: "Threat. Loss of security. Danger.",
                keywords: [],
                imageName: "nine_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Eight of Pentacles",
                suit: "Pentacles",
                number: 8,
                uprightMeaning: "Learning - Learning, apprenticeship, gaining new knowledge or skills, workign very hard at low-paying levels, nose to the grindstone. Creation.",
                reversedMeaning: "A lack of emotion, vanity. Caution against borrowing money.",
                keywords: [],
                imageName: "eight_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Seven of Pentacles",
                suit: "Pentacles",
                number: 7,
                uprightMeaning: "Material progress - Cleverness, growth through hard work. Surprisingly good news. Help will prove useful.",
                reversedMeaning: "Anxiety about finances. Money lost. Bad investments.",
                keywords: [],
                imageName: "seven_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Six of Pentacles",
                suit: "Pentacles",
                number: 6,
                uprightMeaning: "Gratification - Help with finances. Return of a favor. Gifts, stability. Gratifying your desire to help or repay another.",
                reversedMeaning: "Jealousy can cause harm. Unstable finances frustrate plans. Desire, avarice. A bad debt.",
                keywords: [],
                imageName: "six_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Five of Pentacles",
                suit: "Pentacles",
                number: 5,
                uprightMeaning: "Misery - Destution, loss, loneliness, being out in the cold. Lovers who cannot find a meeting place. Poor health, spiritual impoverishment.",
                reversedMeaning: "Lessons in charity to be learned. New employment(possibly temporary). New courage. New interest in spiritual matters.",
                keywords: [],
                imageName: "five_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Four of Pentacles",
                suit: "Pentacles",
                number: 4,
                uprightMeaning: "Miser - Miserliness, greed, selfishness. Avarice, suspicision, mistrust. Inability to let go of anything. An emotional black hole; shortsightedness, imbalance, desperation.",
                reversedMeaning: "Suspense of gain, opposition, reversal of fortunes.",
                keywords: [],
                imageName: "four_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Three of Pentacles",
                suit: "Pentacles",
                number: 3,
                uprightMeaning: "Master craftsman - Skills and abilities will be appreciated and rewarded. Artistic ability, rank, power, achievement. Success through effort.",
                reversedMeaning: "Sloppiness in workmanship. Delay of recognition or recompense. Preoccupation with gain at the cost of craft. Mediocrity.",
                keywords: [],
                imageName: "three_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Two of Pentacles",
                suit: "Pentacles",
                number: 2,
                uprightMeaning: "The Juggler, Balance - Ability to handle several things at once. Harmony in the midst of conflict and change. Fun and games. Knowing the re=opes. Balacne in self and in life, control.",
                reversedMeaning: "Too much to handle. Instability. Lack of control. Forced gaiety.",
                keywords: [],
                imageName: "two_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ace of Pentacles",
                suit: "Pentacles",
                number: 1,
                uprightMeaning: "Reward, Riches - Pure contentment, attainment, bright prospects, prosperity--both material and spiritual.",
                reversedMeaning: "Unhappiness with wealth, misuse of power, corruption.",
                keywords: [],
                imageName: "ace_of_pentacles",
                arcana: "Minor"
            )
        ]
        
        let swordsCards: [TarotCard] = [
            TarotCard(
                name: "King of Swords",
                suit: "Swords",
                number: nil,
                uprightMeaning: "A perceptive, intelligent, and strong willed man is indicated.",
                reversedMeaning: "Crueld and hardhearted. Pig-headed, untrustworthy, crafty.",
                keywords: [],
                imageName: "king_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Queen of Swords",
                suit: "Swords",
                number: nil,
                uprightMeaning: "A strong woman, confident, quickwitted, and intensely perceptive.",
                reversedMeaning: "Keeness sharpened to cruelty. Sly, deceitful, narrow-minded. A gossip. Quarrelsome.",
                keywords: [],
                imageName: "queen_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Knight of Swords",
                suit: "Swords",
                number: nil,
                uprightMeaning: "A soldier; heroic, brave. Righteous anger. Triumph over an opposition. A pracitcal solution to a problem.",
                reversedMeaning: "Unsuccessful or erratic behavior. Bad judgement, extravagance. The seeker makes an impulsive mistake.",
                keywords: [],
                imageName: "knight_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Page of Swords",
                suit: "Swords",
                number: nil,
                uprightMeaning: "Vigilance, agility, insight, keen vision. Service done in secret. The seeker obtains the help of a younger person.",
                reversedMeaning: "Childish cruelty. Unfortunate circumstances. The unforeseen. Vulnerability in the face of opposing force.",
                keywords: [],
                imageName: "page_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ten of Swords",
                suit: "Swords",
                number: 10,
                uprightMeaning: "No, it is that bad! - Misfortunes, ruin, defeat, loss, failure, pain, desolation beyond tears. Alternatively, evils or misfortunes which are over.",
                reversedMeaning: "Evil overthrown, courage, success, recovery, turning toward higher sources.",
                keywords: [],
                imageName: "ten_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Nine of Swords",
                suit: "Swords",
                number: 9,
                uprightMeaning: "Night terrors - Suffering, desolation, doubt, suspicion, misery, dishonesty, slander, a vicious circle. Illness or injury to a loved one. Alternatively, troubles which aren't over yet. The worst is yet to come.",
                reversedMeaning: "An end to suffering, desolation, or doubt. Patience, faithfulness. Good news about a loved one.",
                keywords: [],
                imageName: "nine_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Eight of Swords",
                suit: "Swords",
                number: 8,
                uprightMeaning: "I just cant't! - Fear, bondage, paralysis due to censure, indecision, illness, difficulties. A nearly impossbile task. Can symbolize prison.",
                reversedMeaning: "Respite from fear, new beginnings, freedom, release.",
                keywords: [],
                imageName: "eight_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Seven of Swords",
                suit: "Swords",
                number: 7,
                uprightMeaning: "Thief - Failure of a plan. Taking something that belongs to another, unreliability, betrayal, spying. A less-than-honorable action. However, depending on the surrounding cards, bravery and care. Stealth.",
                reversedMeaning: "Over-qualification, return of stolen property, good advice.",
                keywords: [],
                imageName: "seven_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Six of Swords",
                suit: "Swords",
                number: 6,
                uprightMeaning: "Rite of passage - Water journey. Passage to a higher state of consciousness. Leaving difficulties for safe refuge. Finding an understanding.",
                reversedMeaning: "No-escape. Journey postponed. A trip to a higher level of consciousness is advised.",
                keywords: [],
                imageName: "six_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Five of Swords",
                suit: "Swords",
                number: 5,
                uprightMeaning: "Nyaa-nya-nya-nyaa-nya - Failure, defeat, degradation, winnign by unfair means, trickery, cowardice, manipulation. A loss decreed by the gods.",
                reversedMeaning: "Same as upright meaning, but lessened. An empty vitory. Unfairness and slyuness in dealing with others.",
                keywords: [],
                imageName: "five_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Four of Swords",
                suit: "Swords",
                number: 4,
                uprightMeaning: "Restful, private place - Rest, seclusion, convalescence. A return to the basics. Meditation.",
                reversedMeaning: "An end to rest. A return to active life.",
                keywords: [],
                imageName: "four_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Three of Swords",
                suit: "Swords",
                number: 3,
                uprightMeaning: "Tears and woe - Sorrow, loss, emotional pain, grief, separation. The end of an affair of the heart.",
                reversedMeaning: "Same as upright meaning, but not as extreme.",
                keywords: [],
                imageName: "three_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Two of Swords",
                suit: "Swords",
                number: 2,
                uprightMeaning: "Balance - Dangerous spot, precarious balance. Possible problems ahead. A chocie of lesser of two evils. The seeker has the knowledge and ability to balance the situation and make the best of it.",
                reversedMeaning: "The waiting is over. Stalemate ended. Beware of a new situation. The seeker, or someone known to the seeker may travel soon.",
                keywords: [],
                imageName: "two_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ace of Swords",
                suit: "Swords",
                number: 1,
                uprightMeaning: "Victory - The seeker might be a champion, hero, or leader. The birth of a valiant child may be indicated. Attainment of power or goals.",
                reversedMeaning: "Excessive use of force. Destruction. Obstacles. Tyranny. A separation. Beware of using too much power to gain your ends.",
                keywords: [],
                imageName: "ace_of_swords",
                arcana: "Minor"
            )
        ]

        let wandsCards: [TarotCard] = [
            TarotCard(
                name: "King of Wands",
                suit: "Wands",
                number: nil,
                uprightMeaning: "A man of passion, handsome, conscientious, noble, strong. Sometimes hasty.",
                reversedMeaning: "A severe man, harsh, opinionated, strict, quarrelsome. Sometimes intolerant or prejudiced.",
                keywords: [],
                imageName: "king_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Queen of Wands",
                suit: "Wands",
                number: nil,
                uprightMeaning: "A woman of considerable energy, very active, very passionate. Also, fond of nature, generous, and practical.",
                reversedMeaning: "Strict, domineering, jealous, vengeful. A deceitful woman. Passion overrules all other concerns. A tendency toward unfaithfulness.",
                keywords: [],
                imageName: "queen_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Knight of Wands",
                suit: "Wands",
                number: nil,
                uprightMeaning: "A journey. Practical action taken in spite of distractions.A change of residence.",
                reversedMeaning: "Separation, discord, misunderstanding, progress interrupted. A quarrel.",
                keywords: [],
                imageName: "knight_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Page of Wands",
                suit: "Wands",
                number: nil,
                uprightMeaning: "A child with too much energy. A faithful or loyal person. A stranger explodes into the seekers life with good intentions. A great idea leading to success. A good employee.",
                reversedMeaning: "Childish pranks, indecision, bad news. The behavior of an acquaintance leads the seeker to doubt his or her sincerity. A gossip.",
                keywords: [],
                imageName: "page_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ten of Wands",
                suit: "Wands",
                number: 10,
                uprightMeaning: "Overload - Too much success becomes oppressive. Heavy burden. Martyr complex. Too much willingness to carry others responsibilities. Taking on more than seeker can handle.",
                reversedMeaning: "Selfishness, shifting responsibility to another. Passing the buck.",
                keywords: [],
                imageName: "ten_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Nine of Wands",
                suit: "Wands",
                number: 9,
                uprightMeaning: "Wait for it - Waiting for difficulties, changes, new challenges. Hidden foes, deception, temporary ceasefire in struggle.",
                reversedMeaning: "Obstacles, problems, calamity, illness, disabiltiy.",
                keywords: [],
                imageName: "nine_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Eight of Wands",
                suit: "Wands",
                number: 8,
                uprightMeaning: "Sudden advancement - Swift activiy, the path of activity, hope. Freedom of action after a period of inaction. Too swift a pace, decisions made too hastily. Travel.",
                reversedMeaning: "Jealousy, dispute, a bad conscience. Oppressive conditions (at home or at work).",
                keywords: [],
                imageName: "eight_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Seven of Wands",
                suit: "Wands",
                number: 7,
                uprightMeaning: "Take a stand - Success against obstacles, problems solved or turned aside, bravery.",
                reversedMeaning: "Misgivings about an outcome. Perplexity, anxiety. Hesitancy causes loss.",
                keywords: [],
                imageName: "seven_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Six of Wands",
                suit: "Wands",
                number: 6,
                uprightMeaning: "Triumph - Public acclamation, gain, good news (important news), achievement, reward for hard work, great expectations.",
                reversedMeaning: "Delay, fear, disloyalty, inconclusive victory, acclaim with no real substance.",
                keywords: [],
                imageName: "six_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Five of Wands",
                suit: "Wands",
                number: 5,
                uprightMeaning: "Unfilfilled struggle - Conflict, obstacles, unsatisfied desires, internal strige, indecision.",
                reversedMeaning: "Trickery, complexity, involvement.",
                keywords: [],
                imageName: "five_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Four of Wands",
                suit: "Wands",
                number: 4,
                uprightMeaning: "Romance and tranquility - Harmony, romance, a wedding. New prosperity, fruits of labor, rest, home, harverst, society.",
                reversedMeaning: "Loss of tranquillity, ingratitude. A dissatisfaction with present situation.",
                keywords: [],
                imageName: "four_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Three of Wands",
                suit: "Wands",
                number: 3,
                uprightMeaning: "Ships come in - Good business, strength, grasp of future and of things needed for growth, successful business ventures.",
                reversedMeaning: "Bad business, failed business ventrues, poor grasp of the future.",
                keywords: [],
                imageName: "three_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Two of Wands",
                suit: "Wands",
                number: 2,
                uprightMeaning: "Watch and wait - Wait to see if any plans bear fruit. Kindness, genorosity, intellect, well balanced individual, creative. Good thigns coming, fulfillment.",
                reversedMeaning: "Seeker must avoid impatience. Empty success. Good beginnings go sour. Domination by others.",
                keywords: [],
                imageName: "two_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ace of Wands",
                suit: "Wands",
                number: 1,
                uprightMeaning: "Creation, Power - A beginning. Fertility, birth, growth, life. Energy, virility, inheritance. Adventure.",
                reversedMeaning: "False start, unrealized goal, decadence, stagnation, sterility.",
                keywords: [],
                imageName: "ace_of_wands",
                arcana: "Minor"
            )
        ]

        let cupsCards: [TarotCard] = [
            TarotCard(
                name: "King of Cups",
                suit: "Cups",
                number: nil,
                uprightMeaning: "A kind, considerate man. A father figure. A person interested in the arts, balanced. A deep man with a quiet demeanor, quiet power.",
                reversedMeaning: "A powerful, two-faced man. A violent man. A double-cross.",
                keywords: [],
                imageName: "king_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Queen of Cups",
                suit: "Cups",
                number: nil,
                uprightMeaning: "A soft, nurturing mother figure, perhaps too protective. Kind but not energetic. Will help if its not all too taxing. Good insight, love, gentleness.",
                reversedMeaning: "Too much imagination. Too passive. An overprotective mother who \"means well,\" or is \"only thinking of you, dear.\" A woman who stifles her children.",
                keywords: [],
                imageName: "queen_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Knight of Cups",
                suit: "Cups",
                number: nil,
                uprightMeaning: "An opportunity may be presented to the seeker. Arrival of a lover. Appeal, approach, creativity, inspiration.",
                reversedMeaning: "A person capable or trickery. Warning against fraud. Competition for a love.",
                keywords: [],
                imageName: "knight_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Page of Cups",
                suit: "Cups",
                number: nil,
                uprightMeaning: "A helpful youth of artistic temperment, studious and intense. A trustworthy and trustying employee. The seeker finds that a child brings joy. A birth.",
                reversedMeaning: "Deception, poor taste, seduction, inclination. A lack of discretion. An unpleasant surprise.",
                keywords: [],
                imageName: "page_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ten of Cups",
                suit: "Cups",
                number: 10,
                uprightMeaning: "Welcome home - Home, joy, familial bliss. Peace. Love. Plenty. Contentment of the heart. Respect from your neighbors.",
                reversedMeaning: "The loss of a friendship. Sadness or great disappointment. Indignation.",
                keywords: [],
                imageName: "ten_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Nine of Cups",
                suit: "Cups",
                number: 9,
                uprightMeaning: "Party hearty - Satisfaction, plenty, sensual pleasures, wellbeing, success, security, wishes fulfilled.",
                reversedMeaning: "An absence of upright qualities. Self indulgent behavior, smugness, deprivation or temporary illness.",
                keywords: [],
                imageName: "nine_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Eight of Cups",
                suit: "Cups",
                number: 8,
                uprightMeaning: "Enough of this! - Abandonment of this phase of life, rejection of material things and a turning toward spiritual things. Disappointment in love. A searhc for new paths.",
                reversedMeaning: "A search for pleasure, hedonism, joy, new love, feasting. An abandonment of the responsibilities of life.",
                keywords: [],
                imageName: "eight_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Seven of Cups",
                suit: "Cups",
                number: 7,
                uprightMeaning: "Dreams - Dreaming instead of acting. Overactive imagination. Inability to choose a single path or goal. Illusion. Head in the clouds. A mystical experience, positive visualizations.",
                reversedMeaning: "Determination, strong will, actions.",
                keywords: [],
                imageName: "seven_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Six of Cups",
                suit: "Cups",
                number: 6,
                uprightMeaning: "Home, Childhood - The past, memories, nostalgia, knight on a pillar. Time whcih ahve passed by and vanished. Innocence, youthful idealism.",
                reversedMeaning: "The future, a renewal. Plans which may soon come true (or fail).",
                keywords: [],
                imageName: "six_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Five of Cups",
                suit: "Cups",
                number: 5,
                uprightMeaning: "Despair - Sorrow, loss, disillusionment, bitterness, relationship ending (marriage, work, friendship). Despite feelings, do not give up hope - look for the positive.",
                reversedMeaning: "Renewal, new alliances. The return of a lost one. Courage to overcome difficulties.",
                keywords: [],
                imageName: "five_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Four of Cups",
                suit: "Cups",
                number: 4,
                uprightMeaning: "Introspection, Discontent - Discontent with materialism. A time of introspection and contemplation; start of self-awareness. Alternatively, self-involvement. World-weariness. A search for understanding. Solitude. Disregarding offered gifts.",
                reversedMeaning: "New relationships. The beginning of action. New possibilities.",
                keywords: [],
                imageName: "four_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Three of Cups",
                suit: "Cups",
                number: 3,
                uprightMeaning: "Good luck - Good fortune, artistic ability, sensitivity. Perhaps a party is in store. Fulfillemnt, healing, harmony.",
                reversedMeaning: "Gluttony, overindulgence, or delary. Talents are hidden or unappreciated. Abundance turns to lack, pleasure to pain.",
                keywords: [],
                imageName: "three_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Two of Cups",
                suit: "Cups",
                number: 2,
                uprightMeaning: "Balance, Friendship - Satisfying love, friendship, platonic love, a godo partnership, harmony, cooperation. Opposing forces blend and yield a glorious whole.",
                reversedMeaning: "Loss of balance, violent passion, love, becoming hate, misunderstanding.",
                keywords: [],
                imageName: "two_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ace of Cups",
                suit: "Cups",
                number: 1,
                uprightMeaning: "Bounty - Joy, abundance, perfection, fertility, fulfillment. Good things overflowing, fullness. Favorable outlook, faitfulness. Love.",
                reversedMeaning: "False hope, clouded joy, fulfillment delaryed, false heart, unfaithfulness, false love, change, alteration, sterility.",
                keywords: [],
                imageName: "ace_of_cups",
                arcana: "Minor"
            )
        ]

        
        let majorArcana: [TarotCard] = [
                fool,
                magician,
                highPriestess,
                empress,
                emperor,
                hierophant,
                lovers,
                chariot,
                strength,
                hermit,
                wheelOfFortune,
                justice,
                hangedMan,
                death,
                temperance,
                devil,
                tower,
                star,
                moon,
                sun,
                judgement,
                world
            ]

        for card in majorArcana {
            modelContext.insert(card)
        }

        for card in pentaclesCards {
            modelContext.insert(card)
        }
        
        for card in swordsCards {
            modelContext.insert(card)
        }
        
        for card in wandsCards {
            modelContext.insert(card)
        }
        
        for card in cupsCards {
            modelContext.insert(card)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving tarot deck: \(error)")
        }

    }

    
}

#Preview {
    ContentView()
        .modelContainer(for: TarotCard.self, inMemory: true)
}
