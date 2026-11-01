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
                        Text("The Read is for reflection and entertainment. Readings are written by an AI from the cards you draw, and are not professional, medical, legal, or financial advice.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineSpacing(4)
                        Text("To write a reading, the cards you draw and any question you ask are sent to Anthropic. Your readings are saved only on this device.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineSpacing(4)
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
