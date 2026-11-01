//
//  ReminderSettingsSheet.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI
import UIKit
import UserNotifications

struct ReminderSettingsSheet: View {
    @AppStorage("reminderEnabled") private var enabled = true
    @AppStorage("reminderHour") private var hour = 8
    @AppStorage("reminderMinute") private var minute = 0
    @State private var status: UNAuthorizationStatus = .notDetermined

    private let gold = Color(red: 0.94, green: 0.90, blue: 0.78)

    private var denied: Bool { status == .denied }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour = components.hour ?? 8
                minute = components.minute ?? 0
                NotificationScheduler.refresh()
            }
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.2))
                        .frame(width: 36, height: 4)
                    Spacer()
                }
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 6) {
                    Text("DAILY REMINDER")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .kerning(4)
                    Text("When should the cards find you?")
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                }

                if denied {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notifications are off for The Read.")
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                        Text("Turn them on in Settings to get your daily card.")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("OPEN SETTINGS")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.8))
                                .kerning(3)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(gold.opacity(0.25), lineWidth: 0.5))
                    )
                }

                Toggle(isOn: $enabled) {
                    Text("Remind me each day")
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                }
                .tint(gold)
                .disabled(denied)

                DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.colorScheme, .dark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .opacity(enabled && !denied ? 1 : 0.35)
                    .disabled(!enabled || denied)

                Text(enabled && !denied
                     ? "Your daily card will arrive at \(NotificationScheduler.timeString(hour: hour, minute: minute))."
                     : "No reminder will be sent.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
        .task { await refreshStatus() }
        .onChange(of: enabled) { _, isOn in
            Task {
                if isOn {
                    _ = try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge])
                    await refreshStatus()
                }
                NotificationScheduler.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await refreshStatus()
                NotificationScheduler.refresh()
            }
        }
    }

    private func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        status = settings.authorizationStatus
    }
}
