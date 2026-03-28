# Gamanbo

`がまんぼ` は、使ったお金ではなく「我慢して使わなかったお金」を積み上げる iOS アプリです。

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

## 開発メモ

- Xcode プロジェクト: `Gamanbo.xcodeproj`
- メイン画面: `Gamanbo/ContentView.swift`
- 保存ロジック: `Gamanbo/GamanboStore.swift`
- 通知設定: `Gamanbo/ReminderSettingsStore.swift`
- CSV 出力: `Gamanbo/CSVExportDocument.swift`
- アプリアイコン生成: `tools/generate_app_icon.swift`
