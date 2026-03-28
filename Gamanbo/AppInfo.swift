//
//  AppInfo.swift
//  Gamanbo
//
//  Created by Codex on 2026/03/28.
//

import Foundation

enum AppInfo {
    static var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "がまんぼ"
    }

    static var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    static let supportMessage = "小さな我慢でも、続けるとしっかり積み上がります。迷ったら食べ物やカフェ代から始めるのがおすすめです。"
}
