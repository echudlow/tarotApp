//
//  Reading.swift
//  Tarot
//
//  Created by Elijah Hudlow on 3/18/26.
//

import Foundation
import SwiftData

@Model
class Reading {
    var id: UUID
    var date: Date
    var spreadType: String
    var cardNames: [String]
    var cardPositions: [String]
    var cardReversals: [Bool]
    var interpretation: String
    var question: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        spreadType: String,
        cardNames: [String],
        cardPositions: [String],
        cardReversals: [Bool],
        interpretation: String,
        question: String? = nil
    ) {
        self.id = id
        self.date = date
        self.spreadType = spreadType
        self.cardNames = cardNames
        self.cardPositions = cardPositions
        self.cardReversals = cardReversals
        self.interpretation = interpretation
        self.question = question
    }
    
    var spreadDisplayName: String {
        switch spreadType {
        case "daily": return "Daily Card"
        case "three_card": return "Three Card Spread"
        case "four_card": return "Four Card Spread"
        case "clarity": return "Clarity Spread"
        case "read_me": return "Read Me"
        default: return spreadType.capitalized
        }
    }
}
