//
//  Journalroot.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI
import SwiftData

struct JournalRoot: View {
    var goToRead: () -> Void

    @Query private var readings: [Reading]

    var body: some View {
        if readings.isEmpty {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 14) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(Theme.gold.opacity(0.6))
                    Text("Nothing here yet")
                        .font(.system(size: 22, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                    Text("Every reading you do is saved here, so you can come back to it.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 48)
                    Button {
                        Haptics.tap()
                        goToRead()
                    } label: {
                        Text("DO A READING")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .kerning(3)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.white.opacity(0.06))
                                    .overlay(RoundedRectangle(cornerRadius: 6)
                                        .stroke(Theme.gold.opacity(0.3), lineWidth: 0.5))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
            .transition(.opacity)
        } else {
            HistoryView()
        }
    }
}
