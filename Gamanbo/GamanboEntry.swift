//
//  GamanboEntry.swift
//  Gamanbo
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI

struct GamanboEntry: Identifiable, Codable {
    let id: UUID
    let title: String
    let amount: Int
    let category: GamanCategory
    let note: String
    let date: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Int,
        category: GamanCategory,
        note: String = "",
        date: Date = .now
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
    }

    var categoryIcon: String {
        category.symbol
    }

    var categoryColor: Color {
        category.color
    }
}

enum GamanCategory: String, CaseIterable, Codable, Identifiable {
    case food = "食べ物"
    case cafe = "カフェ"
    case hobby = "趣味"
    case shopping = "買い物"
    case transport = "移動"
    case other = "その他"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .food:
            return "fork.knife"
        case .cafe:
            return "cup.and.saucer.fill"
        case .hobby:
            return "gamecontroller.fill"
        case .shopping:
            return "bag.fill"
        case .transport:
            return "tram.fill"
        case .other:
            return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .food:
            return Color(red: 0.89, green: 0.43, blue: 0.27)
        case .cafe:
            return Color(red: 0.56, green: 0.36, blue: 0.23)
        case .hobby:
            return Color(red: 0.45, green: 0.31, blue: 0.73)
        case .shopping:
            return Color(red: 0.18, green: 0.56, blue: 0.56)
        case .transport:
            return Color(red: 0.24, green: 0.48, blue: 0.78)
        case .other:
            return Color(red: 0.46, green: 0.47, blue: 0.50)
        }
    }
}

extension Int {
    var currencyText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "¥0"
    }
}
