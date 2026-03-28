# Gamanbo

`がまんぼ` は、使ったお金ではなく「我慢して使わなかったお金」を積み上げる iOS アプリです。

## Overview

- App name: `がまんぼ`
- Platform: iOS
- Concept: 我慢した支出を記録して、節約できた金額と継続の手応えを見える化する

## Screens

- ホーム: 累計節約額、今月の節約額、連続記録、トロフィー進捗を表示
- 記録一覧: 検索、編集、削除に対応
- 分析: 月別グラフ、月別フィルタ、カテゴリ別集計を表示
- 補助機能: 通知リマインダー、共有、CSV エクスポート、アプリ情報

## コンセプト

- 衝動買いを我慢した記録を残す
- 節約できた金額を見える化する
- 継続するとトロフィーで達成感が出る

## 現在の機能

- 我慢した支出の追加
- 記録の編集
- 記録の削除
- 累計節約額の表示
- 今月の節約額の表示
- 連続記録日数とベスト記録の表示
- 月別の振り返り
- 月別フィルタ
- 月別グラフ
- カテゴリ別集計
- 記録の検索
- トロフィー表示
- トロフィー進捗表示
- トロフィー獲得時のバナー表示
- 初回向けヒント表示
- 毎日のふりかえり通知
- 共有テキスト出力
- CSV エクスポート

## Tech

- SwiftUI
- UserDefaults によるローカル保存
- UserNotifications によるローカル通知
- FileDocument による CSV 書き出し

## Run

1. Xcode で `Gamanbo.xcodeproj` を開く
2. Signing & Capabilities で必要に応じて Team を設定する
3. Simulator または実機で実行する

## Beginner Workflow

はじめて開発を進めるときは、毎回この流れで進めるとわかりやすいです。

### 1. 最新の `main` を使う

```bash
cd /Users/aikawa.yuki/Developer/Gamanbo
git checkout main
git pull
```

### 2. 新しい作業ブランチを作る

`feature-name` の部分は、やることに合わせて変えてください。

```bash
git checkout -b codex/feature-name
```

例:

```bash
git checkout -b codex/add-widget
git checkout -b codex/improve-search
```

### 3. Xcode で開発する

1. `Gamanbo.xcodeproj` を開く
2. 画面上で `Gamanbo` を選ぶ
3. 実行先に `iPhone Simulator` を選ぶ
4. `command + R` で起動する

### 4. 動作確認する

最低限、次を確認すると安心です。

- アプリが起動する
- 追加した機能が動く
- 既存の主要機能が壊れていない

必要に応じてビルド確認もできます。

```bash
xcodebuild -quiet -project Gamanbo.xcodeproj -scheme Gamanbo -destination 'generic/platform=iOS' -derivedDataPath /tmp/GamanboDerived CODE_SIGNING_ALLOWED=NO build
```

### 5. 変更を Git に保存する

```bash
git status
git add .
git commit -m "Describe what changed"
```

コミットメッセージ例:

```bash
git commit -m "Add widget prototype"
git commit -m "Improve monthly summary UI"
```

### 6. GitHub に push する

```bash
git push -u origin codex/feature-name
```

2回目以降は、同じブランチならこれだけで大丈夫です。

```bash
git push
```

### 7. GitHub で Pull Request を作る

1. GitHub のリポジトリを開く
2. `Compare & pull request` を押す
3. タイトルと本文を書く
4. `Create pull request` を押す

### 8. マージ後にローカルを片付ける

```bash
git checkout main
git pull
git branch -d codex/feature-name
```

### 困ったとき

- 今どのブランチにいるか確認したい:

```bash
git branch --show-current
```

- 変更されたファイルを見たい:

```bash
git status
```

- GitHub に送れているか確認したい:

```bash
git remote -v
```

## Suggested GitHub Description

`我慢して使わなかったお金を記録するiOSアプリ`

## 開発メモ

- Xcode プロジェクト: `Gamanbo.xcodeproj`
- メイン画面: `Gamanbo/ContentView.swift`
- 保存ロジック: `Gamanbo/GamanboStore.swift`
- 通知設定: `Gamanbo/ReminderSettingsStore.swift`
- CSV 出力: `Gamanbo/CSVExportDocument.swift`
- アプリアイコン生成: `tools/generate_app_icon.swift`
