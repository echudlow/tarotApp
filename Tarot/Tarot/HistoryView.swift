//
//  HisotryView.swift
//  Tarot
//
//  Created by Elijah Hudlow on 3/18/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]
    @Query private var cards: [TarotCard]
    @State private var selectedReading: Reading? = nil
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAllAlert = false
    @State private var isSelecting = false
    @State private var selectedReadings: Set<UUID> = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // One list that scrolls on its own, so it ends exactly at the oldest reading
            List {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("HISTORY")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .kerning(4)
                    Text("Past Readings")
                        .font(.system(size: 28, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 14, trailing: 20))

                if readings.isEmpty {
                    VStack(spacing: 12) {
                        Text("✦")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("No readings yet")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(readings) { reading in
                    HStack(spacing: 12) {
                        if isSelecting {
                            Image(systemName: selectedReadings.contains(reading.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedReadings.contains(reading.id) ? .white : .white.opacity(0.3))
                                .animation(.easeInOut(duration: 0.15), value: selectedReadings.contains(reading.id))
                        }
                        ReadingHistoryRow(reading: reading, cards: cards)
                            .onTapGesture {
                                if isSelecting {
                                    if selectedReadings.contains(reading.id) {
                                        selectedReadings.remove(reading.id)
                                    } else {
                                        selectedReadings.insert(reading.id)
                                    }
                                } else {
                                    selectedReading = reading
                                }
                            }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !isSelecting {
                            Button(role: .destructive) {
                                if let index = readings.firstIndex(where: { $0.id == reading.id }) {
                                    deleteReadings(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 40, bottom: 6, trailing: 40))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, 24, for: .scrollContent)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !readings.isEmpty {
                    HStack {
                        if isSelecting {
                            Button("Delete (\(selectedReadings.count))") {
                                showingDeleteAllAlert = true
                            }
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(selectedReadings.isEmpty ? .white.opacity(0.2) : .red.opacity(0.7))
                            .disabled(selectedReadings.isEmpty)
                            
                            Button("Done") {
                                isSelecting = false
                                selectedReadings.removeAll()
                            }
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                        } else {
                            Button("Select") {
                                isSelecting = true
                            }
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                            
                            Button("Clear All") {
                                showingDeleteAllAlert = true
                            }
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
            }
        }
        // Pushed instead of a sheet: a back button always in view, and swipe from the left edge works
        .navigationDestination(item: $selectedReading) { reading in
            ReadingDetailSheet(reading: reading, cards: cards)
        }
        .alert(isSelecting ? "Delete Selected Readings?" : "Clear All Readings?", isPresented: $showingDeleteAllAlert) {
            Button("Delete", role: .destructive) {
                if isSelecting {
                    deleteSelectedReadings()
                } else {
                    deleteAllReadings()
                }
                isSelecting = false
                selectedReadings.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(isSelecting
                 ? "This will permanently delete \(selectedReadings.count) reading\(selectedReadings.count == 1 ? "" : "s")."
                 : "This will permanently delete all your past readings and cannot be undone.")
        }
    }
    private func deleteReadings(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(readings[index])
        }
        try? modelContext.save()
    }
    
    private func deleteAllReadings() {
        for reading in readings {
            modelContext.delete(reading)
        }
        try? modelContext.save()
    }
    
    private func deleteSelectedReadings() {
        for reading in readings where selectedReadings.contains(reading.id) {
            modelContext.delete(reading)
        }
        try? modelContext.save()
    }
    
}

// MARK: - History Row
struct ReadingHistoryRow: View {
    let reading: Reading
    let cards: [TarotCard]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: reading.date)
    }

    var previewText: String {
        let lines = reading.interpretation
            .replacingOccurrences(of: "**", with: "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.drop(while: { $0.hasSuffix(":") }).joined(separator: " ")
    }
    
    static let singleRowLimit = 5

    @ViewBuilder
    private func thumbnail(index: Int, name: String) -> some View {
        let card = cards.first(where: { $0.name == name })
        let isReversed = reading.cardReversals.indices.contains(index) ? reading.cardReversals[index] : false
        if let imageName = card?.imageName {
            Image(imageName)
                .resizable()
                .aspectRatio(2/3, contentMode: .fit)
                .cornerRadius(4)
                .rotationEffect(isReversed ? .degrees(180) : .degrees(0))
                .opacity(0.85)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reading.spreadDisplayName.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .kerning(2)
                    Text(formattedDate)
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.2))
            }

            // Card thumbnails: up to 5 sit in one row, bigger spreads wrap into a small grid
            if reading.cardNames.count <= ReadingHistoryRow.singleRowLimit {
                HStack(spacing: 8) {
                    ForEach(Array(reading.cardNames.enumerated()), id: \.offset) { index, name in
                        thumbnail(index: index, name: name)
                            .frame(width: 44)
                    }
                    Spacer()
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 36, maximum: 44), spacing: 6)],
                          alignment: .leading, spacing: 6) {
                    ForEach(Array(reading.cardNames.enumerated()), id: \.offset) { index, name in
                        thumbnail(index: index, name: name)
                    }
                }
            }

            // Interpretation preview
            Text(previewText)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
                .lineLimit(2)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Reading Detail Sheet
struct ReadingDetailSheet: View {
    let reading: Reading
    let cards: [TarotCard]
    @State private var selectedCard: TarotCard? = nil

    // Rebuild the drawn spread from what was saved
    private var drawnCards: [DrawnCard] {
        reading.cardNames.enumerated().compactMap { index, name in
            guard let card = cards.first(where: { $0.name == name }) else { return nil }
            let position = reading.cardPositions.indices.contains(index) ? reading.cardPositions[index] : ""
            let reversed = reading.cardReversals.indices.contains(index) ? reading.cardReversals[index] : false
            return DrawnCard(card: card, isReversed: reversed, position: position)
        }
    }

    private var sections: [InterpretationSection] {
        parseInterpretationSections(reading.interpretation)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    ShareCardView(
                        spreadName: reading.spreadDisplayName,
                        spreadType: reading.spreadType,
                        cards: drawnCards,
                        question: reading.question,
                        closingHeader: "Interpretation",
                        closingText: reading.interpretation.replacingOccurrences(of: "**", with: ""),
                        date: reading.date,
                        sections: sections,
                        fillWidth: true,
                        showFooter: false,
                        onCardTap: { drawn in
                            Haptics.tap()
                            selectedCard = drawn.card
                        }
                    )

                    Spacer(minLength: 40)
                }
            }

            // Text melts into black under the back button instead of ending on a hard line
            TopFade()
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)   // the fade below replaces the hard bar
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $selectedCard) { card in
            CardDetailSheet(card: card)
        }
    }
}
