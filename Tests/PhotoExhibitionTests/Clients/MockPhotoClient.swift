import XCTest

@testable import PhotoExhibition

@MainActor
final class MockPhotoClient: PhotoClient {
  // MARK: - テスト用のプロパティ

  // fetchPhotos()の呼び出し追跡
  var fetchPhotosWasCalled: Bool = false
  var fetchPhotosExhibitionId: String? = nil
  var mockPhotos: [Photo] = []
  var fetchPhotosResult: [Photo] = []
  var fetchPhotosCallCount: Int = 0
  var fetchPhotosError: Error? = nil

  // addPhoto()の呼び出し追跡
  var addPhotoWasCalled: Bool = false
  var addPhotoExhibitionId: String? = nil
  var addPhotoId: String? = nil
  var addPhotoPath: String? = nil
  var addPhotoSort: Int? = nil
  var mockAddedPhoto: Photo? = nil
  var addPhotoResult: Photo? = nil

  // updatePhoto()の呼び出し追跡
  var updatePhotoWasCalled: Bool = false
  var updatePhotoExhibitionId: String? = nil
  var updatePhotoId: String? = nil
  var updatePhotoTitle: String? = nil
  var updatePhotoDescription: String? = nil

  // deletePhoto()の呼び出し追跡
  var deletePhotoWasCalled: Bool = false
  var isDeletePhotoCalled: Bool { deletePhotoWasCalled }
  var deletePhotoExhibitionId: String? = nil
  var deletePhotoId: String? = nil
  var shouldFailDelete: Bool = false

  // updatePhotoSort()の呼び出し追跡
  var updatePhotoSortWasCalled: Bool = false
  var updatePhotoSortExhibitionId: String? = nil
  var updatePhotoSortId: String? = nil
  var updatePhotoSortValue: Int? = nil

  // 成功/失敗のシミュレーション
  var shouldSucceed: Bool = true
  var errorToThrow: Error? = nil
  var shouldThrowError: Bool = false

  // MARK: - PhotoClientプロトコルの実装

  func fetchPhotos(exhibitionId: String) async throws -> [Photo] {
    fetchPhotosWasCalled = true
    fetchPhotosExhibitionId = exhibitionId
    fetchPhotosCallCount += 1

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed || shouldThrowError, let error = errorToThrow ?? fetchPhotosError {
      throw error
    }

    if !fetchPhotosResult.isEmpty {
      return fetchPhotosResult
    }

    return mockPhotos
  }

  func addPhoto(exhibitionId: String, photoId: String, path: String, sort: Int) async throws
    -> Photo
  {
    addPhotoWasCalled = true
    addPhotoExhibitionId = exhibitionId
    addPhotoId = photoId
    addPhotoPath = path
    addPhotoSort = sort

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed || shouldThrowError, let error = errorToThrow {
      throw error
    }

    if let result = addPhotoResult {
      return result
    }

    if let mockPhoto = mockAddedPhoto {
      return mockPhoto
    }

    throw NSError(
      domain: "MockPhotoClient",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "No mock photo provided"]
    )
  }

  func updatePhoto(exhibitionId: String, photoId: String, title: String?, description: String?)
    async throws
  {
    updatePhotoWasCalled = true
    updatePhotoExhibitionId = exhibitionId
    updatePhotoId = photoId
    updatePhotoTitle = title
    updatePhotoDescription = description

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed || shouldThrowError, let error = errorToThrow {
      throw error
    }
  }

  func deletePhoto(exhibitionId: String, photoId: String) async throws {
    deletePhotoWasCalled = true
    deletePhotoExhibitionId = exhibitionId
    deletePhotoId = photoId

    // 非同期処理をシミュレート
    await Task.yield()

    if shouldFailDelete || !shouldSucceed || shouldThrowError, let error = errorToThrow {
      throw error
    }
  }

  func updatePhotoSort(exhibitionId: String, photoId: String, sort: Int) async throws {
    updatePhotoSortWasCalled = true
    updatePhotoSortExhibitionId = exhibitionId
    updatePhotoSortId = photoId
    updatePhotoSortValue = sort

    // 非同期処理をシミュレート
    await Task.yield()

    if !shouldSucceed || shouldThrowError, let error = errorToThrow {
      throw error
    }
  }

  // MARK: - テスト用のヘルパーメソッド

  func reset() {
    fetchPhotosWasCalled = false
    fetchPhotosExhibitionId = nil
    fetchPhotosResult = []
    fetchPhotosCallCount = 0
    fetchPhotosError = nil

    addPhotoWasCalled = false
    addPhotoExhibitionId = nil
    addPhotoId = nil
    addPhotoPath = nil
    addPhotoSort = nil
    addPhotoResult = nil

    updatePhotoWasCalled = false
    updatePhotoExhibitionId = nil
    updatePhotoId = nil
    updatePhotoTitle = nil
    updatePhotoDescription = nil

    deletePhotoWasCalled = false
    deletePhotoExhibitionId = nil
    deletePhotoId = nil

    updatePhotoSortWasCalled = false
    updatePhotoSortExhibitionId = nil
    updatePhotoSortId = nil
    updatePhotoSortValue = nil

    shouldSucceed = true
    errorToThrow = nil
    shouldThrowError = false
  }
}
