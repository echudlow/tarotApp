//
//  QuestionInputSheet.swift
//  Tarot
//
//  Created by Elijah Hudlow on 3/19/26.
//

import SwiftUI

struct QuestionInputSheet: View {
    @Binding var questionText: String
    @Environment(\.dismiss) var dismiss
    let onSubmit: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 32) {

                // Handle
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.2))
                        .frame(width: 36, height: 4)
                    Spacer()
                }
                .padding(.top, 16)

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("FIVE CARD SPREAD")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .kerning(4)
                    Text("Ask Your Question")
                        .font(.system(size: 28, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                    Text("Focus your mind, then write your question clearly. The cards will respond to what you truly mean to ask.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineSpacing(4)
                        .padding(.top, 4)
                }

                // Text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR QUESTION")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .kerning(3)

                    ZStack(alignment: .topLeading) {
                        if questionText.isEmpty {
                            Text("What would you like to know?")
                                .font(.system(size: 15, weight: .light, design: .serif))
                                .foregroundStyle(.white.opacity(0.25))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                        }
                        TextEditor(text: $questionText)
                            .font(.system(size: 15, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .background(.clear)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(minHeight: 100)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.12), lineWidth: 0.5)
                            )
                    )
                }

                // Submit button
                Button {
                    let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    dismiss()
                    onSubmit(trimmed)
                } label: {
                    HStack {
                        Spacer()
                        Text("Draw the Cards")
                            .font(.system(size: 15, weight: .light, design: .serif))
                            .foregroundStyle(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.3) : .white)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.04 : 0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
    }
}
