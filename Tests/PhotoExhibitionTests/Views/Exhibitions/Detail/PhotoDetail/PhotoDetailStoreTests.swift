import XCTest

@testable import PhotoExhibition

@MainActor
final class MockPhotoDetailStoreDelegate: PhotoDetailStoreDelegate {
  var didUpdatePhotoCalled = false
  var updatedPhoto: Photo? = nil
  var didDeletePhotoCalled = false
  var deletedPhotoId: String? = nil

  func photoDetailStore(_ store: PhotoDetailStore, didUpdatePhoto photo: Photo) {
    didUpdatePhotoCalled = true
    updatedPhoto = photo
  }

  func photoDetailStore(_ store: PhotoDetailStore, didDeletePhoto photoId: String) {
    didDeletePhotoCalled = true
    deletedPhotoId = photoId
  }

  func reset() {
    didUpdatePhotoCalled = false
    updatedPhoto = nil
    didDeletePhotoCalled = false
    deletedPhotoId = nil
  }
}

@MainActor
final class PhotoDetailStoreTests: XCTestCase {
  private var mockPhotoClient: MockPhotoClient!
  private var mockImageCache: MockStorageImageCache!
  private var mockDelegate: MockPhotoDetailStoreDelegate!
  private var store: PhotoDetailStore!
  private let exhibitionId = "test-exhibition-id"
  private let photo = Photo(
    id: "test-photo-id",
    path: "test-path",
    path_256x256: "test-path_256x256",
    path_512x512: "test-path_512x512",
    path_1024x1024: "test-path_1024x1024",
    title: "Test Photo",
    description: "Test Description",
    takenDate: Date(),
    photographer: "Test Photographer",
    createdAt: Date(),
    updatedAt: Date()
  )
  private let photos: [Photo] = [
    Photo(
      id: "test-photo-id",
      path: "test-path",
      path_256x256: "test-path_256x256",
      path_512x512: "test-path_512x512",
      path_1024x1024: "test-path_1024x1024",
      title: "Test Photo",
      description: "Test Description",
      takenDate: Date(),
      photographer: "Test Photographer",
      createdAt: Date(),
      updatedAt: Date()
    )
  ]
  private var mockAnalyticsClient: MockAnalyticsClient!

  override func setUp() async throws {
    mockPhotoClient = MockPhotoClient()
    mockImageCache = MockStorageImageCache()
    mockDelegate = MockPhotoDetailStoreDelegate()
    store = PhotoDetailStore(
      exhibitionId: exhibitionId,
      photo: photo,
      isOrganizer: true,
      photos: photos,
      delegate: mockDelegate,
      imageCache: mockImageCache,
      photoClient: mockPhotoClient
    )
    mockAnalyticsClient = MockAnalyticsClient()
  }

  func testLoadImage() async throws {
    // 準備
    let expectedURL = URL(string: "https://example.com/test-image.jpg")!
    mockImageCache.mockImageURL = expectedURL

    // 実行
    store.send(PhotoDetailStore.Action.loadImage)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockImageCache.getImageURLWasCalled)
    XCTAssertEqual(mockImageCache.getImageURLPath, "test-path_1024x1024")
    XCTAssertEqual(store.imageURL, expectedURL)
    XCTAssertFalse(store.isLoading)
  }

  func testUpdatePhoto() async throws {
    // 準備
    let title = "Updated Title"
    let description = "Updated Description"

    // 実行
    store.send(PhotoDetailStore.Action.updatePhoto(title: title, description: description))

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockPhotoClient.updatePhotoWasCalled)
    XCTAssertEqual(mockPhotoClient.updatePhotoExhibitionId, exhibitionId)
    XCTAssertEqual(mockPhotoClient.updatePhotoId, photo.id)
    XCTAssertEqual(mockPhotoClient.updatePhotoTitle, title)
    XCTAssertEqual(mockPhotoClient.updatePhotoDescription, description)
    XCTAssertFalse(store.showEditSheet)
  }

  func testDeletePhoto() async throws {
    // 実行
    store.send(PhotoDetailStore.Action.deleteButtonTapped)

    // 検証
    XCTAssertTrue(store.showDeleteConfirmation)

    // 削除を確認
    store.send(PhotoDetailStore.Action.confirmDeletePhoto)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockPhotoClient.deletePhotoWasCalled)
    XCTAssertEqual(mockPhotoClient.deletePhotoExhibitionId, exhibitionId)
    XCTAssertEqual(mockPhotoClient.deletePhotoId, photo.id)
    XCTAssertFalse(store.showDeleteConfirmation)
    XCTAssertTrue(store.isDeleted)
  }

  func testDeletePhotoFailure() async throws {
    // 準備
    mockPhotoClient.shouldSucceed = false
    mockPhotoClient.errorToThrow = NSError(domain: "test", code: 1, userInfo: nil)

    // 実行
    store.send(PhotoDetailStore.Action.deleteButtonTapped)
    store.send(PhotoDetailStore.Action.confirmDeletePhoto)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockPhotoClient.deletePhotoWasCalled)
    XCTAssertNotNil(store.error)
    XCTAssertFalse(store.isDeleted)
  }

  func testUpdatePhotoCallsDelegate() async throws {
    // 実行
    store.send(
      PhotoDetailStore.Action.updatePhoto(
        title: "Updated Title", description: "Updated Description"))

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockDelegate.didUpdatePhotoCalled, "Delegate method should be called")
    XCTAssertEqual(mockDelegate.updatedPhoto?.id, "test-photo-id")
    XCTAssertEqual(mockDelegate.updatedPhoto?.title, "Updated Title")
    XCTAssertEqual(mockDelegate.updatedPhoto?.description, "Updated Description")
  }

  func testDeletePhotoCallsDelegate() async throws {
    // 実行
    store.send(PhotoDetailStore.Action.confirmDeletePhoto)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)

    // 検証
    XCTAssertTrue(mockDelegate.didDeletePhotoCalled, "Delegate method should be called")
    XCTAssertEqual(mockDelegate.deletedPhotoId, "test-photo-id")
  }
}
