import XCTest

@testable import PhotoExhibition

@MainActor
final class MockSignUpClient: SignUpClient {
  // MARK: - テスト用のプロパティ

  // signUp()の呼び出し追跡
  var signUpWasCalled: Bool = false
  var signUpEmail: String? = nil
  var signUpPassword: String? = nil
  var signUpExpectation = XCTestExpectation(description: "SignUp method called")

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

  // MARK: - SignUpClientプロトコルの実装

  func signUp(email: String, password: String) async throws -> Member {
    signUpWasCalled = true
    signUpEmail = email
    signUpPassword = password
    signUpExpectation.fulfill()

    if !shouldSucceed {
      if let error = errorToThrow {
        throw error
      } else {
        throw SignUpClientError.invalidData
      }
    }

    return mockMember
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    signUpWasCalled = false
    signUpEmail = nil
    signUpPassword = nil

    // 新しいExpectationを作成
    signUpExpectation = XCTestExpectation(description: "SignUp method called")

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
