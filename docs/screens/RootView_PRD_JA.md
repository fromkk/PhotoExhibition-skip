# RootView 画面 PRD

- **画面名**: ルート画面
- **View名**: `RootView`
- **目的**: 認証状態を確認し、適切なトップ画面へ遷移する
- **主な機能**:
  - Firebase Authentication のログイン状態を判定
  - 未認証なら `AuthRootView` へ遷移
  - 認証済みの場合は `ExhibitionsView` を表示
