//
//  TarotSeed.swift
//  Tarot
//
//  Created by Elijah Hudlow on 3/18/26.
//

import SwiftUI
import SwiftData

extension ContentView {
    func seedTarotDeckIfNeeded() {
        
        let seedVersion = 3
        if UserDefaults.standard.integer(forKey: "tarotSeedVersion") < seedVersion {
            for card in cards { modelContext.delete(card) }
            try? modelContext.save()
        } else {
            guard cards.isEmpty else { return }
        }
        
        let fool = TarotCard(
            name: "The Fool",
            suit: nil,
            number: 0,
            uprightMeaning: "A fresh start taken on trust. Curiosity, openness, and the willingness to leap before every detail is clear.",
            reversedMeaning: "Rushing in without looking, or freezing at the edge. Naivety, poor planning, and risks taken without thought.",
            keywords: ["Innocence", "Beginnings", "Freedom"],
            imageName: "00_the_fool",
            arcana: "Major"
        )
        
        let magician = TarotCard(
            name: "The Magician",
            suit: nil,
            number: 1,
            uprightMeaning: "You have what you need. Focus, skill, and resourcefulness turn an idea into something real.",
            reversedMeaning: "Talent scattered or misused. Manipulation, self-doubt, or plans that never get off the ground.",
            keywords: ["Skill", "Manifestation", "Action"],
            imageName: "01_the_magician",
            arcana: "Major"
        )
        
        let highPriestess = TarotCard(
            name: "The High Priestess",
            suit: nil,
            number: 2,
            uprightMeaning: "Quiet knowing. Intuition, patience, and answers that arrive once you stop forcing them.",
            reversedMeaning: "Ignoring your instincts, or secrets that cloud the picture. Disconnection from your own inner voice.",
            keywords: ["Intuition", "Mystery", "Wisdom"],
            imageName: "02_the_high_priestess",
            arcana: "Major"
        )
        
        let empress = TarotCard(
            name: "The Empress",
            suit: nil,
            number: 3,
            uprightMeaning: "Nurture and abundance. Creativity, comfort, and growth that comes from care and attention.",
            reversedMeaning: "Smothering or neglect, including of yourself. Creative blocks, dependence, and stalled growth.",
            keywords: ["Fertility", "Nurturing", "Abundance"],
            imageName: "03_the_empress",
            arcana: "Major"
        )
        
        let emperor = TarotCard(
            name: "The Emperor",
            suit: nil,
            number: 4,
            uprightMeaning: "Structure and steady leadership. Discipline, boundaries, and building something that lasts.",
            reversedMeaning: "Control taken too far, or too little of it. Rigidity, domination, or a lack of direction.",
            keywords: ["Authority", "Structure", "Leadership"],
            imageName: "04_the_emperor",
            arcana: "Major"
        )
        
        let hierophant = TarotCard(
            name: "The Hierophant",
            suit: nil,
            number: 5,
            uprightMeaning: "Established paths and shared values. Learning from tradition, mentors, and trusted institutions.",
            reversedMeaning: "Questioning the rules. Rebelling against convention, or staying stuck in habits that no longer fit.",
            keywords: ["Tradition", "Spirituality", "Conformity"],
            imageName: "05_the_hierophant",
            arcana: "Major"
        )
        
        let lovers = TarotCard(
            name: "The Lovers",
            suit: nil,
            number: 6,
            uprightMeaning: "A meaningful connection and an honest choice. Alignment between what you value and what you do.",
            reversedMeaning: "Disharmony, mixed signals, or a choice avoided. Values and actions pulling in different directions.",
            keywords: ["Partnership", "Choice", "Union"],
            imageName: "06_the_lovers",
            arcana: "Major"
        )
        
        let chariot = TarotCard(
            name: "The Chariot",
            suit: nil,
            number: 7,
            uprightMeaning: "Determination carries you forward. Discipline and focus bring opposing pulls under a single direction.",
            reversedMeaning: "Lost direction or forced momentum. Scattered effort, aggression, or a push that has outrun its plan.",
            keywords: ["Willpower", "Victory", "Control"],
            imageName: "07_the_chariot",
            arcana: "Major"
        )
        
        let strength = TarotCard(
            name: "Strength",
            suit: nil,
            number: 8,
            uprightMeaning: "Quiet courage. Patience, compassion, and self-command accomplish more than force ever could.",
            reversedMeaning: "Self-doubt and drained confidence. Impulse or harshness where gentleness is needed.",
            keywords: ["Courage", "Inner Strength", "Compassion"],
            imageName: "08_strength",
            arcana: "Major"
        )
        
        let hermit = TarotCard(
            name: "The Hermit",
            suit: nil,
            number: 9,
            uprightMeaning: "Stepping back to find your own answers. Solitude, reflection, and wisdom gathered in stillness.",
            reversedMeaning: "Isolation that has gone too far, or avoiding your own thoughts. Withdrawal without purpose.",
            keywords: ["Solitude", "Reflection", "Wisdom"],
            imageName: "09_the_hermit",
            arcana: "Major"
        )
        
        let wheelOfFortune = TarotCard(
            name: "Wheel of Fortune",
            suit: nil,
            number: 10,
            uprightMeaning: "Things are turning. Cycles, timing, and luck shift, and adapting to the change works in your favor.",
            reversedMeaning: "A setback or a stubborn pattern repeating. Resistance to change, and a sense of things being out of your hands.",
            keywords: ["Cycles", "Fate", "Change"],
            imageName: "10_wheel_of_fortune",
            arcana: "Major"
        )
        
        let justice = TarotCard(
            name: "Justice",
            suit: nil,
            number: 11,
            uprightMeaning: "Fairness and consequence. Honest accounting, clear decisions, and owning your part.",
            reversedMeaning: "Unfairness, dodged accountability, or a skewed view. Dishonesty with others or with yourself.",
            keywords: ["Fairness", "Truth", "Law"],
            imageName: "11_justice",
            arcana: "Major"
        )
        
        let hangedMan = TarotCard(
            name: "The Hanged Man",
            suit: nil,
            number: 12,
            uprightMeaning: "A deliberate pause. Letting go of the old approach opens a new view of the situation.",
            reversedMeaning: "Stalling without learning anything. Needless sacrifice, resistance, and waiting that has outlived its purpose.",
            keywords: ["Surrender", "Perspective", "Pause"],
            imageName: "12_the_hanged_man",
            arcana: "Major"
        )
        
        let death = TarotCard(
            name: "Death",
            suit: nil,
            number: 13,
            uprightMeaning: "An ending that makes room for something new. Transformation, release, and closing a chapter.",
            reversedMeaning: "Holding on past the point. Fear of change, and a transition that drags on.",
            keywords: ["Transformation", "Endings", "Release"],
            imageName: "13_death",
            arcana: "Major"
        )
        
        let temperance = TarotCard(
            name: "Temperance",
            suit: nil,
            number: 14,
            uprightMeaning: "Balance and patience. Blending different parts of your life with moderation and steady care.",
            reversedMeaning: "Excess or imbalance. Impatience, extremes, and parts of life out of proportion.",
            keywords: ["Balance", "Moderation", "Harmony"],
            imageName: "14_temperance",
            arcana: "Major"
        )
        
        let devil = TarotCard(
            name: "The Devil",
            suit: nil,
            number: 15,
            uprightMeaning: "Feeling bound by habit, desire, or fear. A prompt to notice what has a hold on you, and where you hold the key.",
            reversedMeaning: "Loosening a grip. Breaking a pattern, or finally seeing what has been holding you.",
            keywords: ["Bondage", "Temptation", "Shadow"],
            imageName: "15_the_devil",
            arcana: "Major"
        )
        
        let tower = TarotCard(
            name: "The Tower",
            suit: nil,
            number: 16,
            uprightMeaning: "Sudden upheaval. A structure built on shaky ground comes down, and the truth comes into focus.",
            reversedMeaning: "A shake-up avoided or dragged out. Fear of change, or the aftermath of something already fallen.",
            keywords: ["Upheaval", "Shock", "Revelation"],
            imageName: "16_the_tower",
            arcana: "Major"
        )
        
        let star = TarotCard(
            name: "The Star",
            suit: nil,
            number: 17,
            uprightMeaning: "Hope and renewal after hardship. Calm, inspiration, and trust that things can heal.",
            reversedMeaning: "Flagging hope. Discouragement, disconnection, and difficulty believing in better days.",
            keywords: ["Hope", "Renewal", "Guidance"],
            imageName: "17_the_star",
            arcana: "Major"
        )
        
        let moon = TarotCard(
            name: "The Moon",
            suit: nil,
            number: 18,
            uprightMeaning: "Things are not what they seem. Uncertainty, dreams, and intuition, so go gently and trust slowly.",
            reversedMeaning: "Fog lifting. Confusion clearing, or fears and anxieties that can no longer be ignored.",
            keywords: ["Illusion", "Uncertainty", "Subconscious"],
            imageName: "18_the_moon",
            arcana: "Major"
        )
        
        let sun = TarotCard(
            name: "The Sun",
            suit: nil,
            number: 19,
            uprightMeaning: "Warmth, clarity, and joy. Confidence, vitality, and good things coming into the light.",
            reversedMeaning: "Joy dimmed or delayed. Temporary clouds, overconfidence, or difficulty seeing the good.",
            keywords: ["Joy", "Vitality", "Success"],
            imageName: "19_the_sun",
            arcana: "Major"
        )
        
        let judgement = TarotCard(
            name: "Judgement",
            suit: nil,
            number: 20,
            uprightMeaning: "A moment of reckoning and renewal. Honest self-assessment, forgiveness, and answering a calling.",
            reversedMeaning: "Self-doubt and avoidance. Ignoring the call, harsh self-criticism, and refusing to learn from the past.",
            keywords: ["Rebirth", "Awakening", "Accountability"],
            imageName: "20_judgement",
            arcana: "Major"
        )
        
        let world = TarotCard(
            name: "The World",
            suit: nil,
            number: 21,
            uprightMeaning: "Completion and wholeness. A cycle finishes, and you stand ready for what comes next.",
            reversedMeaning: "Almost there. Loose ends, delay, or reluctance to close one chapter and begin another.",
            keywords: ["Completion", "Integration", "Fulfillment"],
            imageName: "21_the_world",
            arcana: "Major"
        )
        
        let pentaclesCards: [TarotCard] = [
            TarotCard(
                name: "King of Pentacles",
                suit: "Pentacles",
                number: nil,
                uprightMeaning: "A grounded, generous provider. Stability, patience, and success built over time.",
                reversedMeaning: "Greed or stubbornness. Possessiveness, indulgence, and security valued above everything else.",
                keywords: [],
                imageName: "king_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Queen of Pentacles",
                suit: "Pentacles",
                number: nil,
                uprightMeaning: "Practical warmth. Someone who makes a home, tends to what matters, and gives without fuss.",
                reversedMeaning: "Overextended or neglecting self-care. Worry about money, smothering, or putting everyone else first.",
                keywords: [],
                imageName: "queen_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Knight of Pentacles",
                suit: "Pentacles",
                number: nil,
                uprightMeaning: "Slow, steady progress. Reliability, hard work, and seeing a task through.",
                reversedMeaning: "Stuck in routine. Stubbornness, boredom, or perfectionism that stalls the work.",
                keywords: [],
                imageName: "knight_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Page of Pentacles",
                suit: "Pentacles",
                number: nil,
                uprightMeaning: "A student of the material world. Curiosity, a new opportunity, and the start of a practical goal.",
                reversedMeaning: "Distraction and procrastination. Plans without follow-through, or a missed chance.",
                keywords: [],
                imageName: "page_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ten of Pentacles",
                suit: "Pentacles",
                number: 10,
                uprightMeaning: "Lasting security. Family, legacy, and comfort built to endure.",
                reversedMeaning: "Instability at the foundation. Family friction, financial strain, or fragile security.",
                keywords: [],
                imageName: "ten_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Nine of Pentacles",
                suit: "Pentacles",
                number: 9,
                uprightMeaning: "Self-made comfort. Independence, enjoying what you have earned, and being at ease alone.",
                reversedMeaning: "Overworking or leaning on appearances. Fragile independence, or comfort that has turned into isolation.",
                keywords: [],
                imageName: "nine_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Eight of Pentacles",
                suit: "Pentacles",
                number: 8,
                uprightMeaning: "Devotion to craft. Practice, focus, and steady improvement through effort.",
                reversedMeaning: "Rushed or joyless work. Perfectionism, burnout, or effort without direction.",
                keywords: [],
                imageName: "eight_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Seven of Pentacles",
                suit: "Pentacles",
                number: 7,
                uprightMeaning: "Pausing to take stock. Patience while effort grows, and asking whether it is worth continuing.",
                reversedMeaning: "Impatience with slow results. Frustration, wasted effort, or worry about returns.",
                keywords: [],
                imageName: "seven_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Six of Pentacles",
                suit: "Pentacles",
                number: 6,
                uprightMeaning: "Generosity and fair exchange. Giving and receiving help, and sharing what you have.",
                reversedMeaning: "Strings attached. Uneven give and take, debt, or generosity that comes with conditions.",
                keywords: [],
                imageName: "six_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Five of Pentacles",
                suit: "Pentacles",
                number: 5,
                uprightMeaning: "Hardship and feeling left out. Money worries, poor health, or a sense of standing outside, with help closer than it looks.",
                reversedMeaning: "Recovery begins. Help is accepted, and things slowly improve after a rough stretch.",
                keywords: [],
                imageName: "five_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Four of Pentacles",
                suit: "Pentacles",
                number: 4,
                uprightMeaning: "Holding tight. Security and caution, or a fear of loss that makes you grip too hard.",
                reversedMeaning: "Loosening your grip. Letting go and spending freely, or tipping into recklessness.",
                keywords: [],
                imageName: "four_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Three of Pentacles",
                suit: "Pentacles",
                number: 3,
                uprightMeaning: "Teamwork and skilled work. Collaboration, recognition, and building something well.",
                reversedMeaning: "Poor teamwork or half-hearted effort. Disagreements, shortcuts, or work going unappreciated.",
                keywords: [],
                imageName: "three_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Two of Pentacles",
                suit: "Pentacles",
                number: 2,
                uprightMeaning: "Juggling priorities. Adapting, staying flexible, and keeping several things in motion.",
                reversedMeaning: "Overwhelm. Too many commitments, dropped balls, and disorganization.",
                keywords: [],
                imageName: "two_of_pentacles",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ace of Pentacles",
                suit: "Pentacles",
                number: 1,
                uprightMeaning: "A promising start in practical matters. A new opportunity in work, money, or health on solid footing.",
                reversedMeaning: "A missed or squandered chance. Poor planning, short-term thinking, and shaky foundations.",
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
                uprightMeaning: "Clear thinking and fair judgement. Honesty, expertise, and decisions made with a level head.",
                reversedMeaning: "Cold or harsh. Misused authority, manipulation, or logic without compassion.",
                keywords: [],
                imageName: "king_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Queen of Swords",
                suit: "Swords",
                number: nil,
                uprightMeaning: "Sharp, honest perception. Independence, clear boundaries, and saying what is true.",
                reversedMeaning: "Bitterness or cutting words. Guarded, judgmental, or hiding behind criticism.",
                keywords: [],
                imageName: "queen_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Knight of Swords",
                suit: "Swords",
                number: nil,
                uprightMeaning: "Bold, fast action. Drive, ambition, and charging at a problem with conviction.",
                reversedMeaning: "Reckless or scattered. Impatience, arguments, and acting or speaking before thinking.",
                keywords: [],
                imageName: "knight_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Page of Swords",
                suit: "Swords",
                number: nil,
                uprightMeaning: "Curiosity and a restless mind. New ideas, questions, and a hunger to learn the truth.",
                reversedMeaning: "Gossip and hasty words. Scattered thoughts, sharp remarks, or ideas not thought through.",
                keywords: [],
                imageName: "page_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ten of Swords",
                suit: "Swords",
                number: 10,
                uprightMeaning: "A painful ending. Rock bottom has been reached, and the only direction left is up.",
                reversedMeaning: "Slow recovery. Lingering pain, or refusing to accept that something is over.",
                keywords: [],
                imageName: "ten_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Nine of Swords",
                suit: "Swords",
                number: 9,
                uprightMeaning: "Anxiety and sleepless worry. Fears loom larger in the dark than they do in daylight.",
                reversedMeaning: "Worry easing. Reaching out for support, or facing what has been weighing on you.",
                keywords: [],
                imageName: "nine_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Eight of Swords",
                suit: "Swords",
                number: 8,
                uprightMeaning: "Feeling trapped. Restrictions that are partly self-imposed, with a way out closer than it seems.",
                reversedMeaning: "Breaking free. Taking back control, seeing options, and stepping out of a limiting mindset.",
                keywords: [],
                imageName: "eight_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Seven of Swords",
                suit: "Swords",
                number: 7,
                uprightMeaning: "Strategy and secrecy. Acting alone, cleverness, or avoiding the direct approach.",
                reversedMeaning: "Coming clean. A secret surfaces, a conscience catches up, or a plan unravels.",
                keywords: [],
                imageName: "seven_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Six of Swords",
                suit: "Swords",
                number: 6,
                uprightMeaning: "Moving on from difficulty. A gradual passage toward calmer waters, carrying only what you need.",
                reversedMeaning: "Stuck in transition. Baggage, resistance to leaving, or a rocky, unfinished journey.",
                keywords: [],
                imageName: "six_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Five of Swords",
                suit: "Swords",
                number: 5,
                uprightMeaning: "A hollow victory. Conflict, winning at someone else's expense, and a cost that outweighs the gain.",
                reversedMeaning: "Making peace. Regret, reconciliation, or choosing to walk away from a pointless fight.",
                keywords: [],
                imageName: "five_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Four of Swords",
                suit: "Swords",
                number: 4,
                uprightMeaning: "Rest and recovery. A pause to recharge the mind and body before moving on.",
                reversedMeaning: "Restlessness or burnout. Pushing on without rest, or finally returning to the world.",
                keywords: [],
                imageName: "four_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Three of Swords",
                suit: "Swords",
                number: 3,
                uprightMeaning: "Heartbreak. Grief and hard truths that hurt and also clear the air.",
                reversedMeaning: "Healing slowly. Releasing pain, forgiveness, or holding hurt longer than it serves.",
                keywords: [],
                imageName: "three_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Two of Swords",
                suit: "Swords",
                number: 2,
                uprightMeaning: "A stalemate. A hard decision put off, and the strain of keeping your guard up.",
                reversedMeaning: "The choice can no longer be avoided. Indecision breaks, or new information tips the balance.",
                keywords: [],
                imageName: "two_of_swords",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ace of Swords",
                suit: "Swords",
                number: 1,
                uprightMeaning: "A breakthrough of clarity. A sharp idea, an honest truth, and a decisive new start.",
                reversedMeaning: "Confusion and clouded judgement. Harsh words, muddled thinking, or a truth you resist.",
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
                uprightMeaning: "A natural leader with vision. Charisma, boldness, and the ability to inspire others.",
                reversedMeaning: "Domineering or impulsive. Ego, impatience, and big plans with little follow-through.",
                keywords: [],
                imageName: "king_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Queen of Wands",
                suit: "Wands",
                number: nil,
                uprightMeaning: "Confident warmth. Magnetic, determined, and unafraid to be seen.",
                reversedMeaning: "Jealousy or insecurity. Demanding, withdrawn, or a temper that flares when confidence slips.",
                keywords: [],
                imageName: "queen_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Knight of Wands",
                suit: "Wands",
                number: nil,
                uprightMeaning: "Adventure and momentum. Passion, energy, and chasing what excites you.",
                reversedMeaning: "Hot-headed and scattered. Restlessness, delays, or burning out from rushing.",
                keywords: [],
                imageName: "knight_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Page of Wands",
                suit: "Wands",
                number: nil,
                uprightMeaning: "A spark of inspiration. Enthusiasm, curiosity, and eagerness to try something new.",
                reversedMeaning: "Ideas without action. Lack of direction, setbacks, or enthusiasm that fizzles.",
                keywords: [],
                imageName: "page_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ten of Wands",
                suit: "Wands",
                number: 10,
                uprightMeaning: "A heavy load. Responsibility and effort stacked high, close to the finish.",
                reversedMeaning: "Putting the burden down. Delegating, or collapsing under too much.",
                keywords: [],
                imageName: "ten_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Nine of Wands",
                suit: "Wands",
                number: 9,
                uprightMeaning: "Bruised but standing. Resilience, one last push, and guarding what you have built.",
                reversedMeaning: "Exhaustion and defensiveness. Giving up near the end, or fighting battles that are already over.",
                keywords: [],
                imageName: "nine_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Eight of Wands",
                suit: "Wands",
                number: 8,
                uprightMeaning: "Rapid movement. Messages, travel, and things falling into place quickly.",
                reversedMeaning: "Delays and crossed wires. Frustration, slowed momentum, or rushing too fast.",
                keywords: [],
                imageName: "eight_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Seven of Wands",
                suit: "Wands",
                number: 7,
                uprightMeaning: "Standing your ground. Defending your position with confidence, even when it is hard.",
                reversedMeaning: "Overwhelmed and giving way. Fatigue, doubt, or backing down too soon.",
                keywords: [],
                imageName: "seven_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Six of Wands",
                suit: "Wands",
                number: 6,
                uprightMeaning: "Recognition and earned success. Confidence, praise, and progress made visible.",
                reversedMeaning: "A fall from favor or a hollow win. Ego, self-doubt, or credit that goes elsewhere.",
                keywords: [],
                imageName: "six_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Five of Wands",
                suit: "Wands",
                number: 5,
                uprightMeaning: "Friction and competition. Clashing ideas, healthy rivalry, or noisy disagreement.",
                reversedMeaning: "Conflict settling, or avoided. Tension eases, or hostility goes underground.",
                keywords: [],
                imageName: "five_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Four of Wands",
                suit: "Wands",
                number: 4,
                uprightMeaning: "Celebration and homecoming. Stability, milestones, and the joy of a shared achievement.",
                reversedMeaning: "Unease at home or in a gathering. Instability, delay, or a celebration that feels hollow.",
                keywords: [],
                imageName: "four_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Three of Wands",
                suit: "Wands",
                number: 3,
                uprightMeaning: "Looking ahead. Plans in motion, expansion, and waiting on the results of your efforts.",
                reversedMeaning: "Delays and setbacks. Poor planning, blocked progress, or lack of foresight.",
                keywords: [],
                imageName: "three_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Two of Wands",
                suit: "Wands",
                number: 2,
                uprightMeaning: "Planning your next step. Deciding between staying put and venturing out, with the world before you.",
                reversedMeaning: "Fear of the unknown. Playing it safe, or indecision about the way forward.",
                keywords: [],
                imageName: "two_of_wands",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ace of Wands",
                suit: "Wands",
                number: 1,
                uprightMeaning: "A surge of inspiration. New energy, creative spark, and the courage to begin.",
                reversedMeaning: "Stalled energy. Delays, lack of motivation, or a spark that will not catch.",
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
                uprightMeaning: "Emotional maturity. Calm, compassionate, and steady, able to feel deeply without being swept away.",
                reversedMeaning: "Mood swings and suppressed feelings. Manipulation, or emotional distance.",
                keywords: [],
                imageName: "king_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Queen of Cups",
                suit: "Cups",
                number: nil,
                uprightMeaning: "Empathy and intuition. Tender, perceptive, and attuned to what others feel.",
                reversedMeaning: "Overwhelmed by emotion. Insecurity, dependence, or giving more than you have.",
                keywords: [],
                imageName: "queen_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Knight of Cups",
                suit: "Cups",
                number: nil,
                uprightMeaning: "A romantic invitation. Charm, creativity, and following the heart.",
                reversedMeaning: "Moodiness and unrealistic promises. Daydreams over action, or charm without substance.",
                keywords: [],
                imageName: "knight_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Page of Cups",
                suit: "Cups",
                number: nil,
                uprightMeaning: "A tender, creative message. Sensitivity, a spark of imagination, and openness to feeling.",
                reversedMeaning: "Emotional immaturity. Creative blocks, oversensitivity, or mixed feelings.",
                keywords: [],
                imageName: "page_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ten of Cups",
                suit: "Cups",
                number: 10,
                uprightMeaning: "Emotional fulfillment. Close bonds, a happy home, and love that is shared.",
                reversedMeaning: "Strained harmony. Family tension, misaligned values, or an ideal that falls short.",
                keywords: [],
                imageName: "ten_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Nine of Cups",
                suit: "Cups",
                number: 9,
                uprightMeaning: "A wish granted. Satisfaction, enjoying your good fortune, and contentment.",
                reversedMeaning: "Smugness or an empty win. Overindulgence, or getting what you wanted and finding it lacking.",
                keywords: [],
                imageName: "nine_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Eight of Cups",
                suit: "Cups",
                number: 8,
                uprightMeaning: "Walking away. Leaving something that no longer fills you, in search of more meaning.",
                reversedMeaning: "Staying or drifting. Fear of leaving, going back, or avoiding the real issue.",
                keywords: [],
                imageName: "eight_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Seven of Cups",
                suit: "Cups",
                number: 7,
                uprightMeaning: "Many options and many daydreams. Imagination and temptation, and the need to sort what is real.",
                reversedMeaning: "Clarity at last. Choosing a direction, or illusions fading.",
                keywords: [],
                imageName: "seven_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Six of Cups",
                suit: "Cups",
                number: 6,
                uprightMeaning: "Nostalgia and kindness. Old friends, happy memories, and simple generosity.",
                reversedMeaning: "Stuck in the past. Idealizing yesterday, or needing to move on from old patterns.",
                keywords: [],
                imageName: "six_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Five of Cups",
                suit: "Cups",
                number: 5,
                uprightMeaning: "Grief and regret. Focusing on what is lost while something remains standing nearby.",
                reversedMeaning: "Moving on. Acceptance, forgiveness, and turning toward what is left.",
                keywords: [],
                imageName: "five_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Four of Cups",
                suit: "Cups",
                number: 4,
                uprightMeaning: "Apathy and reflection. Turning away from what is offered, or needing time to work out what you want.",
                reversedMeaning: "Re-engagement. Noticing opportunities again, or coming out of a slump.",
                keywords: [],
                imageName: "four_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Three of Cups",
                suit: "Cups",
                number: 3,
                uprightMeaning: "Celebration and friendship. Community, shared joy, and good company.",
                reversedMeaning: "Overindulgence or social friction. Gossip, cliques, or isolation from the group.",
                keywords: [],
                imageName: "three_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Two of Cups",
                suit: "Cups",
                number: 2,
                uprightMeaning: "Mutual connection. Partnership, attraction, and a balanced give and take.",
                reversedMeaning: "Imbalance in a relationship. Miscommunication, drifting apart, or one-sided effort.",
                keywords: [],
                imageName: "two_of_cups",
                arcana: "Minor"
            ),
            TarotCard(
                name: "Ace of Cups",
                suit: "Cups",
                number: 1,
                uprightMeaning: "A new wave of feeling. Love, compassion, and creative inspiration beginning to flow.",
                reversedMeaning: "Feelings held back. Emotional blockage, disappointment, or an offer of love not received.",
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
        
        UserDefaults.standard.set(seedVersion, forKey: "tarotSeedVersion")
    }
        
}
