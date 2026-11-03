//
//  Settingssheet.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI

struct SettingsSheet: View {
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var showingReminder = false
    @State private var restoreNote: String? = nil
    @State private var isRestoring = false

    private let privacyURL = URL(string: "https://the-read-proxy.theread-app.workers.dev/privacy")!

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private func restorePurchases() async {
        isRestoring = true
        restoreNote = nil
        let store = PurchaseStore.shared
        await store.restore()
        isRestoring = false
        if store.isUnlocked {
            restoreNote = "RESTORED"
        } else {
            restoreNote = "NOTHING FOUND"
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SETTINGS")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .kerning(4)
                        Text("The Read")
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 0) {
                        Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
                        Button {
                            showingReminder = true
                        } label: {
                            LinkRow(
                                title: "DAILY REMINDER",
                                trailing: reminderEnabled
                                    ? NotificationScheduler.timeString(hour: reminderHour, minute: reminderMinute)
                                    : "OFF"
                            )
                        }
                        .buttonStyle(.plain)
                        Rectangle().fill(.white.opacity(0.08)).frame(height: 1)

                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("ABOUT")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                            .kerning(3)
                        Text("The universe has always found a voice in strange places: smoke, cards, tea leaves. Here, it speaks through an AI. The deck, its imagery, and the meanings behind every card were made by people, over generations. The AI doesn't predict anything. Each reading is written fresh from the cards you draw, to help you put your own thoughts into words. It's for reflection and entertainment, not professional, medical, legal, or financial advice.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineSpacing(4)
                        Text("To write a reading, the cards you draw and any question you ask are sent to Anthropic, the company behind the AI. Your readings are saved only on this device.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineSpacing(4)
                        Link("Privacy Policy", destination: privacyURL)
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Theme.gold.opacity(0.8))
                            .padding(.top, 4)
                        HStack(spacing: 10) {
                            Button {
                                Task { await restorePurchases() }
                            } label: {
                                Text("Restore Purchase")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundStyle(Theme.gold.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .disabled(isRestoring)
                            if isRestoring || restoreNote != nil {
                                Text(isRestoring ? "CHECKING..." : (restoreNote ?? ""))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .kerning(2)
                            }
                        }
                        Text(versionString)
                            .font(.system(size: 10, weight: .light, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }

            TopFade()
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingReminder) {
            ReminderSettingsSheet()
                .presentationDetents([.height(480), .large])
        }
    }
}
