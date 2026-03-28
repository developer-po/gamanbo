//
//  ContentView.swift
//  Gamanbo
//
//  Created by 相川祐輝 on 2026/03/28.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: GamanboStore
    @AppStorage("gamanbo.dismissedTips") private var dismissedTips = false
    @StateObject private var reminderStore = ReminderSettingsStore()
    @State private var isShowingAbout = false
    @State private var isExportingCSV = false
    @State private var isPresentingAddSheet = false
    @State private var searchText = ""
    @State private var selectedMonthStart: Date?
    @State private var entryBeingEdited: GamanboEntry?
    @State private var entryPendingDeletion: GamanboEntry?
    @State private var previousUnlockedTrophyCount = 0
    @State private var celebratedTrophy: Trophy?

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
                        tipsSection
                        streakSection
                        reminderSection
                        summarySection
                        chartSection
                        categorySection
                        monthlySection
                        trophySection
                        recentEntriesSection
                    }
                    .padding(20)
                }
            }
            .overlay(alignment: .top) {
                if let celebratedTrophy {
                    TrophyCelebrationBanner(trophy: celebratedTrophy)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("がまんぼ")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 14) {
                        Button {
                            isShowingAbout = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("アプリ情報")

                        Button {
                            isExportingCSV = true
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .accessibilityLabel("CSVを書き出す")

                        ShareLink(item: shareText) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("共有")
                    }
                }

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
            .sheet(isPresented: $isShowingAbout) {
                AboutView()
            }
            .fileExporter(
                isPresented: $isExportingCSV,
                document: CSVExportDocument(text: csvExportText),
                contentType: .commaSeparatedText,
                defaultFilename: csvFilename
            ) { _ in }
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
            .alert(
                "通知について",
                isPresented: Binding(
                    get: { reminderStore.alertMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            reminderStore.alertMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    reminderStore.alertMessage = nil
                }
            } message: {
                Text(reminderStore.alertMessage?.message ?? "")
            }
            .onAppear {
                previousUnlockedTrophyCount = store.trophies.filter(\.isUnlocked).count
            }
            .onChange(of: store.totalAmount) { _, _ in
                handleTrophyUnlockIfNeeded()
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

    private var filteredEntries: [GamanboEntry] {
        let monthFiltered = store.entries(for: selectedMonthStart)
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return monthFiltered }

        return monthFiltered.filter { entry in
            entry.title.localizedCaseInsensitiveContains(trimmed)
            || entry.note.localizedCaseInsensitiveContains(trimmed)
            || entry.category.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var selectedMonthSummary: MonthlySummary? {
        guard let selectedMonthStart else { return nil }
        return store.monthlySummaries.first {
            Calendar.current.isDate($0.monthStart, equalTo: selectedMonthStart, toGranularity: .month)
        }
    }

    private var categorySummaries: [CategorySummary] {
        store.categorySummaries(for: selectedMonthStart)
    }

    private var shareText: String {
        let label = selectedMonthSummary?.monthLabel ?? "今月"
        let total = selectedMonthSummary?.totalAmount ?? store.thisMonthTotal
        let count = selectedMonthSummary?.entryCount ?? store.thisMonthCount

        return """
        がまんぼ記録
        \(label)のがまん額: \(total.currencyText)
        記録数: \(count)件
        欲しいものをちょっと我慢して、コツコツ積み上げ中。
        """
    }

    private var csvExportText: String {
        store.csvText(for: selectedMonthStart)
    }

    private var csvFilename: String {
        if let selectedMonthSummary {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "yyyy-MM"
            return "gamanbo-\(formatter.string(from: selectedMonthSummary.monthStart))"
        }
        return "gamanbo-all"
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

    private var tipsSection: some View {
        Group {
            if !dismissedTips && store.entries.count < 5 {
                TipsCard(
                    suggestions: [
                        "コンビニのつい買いを我慢した",
                        "カフェを家コーヒーに置き換えた",
                        "セール品の衝動買いを見送った"
                    ],
                    onDismiss: { dismissedTips = true }
                )
            }
        }
    }

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                StatCard(
                    title: "連続記録",
                    value: "\(store.currentStreak)日",
                    caption: "ベストは\(store.bestStreak)日",
                    accent: Color(red: 0.88, green: 0.42, blue: 0.26)
                )

                StatCard(
                    title: "記録した日数",
                    value: "\(store.activeDaysCount)日",
                    caption: "積み上げた日数",
                    accent: Color(red: 0.28, green: 0.58, blue: 0.74)
                )
            }

            TrophyProgressCard(
                nextTrophy: store.nextTrophy,
                progress: store.nextTrophyProgress,
                nextMilestoneText: store.nextMilestoneText
            )
        }
    }

    private func handleTrophyUnlockIfNeeded() {
        let unlockedTrophies = store.trophies.filter(\.isUnlocked)
        let unlockedCount = unlockedTrophies.count

        guard unlockedCount > previousUnlockedTrophyCount,
              let latest = unlockedTrophies.last
        else {
            previousUnlockedTrophyCount = unlockedCount
            return
        }

        previousUnlockedTrophyCount = unlockedCount

        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            celebratedTrophy = latest
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut(duration: 0.25)) {
                if celebratedTrophy?.id == latest.id {
                    celebratedTrophy = nil
                }
            }
        }
    }

    private var reminderSection: some View {
        ReminderCard(
            isEnabled: reminderStore.isEnabled,
            reminderTime: reminderStore.reminderTime,
            onToggle: { reminderStore.setEnabled($0) },
            onTimeChange: { reminderStore.updateReminderTime($0) }
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
                VStack(alignment: .leading, spacing: 14) {
                    MonthFilterStrip(
                        summaries: store.monthlySummaries,
                        selectedMonthStart: $selectedMonthStart
                    )

                    MonthlyBarChart(
                        summaries: Array(store.monthlySummaries.prefix(3).reversed()),
                        highlightedMonthStart: selectedMonthStart
                    )
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("カテゴリ別の節約")
                    .font(.title3.weight(.bold))

                Spacer()

                Text(selectedMonthSummary?.monthLabel ?? "全期間")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("CSV書き出しは左上のダウンロードボタンからできます。")
                .font(.caption)
                .foregroundStyle(.secondary)

            if categorySummaries.isEmpty {
                EmptyCard(text: "記録が増えると、どのカテゴリで節約できたかここに表示されます。")
            } else {
                VStack(spacing: 12) {
                    ForEach(categorySummaries.prefix(4)) { summary in
                        CategorySummaryRow(summary: summary)
                    }
                }
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

                if !filteredEntries.isEmpty {
                    Text(selectedMonthSummary?.monthLabel ?? "新しい順")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
            }

            TextField("記録を検索", text: $searchText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                )

            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? (selectedMonthStart == nil ? "まだ記録がありません" : "この月の記録はありません")
                    : "一致する記録がありません",
                    systemImage: "tray",
                    description: Text(
                        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? (
                            selectedMonthStart == nil
                            ? "まずはコンビニのスイーツや衝動買いを我慢した記録から始めてみましょう。"
                            : "別の月を選ぶか、新しい我慢を記録してみましょう。"
                        )
                        : "別のキーワードで検索してみましょう。"
                    )
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.88))
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredEntries) { entry in
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

private struct ReminderCard: View {
    let isEnabled: Bool
    let reminderTime: Date
    let onToggle: (Bool) -> Void
    let onTimeChange: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ふりかえり通知")
                        .font(.title3.weight(.bold))

                    Text("毎日1回、がまんを記録する時間をやさしく知らせます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: onToggle
                ))
                .labelsHidden()
                .tint(Color(red: 0.20, green: 0.55, blue: 0.38))
            }

            HStack {
                Label("通知時刻", systemImage: "bell.badge")
                    .font(.subheadline.weight(.medium))

                Spacer()

                DatePicker(
                    "",
                    selection: Binding(
                        get: { reminderTime },
                        set: onTimeChange
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
            }

            Text(isEnabled ? "毎日 \(reminderTime.formatted(date: .omitted, time: .shortened)) に通知します。" : "通知はオフです。必要なときだけオンにできます。")
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

private struct TipsCard: View {
    let suggestions: [String]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("はじめのヒント")
                        .font(.title3.weight(.bold))

                    Text("迷ったら、まずは小さな我慢から記録してみると続けやすいです。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("閉じる", action: onDismiss)
                    .font(.caption.weight(.semibold))
            }

            ForEach(suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color(red: 0.87, green: 0.58, blue: 0.19))

                    Text(suggestion)
                        .font(.subheadline)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
    }
}

private struct TrophyProgressCard: View {
    let nextTrophy: Trophy?
    let progress: Double
    let nextMilestoneText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("次のトロフィー")
                .font(.headline)

            if let nextTrophy {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextTrophy.title)
                            .font(.title3.weight(.bold))

                        Text("あと\(nextMilestoneText)で獲得")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(nextTrophy.color)
                }

                ProgressView(value: progress)
                    .tint(nextTrophy.color)
            } else {
                Text("すべてのトロフィーを獲得済みです。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
    }
}

private struct TrophyCelebrationBanner: View {
    let trophy: Trophy

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(trophy.color)

            VStack(alignment: .leading, spacing: 2) {
                Text("トロフィー獲得")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(trophy.title)
                    .font(.headline)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.97))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(trophy.color.opacity(0.25), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 18, y: 10)
        .padding(.horizontal, 20)
    }
}

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppInfo.displayName)
                            .font(.system(size: 30, weight: .bold, design: .rounded))

                        Text("使ったお金ではなく、我慢して使わなかったお金を積み上げる家計簿アプリです。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.white)
                    )

                    InfoBlock(
                        title: "おすすめの使い方",
                        lines: [
                            "コンビニやカフェの小さな我慢から始める",
                            "月別フィルタで、調子の良い月を振り返る",
                            "CSV に書き出してあとから見返す"
                        ]
                    )

                    InfoBlock(
                        title: "アプリ情報",
                        lines: [
                            AppInfo.versionText,
                            AppInfo.supportMessage
                        ]
                    )
                }
                .padding(20)
            }
            .background(Color(red: 0.97, green: 0.96, blue: 0.92))
            .navigationTitle("アプリ情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct InfoBlock: View {
    let title: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.20, green: 0.55, blue: 0.38))

                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.95))
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

