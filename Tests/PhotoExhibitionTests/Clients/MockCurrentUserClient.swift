import XCTest

@testable import PhotoExhibition

@MainActor
final class MockCurrentUserClient: @preconcurrency CurrentUserClient {
  // MARK: - テスト用のプロパティ

  // currentUser()のモック結果
  var mockUser: User? = nil

  // logout()の呼び出し追跡
  var logoutWasCalled: Bool = false
  var logoutExpectation = XCTestExpectation(description: "Logout method called")

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil

  // MARK: - CurrentUserClientプロトコルの実装

  func currentUser() -> User? {
    return mockUser
  }

  func logout() throws {
    logoutWasCalled = true
    logoutExpectation.fulfill()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    logoutWasCalled = false

    // 新しいExpectationを作成
    logoutExpectation = XCTestExpectation(description: "Logout method called")

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
