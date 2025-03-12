import XCTest

@testable import PhotoExhibition

@MainActor
final class MockStorageClient: StorageClient {
  // MARK: - テスト用のプロパティ

  // url()の呼び出し追跡
  var urlWasCalled: Bool = false
  var urlPath: String? = nil
  var urlExpectation = XCTestExpectation(description: "URL method called")
  var mockURL: URL = URL(string: "https://example.com/mock-image.jpg")!

  // upload()の呼び出し追跡
  var uploadWasCalled: Bool = false
  var uploadFromURL: URL? = nil
  var uploadToPath: String? = nil
  var uploadExpectation = XCTestExpectation(description: "Upload method called")
  var mockUploadURL: URL = URL(string: "https://example.com/uploaded-image.jpg")!

  // delete()の呼び出し追跡
  var deleteWasCalled: Bool = false
  var deletePath: String? = nil
  var deleteExpectation = XCTestExpectation(description: "Delete method called")

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil

  // MARK: - StorageClientプロトコルの実装

  func url(_ path: String) async throws -> URL {
    urlWasCalled = true
    urlPath = path
    urlExpectation.fulfill()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    return mockURL
  }

  func upload(from url: URL, to path: String) async throws -> URL {
    uploadWasCalled = true
    uploadFromURL = url
    uploadToPath = path
    uploadExpectation.fulfill()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }

    return mockUploadURL
  }

  func delete(path: String) async throws {
    deleteWasCalled = true
    deletePath = path
    deleteExpectation.fulfill()

    if !shouldSucceed, let error = errorToThrow {
      throw error
    }
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    // 呼び出し追跡をリセット
    urlWasCalled = false
    urlPath = nil
    uploadWasCalled = false
    uploadFromURL = nil
    uploadToPath = nil
    deleteWasCalled = false
    deletePath = nil

    // 新しいExpectationを作成
    urlExpectation = XCTestExpectation(description: "URL method called")
    uploadExpectation = XCTestExpectation(description: "Upload method called")
    deleteExpectation = XCTestExpectation(description: "Delete method called")

    // デフォルト値に戻す
    shouldSucceed = true
    errorToThrow = nil
  }
}
