//  TarotCard.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/11/25.
//

import Foundation
import SwiftData

@Model
class TarotCard {
    @Attribute(.unique) var id: UUID
    var name: String
    var suit: String?
    var number: Int?
    var uprightMeaning: String
    var reversedMeaning: String
    var keywords: [String]
    var imageName: String?
    var arcana: String? 

    init(
        id: UUID = UUID(),
        name: String = "",
        suit: String? = nil,
        number: Int? = nil,
        uprightMeaning: String = "",
        reversedMeaning: String = "",
        keywords: [String] = [],
        imageName: String? = nil,
        arcana: String? = nil
    ) {
        self.id = id
        self.name = name
        self.suit = suit
        self.number = number
        self.uprightMeaning = uprightMeaning
        self.reversedMeaning = reversedMeaning
        self.keywords = keywords
        self.imageName = imageName
        self.arcana = arcana
    }
}

