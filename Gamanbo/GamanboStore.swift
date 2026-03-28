//
//  GamanboStore.swift
//  Gamanbo
//
//  Created by Codex on 2026/03/28.
//

import Combine
import Foundation

final class GamanboStore: ObservableObject {
    @Published private(set) var entries: [GamanboEntry] = [] {
        didSet { saveEntries() }
    }

    private let userDefaultsKey = "gamanbo.entries"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(useSampleData: Bool = false) {
        if useSampleData {
            entries = Self.sampleEntries
        } else {
            loadEntries()
        }
    }

    var totalAmount: Int {
        entries.reduce(0) { $0 + $1.amount }
    }

    var thisMonthTotal: Int {
        entriesForCurrentMonth.reduce(0) { $0 + $1.amount }
    }

    var thisMonthCount: Int {
        entriesForCurrentMonth.count
    }

    var activeDaysCount: Int {
        uniqueEntryDays.count
    }

    var currentStreak: Int {
        guard !uniqueEntryDays.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        guard uniqueEntryDays.contains(today) || uniqueEntryDays.contains(yesterday) else {
            return 0
        }

        var streak = 0
        var cursor = uniqueEntryDays.contains(today) ? today : yesterday

        while uniqueEntryDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previousDay
        }

        return streak
    }

    var bestStreak: Int {
        let sortedDays = uniqueEntryDays.sorted(by: >)
        guard !sortedDays.isEmpty else { return 0 }

        let calendar = Calendar.current
        var best = 1
        var current = 1

        for index in 1..<sortedDays.count {
            let previous = sortedDays[index - 1]
            let currentDay = sortedDays[index]
            let diff = calendar.dateComponents([.day], from: currentDay, to: previous).day ?? 0

            if diff == 1 {
                current += 1
                best = max(best, current)
            } else if diff > 1 {
                current = 1
            }
        }

        return best
    }

    var monthlySummaries: [MonthlySummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            let components = calendar.dateComponents([.year, .month], from: entry.date)
            return calendar.date(from: components) ?? entry.date
        }

        return grouped.map { monthStart, monthEntries in
            MonthlySummary(
                monthStart: monthStart,
                totalAmount: monthEntries.reduce(0) { $0 + $1.amount },
                entryCount: monthEntries.count
            )
        }
        .sorted { $0.monthStart > $1.monthStart }
    }

    func entries(for monthStart: Date?) -> [GamanboEntry] {
        guard let monthStart else { return entries }
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
    }

    func categorySummaries(for monthStart: Date?) -> [CategorySummary] {
        let filteredEntries = entries(for: monthStart)
        let grouped = Dictionary(grouping: filteredEntries, by: \.category)

        return grouped.map { category, entries in
            CategorySummary(
                category: category,
                totalAmount: entries.reduce(0) { $0 + $1.amount },
                entryCount: entries.count
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalAmount == rhs.totalAmount {
                return lhs.category.rawValue < rhs.category.rawValue
            }
            return lhs.totalAmount > rhs.totalAmount
        }
    }

    func csvText(for monthStart: Date?) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM-dd"

        let rows = entries(for: monthStart).map { entry in
            [
                formatter.string(from: entry.date),
                escapeCSV(entry.title),
                escapeCSV(entry.category.rawValue),
                "\(entry.amount)",
                escapeCSV(entry.note)
            ].joined(separator: ",")
        }

        let header = "date,title,category,amount,note"
        return ([header] + rows).joined(separator: "\n")
    }

    private func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    var trophies: [Trophy] {
        Trophy.defaults.map { trophy in
            Trophy(
                id: trophy.id,
                title: trophy.title,
                description: trophy.description,
                threshold: trophy.threshold,
                colorName: trophy.colorName,
                isUnlocked: totalAmount >= trophy.threshold
            )
        }
    }

    var nextTrophy: Trophy? {
        trophies.first(where: { !$0.isUnlocked })
    }

    var nextTrophyProgress: Double {
        guard let nextTrophy else { return 1 }

        let previousThreshold = Trophy.defaults
            .filter { $0.threshold < nextTrophy.threshold }
            .map(\.threshold)
            .max() ?? 0

        let required = nextTrophy.threshold - previousThreshold
        guard required > 0 else { return 1 }

        return min(1, max(0, Double(totalAmount - previousThreshold) / Double(required)))
    }

    var nextMilestoneText: String {
        guard let next = Trophy.defaults.first(where: { totalAmount < $0.threshold }) else {
            return "達成済み"
        }
        return (next.threshold - totalAmount).currencyText
    }

    var nextMilestoneCaption: String {
        guard let next = Trophy.defaults.first(where: { totalAmount < $0.threshold }) else {
            return "すべてのトロフィーを獲得しました"
        }
        return "\(next.title)まであと少し"
    }

    func addEntry(title: String, amount: Int, category: GamanCategory, note: String) {
        let newEntry = GamanboEntry(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        entries.insert(newEntry, at: 0)
    }

    func updateEntry(id: UUID, title: String, amount: Int, category: GamanCategory, note: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }

        let existing = entries[index]
        entries[index] = GamanboEntry(
            id: existing.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: existing.date
        )
        entries.sort { $0.date > $1.date }
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
    }

    private var uniqueEntryDays: Set<Date> {
        let calendar = Calendar.current
        return Set(entries.map { calendar.startOfDay(for: $0.date) })
    }

    private var entriesForCurrentMonth: [GamanboEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    private func loadEntries() {
        guard
            let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let decoded = try? decoder.decode([GamanboEntry].self, from: data)
        else {
            entries = []
            return
        }

        entries = decoded.sorted { $0.date > $1.date }
    }

    private func saveEntries() {
        guard let data = try? encoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}

extension GamanboStore {
    static let preview = GamanboStore(useSampleData: true)

    static let sampleEntries: [GamanboEntry] = [
        GamanboEntry(
            title: "コンビニスイーツ",
            amount: 320,
            category: .food,
            note: "夜のつい買いを我慢",
            date: .now
        ),
        GamanboEntry(
            title: "カフェラテ",
            amount: 540,
            category: .cafe,
            note: "家でコーヒーを淹れた",
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        ),
        GamanboEntry(
            title: "セールのTシャツ",
            amount: 2_980,
            category: .shopping,
            note: "今ある服で着回し",
            date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        ),
        GamanboEntry(
            title: "終電回避のタクシー",
            amount: 1_800,
            category: .transport,
            note: "一本早く帰宅",
            date: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
        )
    ]
}

struct MonthlySummary: Identifiable {
    let monthStart: Date
    let totalAmount: Int
    let entryCount: Int

    var id: Date { monthStart }

    var monthLabel: String {
        monthStart.formatted(.dateTime.year().month(.wide))
    }

    var monthShortLabel: String {
        monthStart.formatted(.dateTime.month(.abbreviated))
    }
}

struct CategorySummary: Identifiable {
    let category: GamanCategory
    let totalAmount: Int
    let entryCount: Int

    var id: GamanCategory { category }
}
