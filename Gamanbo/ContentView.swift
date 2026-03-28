//
//  ContentView.swift
//  Gamanbo
//
//  Created by 相川祐輝 on 2026/03/28.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: GamanboStore
    @State private var isPresentingAddSheet = false
    @State private var entryBeingEdited: GamanboEntry?
    @State private var entryPendingDeletion: GamanboEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.95, blue: 0.86),
                        Color(red: 0.88, green: 0.94, blue: 0.92),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heroSection
                        summarySection
                        chartSection
                        monthlySection
                        trophySection
                        recentEntriesSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("がまんぼ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAddSheet = true
                    } label: {
                        Label("我慢を追加", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                AddEntryView(store: store)
            }
            .sheet(item: $entryBeingEdited) { entry in
                AddEntryView(store: store, editingEntry: entry)
            }
            .alert("この記録を削除しますか？", isPresented: deleteAlertIsPresented) {
                Button("キャンセル", role: .cancel) {
                    entryPendingDeletion = nil
                }
                Button("削除", role: .destructive) {
                    guard let entryPendingDeletion else { return }
                    store.deleteEntry(id: entryPendingDeletion.id)
                    self.entryPendingDeletion = nil
                }
            } message: {
                Text(entryPendingDeletion?.title ?? "")
            }
        }
    }

    private var deleteAlertIsPresented: Binding<Bool> {
        Binding(
            get: { entryPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    entryPendingDeletion = nil
                }
            }
        )
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日は何を我慢できた？")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("欲しいものを買わなかった分を積み上げて、節約の手応えを見える化します。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                isPresentingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("我慢した支出を記録する")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.20, green: 0.55, blue: 0.38))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("節約サマリー")
                .font(.title3.weight(.bold))

            HStack(spacing: 12) {
                StatCard(
                    title: "累計がまん額",
                    value: store.totalAmount.currencyText,
                    caption: "\(store.entries.count)件の記録",
                    accent: Color(red: 0.87, green: 0.58, blue: 0.19)
                )

                StatCard(
                    title: "今月のがまん額",
                    value: store.thisMonthTotal.currencyText,
                    caption: "\(store.thisMonthCount)件を記録",
                    accent: Color(red: 0.24, green: 0.48, blue: 0.78)
                )
            }
        }
    }

    private var monthlySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("月ごとの振り返り")
                    .font(.title3.weight(.bold))

                Spacer()

                Text(store.nextMilestoneCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if store.monthlySummaries.isEmpty {
                EmptyCard(text: "記録が増えると、月ごとの節約ペースがここに表示されます。")
            } else {
                VStack(spacing: 12) {
                    ForEach(store.monthlySummaries.prefix(3)) { summary in
                        MonthlySummaryCard(summary: summary, nextMilestoneText: store.nextMilestoneText)
                    }
                }
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("がまんグラフ")
                    .font(.title3.weight(.bold))

                Spacer()

                Text("直近3か月")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if store.monthlySummaries.isEmpty {
                EmptyCard(text: "記録が増えると、月ごとの節約グラフがここに表示されます。")
            } else {
                MonthlyBarChart(summaries: Array(store.monthlySummaries.prefix(3).reversed()))
            }
        }
    }

    private var trophySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("トロフィー")
                .font(.title3.weight(.bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.trophies) { trophy in
                        TrophyCard(trophy: trophy)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("最近のがまん")
                    .font(.title3.weight(.bold))

                Spacer()

                if !store.entries.isEmpty {
                    Text("新しい順")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if store.entries.isEmpty {
                ContentUnavailableView(
                    "まだ記録がありません",
                    systemImage: "tray",
                    description: Text("まずはコンビニのスイーツや衝動買いを我慢した記録から始めてみましょう。")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.88))
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(store.entries) { entry in
                        EntryRow(entry: entry) {
                            entryPendingDeletion = entry
                        } onEdit: {
                            entryBeingEdited = entry
                        }
                    }
                }
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let caption: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 36, height: 36)
                .overlay {
                    Circle()
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                }

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.weight(.bold))
                .minimumScaleFactor(0.8)

            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
    }
}

private struct TrophyCard: View {
    let trophy: Trophy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: trophy.isUnlocked ? "trophy.fill" : "trophy")
                .font(.system(size: 28))
                .foregroundStyle(trophy.isUnlocked ? trophy.color : .secondary)

            Text(trophy.title)
                .font(.headline)

            Text(trophy.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(trophy.threshold.currencyText)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill((trophy.isUnlocked ? trophy.color : .gray).opacity(0.15))
                )
        }
        .frame(width: 160, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(trophy.isUnlocked ? trophy.color.opacity(0.13) : Color.white.opacity(0.85))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(trophy.isUnlocked ? trophy.color.opacity(0.2) : Color.black.opacity(0.05), lineWidth: 1)
        }
    }
}

private struct MonthlySummaryCard: View {
    let summary: MonthlySummary
    let nextMilestoneText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(summary.monthLabel)
                    .font(.headline)

                Spacer()

                Text("\(summary.entryCount)件")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(summary.totalAmount.currencyText)
                .font(.title2.weight(.bold))

            Text("この調子で続けると、次のトロフィーまであと\(nextMilestoneText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
    }
}

private struct EmptyCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.88))
            )
    }
}

private struct MonthlyBarChart: View {
    let summaries: [MonthlySummary]

    private var maxAmount: Double {
        Double(summaries.map(\.totalAmount).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(summaries) { summary in
                    VStack(spacing: 10) {
                        Text(summary.totalAmount.currencyText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        GeometryReader { proxy in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.19, green: 0.61, blue: 0.50),
                                                Color(red: 0.91, green: 0.73, blue: 0.34)
                                            ],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(height: max(18, proxy.size.height * CGFloat(Double(summary.totalAmount) / maxAmount)))
                            }
                        }
                        .frame(height: 140)

                        Text(summary.monthShortLabel)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text("月によってがまん額の波が見えるので、続けやすいペースをつかめます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
    }
}

private struct EntryRow: View {
    let entry: GamanboEntry
    let onDelete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(entry.categoryColor.opacity(0.18))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: entry.categoryIcon)
                        .foregroundStyle(entry.categoryColor)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.headline)

                Text(entry.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(entry.amount.currencyText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color(red: 0.20, green: 0.55, blue: 0.38))

                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("編集", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ContentView(store: GamanboStore.preview)
}
