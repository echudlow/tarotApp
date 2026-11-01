//
//  PaywallView.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    private var store: PurchaseStore { PurchaseStore.shared }

    private var price: String { store.product?.displayPrice ?? "$4.99" }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.2))
                        .frame(width: 36, height: 4)
                        .padding(.top, 12)

                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .ultraLight))
                        .foregroundStyle(Theme.gold.opacity(0.7))
                        .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text("UNLOCK THE READ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .kerning(4)
                        Text("Every spread, yours to keep")
                            .font(.system(size: 26, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        bullet("All six spreads, including Ask and Read Me")
                        bullet("Up to 5 spread readings a day")
                        bullet("One payment. No subscription, no ads")
                        bullet("Your daily card stays free, always")
                    }
                    .padding(.horizontal, 12)

                    if FreeSampleStore.remaining == 0 {
                        Text("You have used your 3 free sample spreads.")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    if let error = store.errorMessage {
                        Text(error)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Haptics.tap()
                        Task {
                            if await store.purchase() {
                                Haptics.success()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if store.isWorking {
                                ProgressView().tint(.white)
                            } else {
                                Text("UNLOCK FOR \(price)")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .kerning(2)
                            }
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.gold.opacity(0.4), lineWidth: 0.5))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isWorking)

                    Button {
                        Task {
                            await store.restore()
                            if store.isUnlocked { dismiss() }
                        }
                    } label: {
                        Text("RESTORE PURCHASE")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                            .kerning(3)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isWorking)

                    Button("Not now") { dismiss() }
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                        .buttonStyle(.plain)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Theme.gold.opacity(0.8))
                .padding(.top, 3)
            Text(text)
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(.white.opacity(0.75))
        }
    }
}
