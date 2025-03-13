import Foundation
import XCTest

@testable import PhotoExhibition

@MainActor
final class MockStorageImageCache: StorageImageCacheProtocol {
  var getImageURLExpectation = XCTestExpectation(description: "getImageURL called")
  var getImageURLWasCalled = false
  var getImageURLPath: String?
  var mockImageURL: URL?
  var shouldThrowError = false

  func getImageURL(for path: String) async throws -> URL {
    getImageURLWasCalled = true
    getImageURLPath = path
    getImageURLExpectation.fulfill()

    if shouldThrowError {
      throw NSError(
        domain: "MockStorageImageCache", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    }

    // テスト用のURLを返す
    return mockImageURL ?? URL(
      string: "file:///mock/image/path/\(path.replacingOccurrences(of: "/", with: "_"))")!
  }

  func clearCache() async {
    // テスト用なので何もしない
  }
}

extension MockStorageImageCache {
  func reset() {
    getImageURLWasCalled = false
    getImageURLPath = nil
    mockImageURL = nil
    shouldThrowError = false
    getImageURLExpectation = XCTestExpectation(description: "getImageURL called")
  }
}
