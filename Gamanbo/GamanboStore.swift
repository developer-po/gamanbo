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
        GamanboEntry(title: "コンビニスイーツ", amount: 320, category: .food, note: "夜のつい買いを我慢"),
        GamanboEntry(title: "カフェラテ", amount: 540, category: .cafe, note: "家でコーヒーを淹れた"),
        GamanboEntry(title: "セールのTシャツ", amount: 2_980, category: .shopping, note: "今ある服で着回し"),
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
