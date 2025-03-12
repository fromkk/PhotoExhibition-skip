import XCTest

@testable import PhotoExhibition

@MainActor
final class MockSignInClient: SignInClient {
  // MARK: - テスト用のプロパティ

  // signIn()の呼び出し追跡
  var signInWasCalled: Bool = false
  var signInEmail: String? = nil
  var signInPassword: String? = nil
  var signInExpectation = XCTestExpectation(description: "SignIn method called")

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
    signInExpectation.fulfill()

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

    // 新しいExpectationを作成
    signInExpectation = XCTestExpectation(description: "SignIn method called")

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
