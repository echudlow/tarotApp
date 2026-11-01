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

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.2))
                        .frame(width: 36, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)

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
                        Text("The Read is made for reflection, not prediction. Each reading is written fresh for the cards you draw, using AI, and it’s meant to give you something to think about, not tell you what to do.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineSpacing(4)
                        Text("When you draw, your cards and any question you ask are sent securely to an AI service (Anthropic) to write your reading. Nothing else leaves your phone, and your journal stays on this device.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineSpacing(4)
                        Link("Privacy Policy", destination: URL(string: "https://the-read-proxy.theread-app.workers.dev/privacy")!)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Theme.gold.opacity(0.8))
                        Button("Restore Purchase") {
                            Task { await PurchaseStore.shared.restore() }
                        }
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Theme.gold.opacity(0.8))
                        Text(versionString)
                            .font(.system(size: 10, weight: .light, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingReminder) {
            ReminderSettingsSheet()
                .presentationDetents([.height(480), .large])
        }
    }
}
