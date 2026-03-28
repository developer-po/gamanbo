//
//  AddEntryView.swift
//  Gamanbo
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: GamanboStore

    @State private var title = ""
    @State private var amountText = ""
    @State private var category: GamanCategory = .food
    @State private var note = ""

    private var amountValue: Int? {
        Int(amountText)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (amountValue ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("何を我慢した？") {
                    TextField("例: コンビニのおにぎり", text: $title)
                    TextField("金額", text: $amountText)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)

                    Picker("カテゴリ", selection: $category) {
                        ForEach(GamanCategory.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                }

                Section("メモ") {
                    TextField("例: 家にあるもので済ませた", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section {
                    Label("長押しで記録を削除できます", systemImage: "hand.tap")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("がまんを記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveEntry()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveEntry() {
        guard let amountValue, canSave else { return }
        store.addEntry(title: title, amount: amountValue, category: category, note: note)
        dismiss()
    }
}

#Preview {
    AddEntryView(store: .preview)
}
