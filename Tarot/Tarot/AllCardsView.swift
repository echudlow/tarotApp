//
//  AllCardsView.swift
//  Tarot
//
//  Created by Elijah Hudlow on 12/12/25.
//
import SwiftUI
import SwiftData
import Foundation
struct AllCardsView: View {
    @Query(sort: \TarotCard.name) private var cards: [TarotCard]

    var body: some View {
        List {
            ForEach(cards) { card in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(card.name)\(card.number != nil ? " - \(card.number!)" : "")")
                        .font(.headline)

                    if let arcana = card.arcana {
                        if let suit = card.suit {
                            Text("\(arcana) - \(suit)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(arcana)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let imageName = card.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(8)
                    }

                    Text("Upright: \(card.uprightMeaning)")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("Reversed: \(card.reversedMeaning)")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("All Cards")
    }
}

#Preview("All Cards") {
    AllCardsView()
        .modelContainer(for: TarotCard.self, inMemory: true)
}
