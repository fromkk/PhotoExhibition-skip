# リポジトリ概要

このリポジトリは Swift 製アプリを [Skip](https://skip.tools) で Android 向け Kotlin プロジェクトへ変換する構成になっています。`Package.swift` に Skip プラグインと Firebase 関連の依存が定義されています。ビルドやテスト手順は `README.md` に記載されています。

## 主なディレクトリ
- **Sources/**
  - `PhotoExhibition` – アプリのメインモジュール。エントリポイントとなる View や画面が配置されます。
  - `PhotoExhibitionModel` – Firebase を利用するクライアントやエンティティを含みます。`Clients/` や `Entities/` が配置されています。
  - `Viewer` – エンドユーザー向けのモデル・クライアント・ビューをまとめたモジュールです。
  - `WidgetClients` – ウィジェット用のクライアントとエンティティ。
  - `IntentHelper` – 通知名の拡張などユーティリティ。
- **Tests/**
  - `PhotoExhibitionTests/` 以下に機能別テストがあり、`XCSkipTests.swift` から Skip 変換後の Kotlin テストも実行できます。
- **Android/** と **Darwin/**
  - Skip により生成・利用される Android 用 Gradle プロジェクトと iOS 向け Xcode プロジェクトが置かれています。

## ビルド・テスト方法
1. Homebrew で Skip をインストール: `brew install skiptools/skip/skip`
2. `skip checkup` で依存ツールを確認
3. iOS/Android それぞれを実行する場合は Xcode と Android Studio を準備

CI 環境では `ci_scripts/ci_post_clone.sh` が実行され、Skip インストールと Xcode 設定が自動化されます。

## 重要なポイント
- Swift と Kotlin で挙動を揃えるために `#if SKIP` などの条件コンパイルを多用しています（例: `Data+.swift` や `StorageClient.swift`）。
- Firebase (Firestore, Storage, Auth など) との連携が多いため、各クライアントの役割を把握すると理解が進みます。
- View 層では `@Observable` な Store クラスを利用し、テストもそれに沿って実装されています。

## 次に学ぶべきこと
1. **Skip ツールチェーンの使い方** – `README.md` に沿って Skip をインストールし、`skip checkup` や `skip test` を試してみましょう。
2. **Firebase クライアントの実装** – `Sources/PhotoExhibitionModel/Clients/` を確認し、認証やストレージ操作の流れを把握します。
3. **各 View と Store の連携** – `Sources/PhotoExhibition/Views/` や `Viewer/` モジュールの Store クラスを読み、UI とビジネスロジックの接続方法を学びます。
4. **テストの書き方** – `Tests/PhotoExhibitionTests/` を参照し、モックの作り方や非同期テストのパターンを確認しましょう。
