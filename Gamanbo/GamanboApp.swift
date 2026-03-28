//
//  GamanboApp.swift
//  Gamanbo
//
//  Created by 相川祐輝 on 2026/03/28.
//

import SwiftUI

@main
struct GamanboApp: App {
    @StateObject private var store = GamanboStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
