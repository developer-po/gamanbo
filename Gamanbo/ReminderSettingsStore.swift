//
//  ReminderSettingsStore.swift
//  Gamanbo
//
//  Created by Codex on 2026/03/28.
//

import Combine
import Foundation
import UserNotifications

@MainActor
final class ReminderSettingsStore: ObservableObject {
    @Published var isEnabled = false
    @Published var reminderTime: Date
    @Published var alertMessage: ReminderAlert?

    private let center = UNUserNotificationCenter.current()
    private let enabledKey = "gamanbo.reminder.enabled"
    private let hourKey = "gamanbo.reminder.hour"
    private let minuteKey = "gamanbo.reminder.minute"
    private let notificationIdentifier = "gamanbo.daily.reminder"

    init() {
        let defaults = UserDefaults.standard
        let hour = defaults.object(forKey: hourKey) as? Int ?? 20
        let minute = defaults.object(forKey: minuteKey) as? Int ?? 0

        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        reminderTime = Calendar.current.date(from: components) ?? .now
        isEnabled = defaults.bool(forKey: enabledKey)
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            requestAndSchedule()
        } else {
            isEnabled = false
            persist()
            center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        }
    }

    func updateReminderTime(_ date: Date) {
        reminderTime = date
        persist()

        if isEnabled {
            scheduleReminder()
        }
    }

    private func requestAndSchedule() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in
                if let error {
                    self.isEnabled = false
                    self.alertMessage = ReminderAlert(message: "通知の設定に失敗しました: \(error.localizedDescription)")
                    self.persist()
                    return
                }

                guard granted else {
                    self.isEnabled = false
                    self.alertMessage = ReminderAlert(message: "通知が許可されていません。iPhoneの設定アプリから通知を許可すると使えます。")
                    self.persist()
                    return
                }

                self.isEnabled = true
                self.persist()
                self.scheduleReminder()
            }
        }
    }

    private func scheduleReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "がまんぼ"
        content.body = "今日は何を我慢できましたか？ 小さな節約も記録してみましょう。"
        content.sound = .default

        let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

        center.add(request) { error in
            Task { @MainActor in
                if let error {
                    self.isEnabled = false
                    self.alertMessage = ReminderAlert(message: "通知の登録に失敗しました: \(error.localizedDescription)")
                    self.persist()
                }
            }
        }
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(isEnabled, forKey: enabledKey)
        defaults.set(Calendar.current.component(.hour, from: reminderTime), forKey: hourKey)
        defaults.set(Calendar.current.component(.minute, from: reminderTime), forKey: minuteKey)
    }
}

struct ReminderAlert: Identifiable {
    let id = UUID()
    let message: String
}
