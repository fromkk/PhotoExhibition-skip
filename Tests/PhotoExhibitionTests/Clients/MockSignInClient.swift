import XCTest

@testable import PhotoExhibition

@MainActor
final class MockSignInClient: SignInClient {
  // MARK: - テスト用のプロパティ

  // signIn()の呼び出し追跡
  var signInWasCalled: Bool = false
  var signInEmail: String? = nil
  var signInPassword: String? = nil

  // モック結果
  var mockMember: Member = Member(
    id: "mock-user-id",
    name: "Mock User",
    icon: nil,
    createdAt: Date(),
    updatedAt: Date()
  )

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil

  // MARK: - SignInClientプロトコルの実装

  func signIn(email: String, password: String) async throws -> Member {
    signInWasCalled = true
    signInEmail = email
    signInPassword = password

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed {
      if let error = errorToThrow {
        throw error
      } else {
        throw SignInClientError.memberNotFound
      }
    }

    return mockMember
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    signInWasCalled = false
    signInEmail = nil
    signInPassword = nil

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
