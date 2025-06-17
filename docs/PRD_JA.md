# 現状の機能一覧

このドキュメントでは、`PhotoExhibition` アプリに実装されている主な機能と画面構成をまとめます。

## 画面一覧

| 画面名 | Viewの名前 | 説明 |
| --- | --- | --- |
| ルート画面 | `RootView` | アプリ起動時のエントリーポイント。認証状態に応じて各画面へ遷移します。 |
| 認証トップ | `AuthRootView` | ログイン・会員登録の選択やAppleサインインを行う画面。 |
| 認証入力 | `AuthView` | メールアドレスとパスワードを入力してサインイン/サインアップする画面。 |
| プロフィール設定 | `ProfileSetupView` | ユーザー名やアイコン画像を設定します。初回ログイン時にも利用されます。 |
| 展示一覧 | `ExhibitionsView` | 投稿されている展示会の一覧を表示します。詳細画面や新規作成へ遷移できます。 |
| 展示詳細 | `ExhibitionDetailView` | 展示会の写真一覧や説明、主催者情報を確認します。 |
| AR表示 | `ExhibitionDetailARViewContainer` | 展示写真をAR空間で閲覧できるモード。 |
| 展示編集 | `ExhibitionEditView` | 展示会を新規作成・編集するフォーム画面。 |
| 投稿規約確認 | `PostAgreementView` | 写真投稿時に同意が必要な規約を表示します。 |
| 自分の展示一覧 | `MyExhibitionsView` | 自分が作成した展示会のみを一覧表示します。 |
| 写真詳細 | `PhotoDetailView` | 写真を拡大表示して詳細を確認します。 |
| 写真編集 | `PhotoEditView` | アップロードした写真のタイトルや説明を編集します。 |
| EXIF情報 | `ExifView` | 写真の撮影情報（EXIF）を表示します。 |
| オーガナイザープロフィール | `OrganizerProfileView` | 展示会の主催者情報や過去の展示を確認します。 |
| 訪問者一覧 | `FootprintsListView` | 展示を閲覧したユーザーの一覧を表示します。 |
| 設定 | `SettingsView` | プロフィール編集、ブロックリスト、ライセンス確認などを行います。 |
| ブロックリスト | `BlockedUsersView` | ブロックしたユーザーの一覧管理画面。 |
| お問い合わせ | `ContactView` | 運営への問い合わせメッセージを送信します。 |
| ライセンス一覧 | `LicenseListView` | 利用しているOSSライセンスの一覧を表示します。 |
| ライセンス詳細 | `LicenseDetailView` | 各OSSライセンスの全文を閲覧します。 |
| 通報 | `ReportView` | 不適切な展示・写真を運営へ報告するための画面。 |

## 機能概要

- Firebase Authentication を利用したメール認証および Apple サインイン
- Firestore/Storage を用いた展示会データと写真の保存
- 展示会の作成、編集、削除
- 写真のアップロード、編集、EXIF 情報の表示
- 足跡機能による訪問ユーザーの記録
- 不適切な内容の通報、ユーザーブロック
- お問い合わせフォームからの運営への連絡
- iOS/Android 双方で同一コードを使用する Skip ベースのクロスプラットフォーム対応


各画面の詳細なPRDは `docs/screens` ディレクトリに収録されています。
