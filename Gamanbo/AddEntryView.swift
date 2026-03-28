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
    let editingEntry: GamanboEntry?

    @State private var title = ""
    @State private var amountText = ""
    @State private var category: GamanCategory = .food
    @State private var note = ""

    init(store: GamanboStore, editingEntry: GamanboEntry? = nil) {
        self.store = store
        self.editingEntry = editingEntry
        _title = State(initialValue: editingEntry?.title ?? "")
        _amountText = State(initialValue: editingEntry.map { String($0.amount) } ?? "")
        _category = State(initialValue: editingEntry?.category ?? .food)
        _note = State(initialValue: editingEntry?.note ?? "")
    }

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
                    Label("記録は長押しで削除、または編集できます", systemImage: "hand.tap")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(editingEntry == nil ? "がまんを記録" : "記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(editingEntry == nil ? "保存" : "更新") {
                        saveEntry()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveEntry() {
        guard let amountValue, canSave else { return }
        if let editingEntry {
            store.updateEntry(
                id: editingEntry.id,
                title: title,
                amount: amountValue,
                category: category,
                note: note
            )
        } else {
            store.addEntry(title: title, amount: amountValue, category: category, note: note)
        }
        dismiss()
    }
}

#Preview {
    AddEntryView(store: .preview)
}