private struct CategorySummaryRow: View {
    let summary: CategorySummary

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(summary.category.color.opacity(0.18))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: summary.category.symbol)
                        .foregroundStyle(summary.category.color)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.category.rawValue)
                    .font(.headline)

                Text("\(summary.entryCount)件のがまん")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(summary.totalAmount.currencyText)
                .font(.headline.weight(.bold))
                .foregroundStyle(summary.category.color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
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

private struct MonthFilterStrip: View {
    let summaries: [MonthlySummary]
    @Binding var selectedMonthStart: Date?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                monthChip(title: "すべて", isSelected: selectedMonthStart == nil) {
                    selectedMonthStart = nil
                }

                ForEach(summaries) { summary in
                    monthChip(
                        title: summary.monthShortLabel,
                        isSelected: selectedMonthStart.map {
                            Calendar.current.isDate($0, equalTo: summary.monthStart, toGranularity: .month)
                        } ?? false
                    ) {
                        selectedMonthStart = summary.monthStart
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func monthChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color(red: 0.20, green: 0.55, blue: 0.38) : Color.white.opacity(0.92))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct MonthlyBarChart: View {
    let summaries: [MonthlySummary]
    let highlightedMonthStart: Date?

    private var maxAmount: Double {
        Double(summaries.map(\.totalAmount).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(summaries) { summary in
                    let isHighlighted = highlightedMonthStart.map {
                        Calendar.current.isDate($0, equalTo: summary.monthStart, toGranularity: .month)
                    } ?? false

                    VStack(spacing: 10) {
                        Text(summary.totalAmount.currencyText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(isHighlighted ? .primary : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        GeometryReader { proxy in
                            VStack {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                isHighlighted ? Color(red: 0.16, green: 0.49, blue: 0.43) : Color(red: 0.19, green: 0.61, blue: 0.50),
                                                isHighlighted ? Color(red: 0.83, green: 0.61, blue: 0.16) : Color(red: 0.91, green: 0.73, blue: 0.34)
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
                            .foregroundStyle(isHighlighted ? .primary : .secondary)
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
