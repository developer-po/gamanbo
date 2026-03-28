//
//  Trophy.swift
//  Gamanbo
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI

struct Trophy: Identifiable {
    let id: String
    let title: String
    let description: String
    let threshold: Int
    let colorName: TrophyColor
    let isUnlocked: Bool

    var color: Color {
        colorName.value
    }
}

enum TrophyColor {
    case bronze
    case silver
    case gold
    case mint

    var value: Color {
        switch self {
        case .bronze:
            return Color(red: 0.74, green: 0.49, blue: 0.29)
        case .silver:
            return Color(red: 0.54, green: 0.60, blue: 0.66)
        case .gold:
            return Color(red: 0.87, green: 0.68, blue: 0.18)
        case .mint:
            return Color(red: 0.20, green: 0.55, blue: 0.38)
        }
    }
}

extension Trophy {
    static let defaults: [Trophy] = [
        Trophy(id: "first-step", title: "はじめの一歩", description: "1,000円分のがまん", threshold: 1_000, colorName: .bronze, isUnlocked: false),
        Trophy(id: "steady", title: "こつこつ名人", description: "5,000円分のがまん", threshold: 5_000, colorName: .silver, isUnlocked: false),
        Trophy(id: "strong-heart", title: "鋼の意思", description: "10,000円分のがまん", threshold: 10_000, colorName: .gold, isUnlocked: false),
        Trophy(id: "legend", title: "がまんぼ伝説", description: "30,000円分のがまん", threshold: 30_000, colorName: .mint, isUnlocked: false)
    ]
}
