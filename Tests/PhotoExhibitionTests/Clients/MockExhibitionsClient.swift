import XCTest

@testable import PhotoExhibition

@MainActor
final class MockExhibitionsClient: ExhibitionsClient {
  // MARK: - テスト用のプロパティ

  // fetch()のモック結果
  var mockExhibitions: [Exhibition] = []
  var fetchExpectation = XCTestExpectation(description: "Fetch method called")
  var mockNextCursor: String? = nil

  // delete()の呼び出し追跡
  var deleteWasCalled: Bool = false
  var deletedExhibitionId: String? = nil
  var deleteExpectation = XCTestExpectation(description: "Delete method called")

  // create()の呼び出し追跡
  var createWasCalled: Bool = false
  var createdData: [String: any Sendable]? = nil
  var mockCreatedId: String = "mock-created-id"
  var createExpectation = XCTestExpectation(description: "Create method called")

  // update()の呼び出し追跡
  var updateWasCalled: Bool = false
  var updatedId: String? = nil
  var updatedData: [String: any Sendable]? = nil
  var updateExpectation = XCTestExpectation(description: "Update method called")

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil

  // MARK: - ExhibitionsClientプロトコルの実装

  func fetch(now: Date, cursor: String?) async throws -> (
    exhibitions: [Exhibition], nextCursor: String?
  ) {
    fetchExpectation.fulfill()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
    return (mockExhibitions, mockNextCursor)
  }

  func create(data: [String: any Sendable]) async throws -> String {
    createWasCalled = true
    createdData = data
    createExpectation.fulfill()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    return mockCreatedId
  }

  func update(id: String, data: [String: any Sendable]) async throws {
    updateWasCalled = true
    updatedId = id
    updatedData = data
    updateExpectation.fulfill()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  func delete(id: String) async throws {
    deleteWasCalled = true
    deletedExhibitionId = id
    deleteExpectation.fulfill()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    deleteWasCalled = false
    deletedExhibitionId = nil
    createWasCalled = false
    createdData = nil
    updateWasCalled = false
    updatedId = nil
    updatedData = nil

    // 新しいExpectationを作成
    fetchExpectation = XCTestExpectation(description: "Fetch method called")
    deleteExpectation = XCTestExpectation(description: "Delete method called")
    createExpectation = XCTestExpectation(description: "Create method called")
    updateExpectation = XCTestExpectation(description: "Update method called")

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
