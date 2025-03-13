import XCTest

@testable import PhotoExhibition

@MainActor
final class ExhibitionDetailStoreTests: XCTestCase {
  // テスト用のモックデータ
  private var testExhibition: Exhibition!
  private var mockExhibitionsClient: MockExhibitionsClient!
  private var mockCurrentUserClient: MockCurrentUserClient!
  private var mockStorageClient: MockStorageClient!
  private var mockStorageImageCache: MockStorageImageCache!

  override func setUp() async throws {
    // テスト用の展示会データを作成
    testExhibition = Exhibition(
      id: "test-exhibition-id",
      name: "Test Exhibition",
      description: "Test Description",
      from: Date(),
      to: Date().addingTimeInterval(60 * 60 * 24 * 7),  // 1週間後
      organizer: Member(
        id: "organizer-id",
        name: "Organizer Name",
        icon: nil,
        createdAt: Date(),
        updatedAt: Date()
      ),
      coverImagePath: "test/cover-image.jpg",
      createdAt: Date(),
      updatedAt: Date()
    )

    // モックの作成
    mockExhibitionsClient = MockExhibitionsClient()
    mockCurrentUserClient = MockCurrentUserClient()
    mockStorageClient = MockStorageClient()
    mockStorageImageCache = MockStorageImageCache()
  }

  override func tearDown() async throws {
    testExhibition = nil
    mockExhibitionsClient = nil
    mockCurrentUserClient = nil
    mockStorageClient = nil
    mockStorageImageCache = nil
  }

  // MARK: - 権限チェックのテスト

  func testIsOrganizerWhenCurrentUserIsOrganizer() {
    // 現在のユーザーを主催者に設定
    mockCurrentUserClient.mockUser = User(uid: "organizer-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 主催者であることを確認
    XCTAssertTrue(store.isOrganizer, "User should be recognized as the organizer")
  }

  func testIsNotOrganizerWhenCurrentUserIsNotOrganizer() {
    // 現在のユーザーを主催者以外に設定
    mockCurrentUserClient.mockUser = User(uid: "different-user-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 主催者でないことを確認
    XCTAssertFalse(store.isOrganizer, "User should not be recognized as the organizer")
  }

  func testIsNotOrganizerWhenNoCurrentUser() {
    // 現在のユーザーをnilに設定
    mockCurrentUserClient.mockUser = nil

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 主催者でないことを確認
    XCTAssertFalse(store.isOrganizer, "When no user is logged in, isOrganizer should be false")
  }

  func testCheckPermissionsUpdatesIsOrganizer() {
    // 最初は主催者でない
    mockCurrentUserClient.mockUser = User(uid: "different-user-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 主催者でないことを確認
    XCTAssertFalse(store.isOrganizer)

    // ユーザーを主催者に変更
    mockCurrentUserClient.mockUser = User(uid: "organizer-id")

    // 権限チェック
    store.send(ExhibitionDetailStore.Action.checkPermissions)

    // 主催者になったことを確認
    XCTAssertTrue(store.isOrganizer, "After checking permissions, isOrganizer should be updated")
  }

  // MARK: - アクションのテスト

  func testEditExhibitionActionShowsSheetWhenIsOrganizer() {
    // 現在のユーザーを主催者に設定
    mockCurrentUserClient.mockUser = User(uid: "organizer-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 編集アクションを送信
    store.send(ExhibitionDetailStore.Action.editExhibition)

    // 編集シートが表示されることを確認
    XCTAssertTrue(store.showEditSheet, "Edit sheet should be shown when user is organizer")
  }

  func testEditExhibitionActionDoesNotShowSheetWhenNotOrganizer() {
    // 現在のユーザーを主催者以外に設定
    mockCurrentUserClient.mockUser = User(uid: "different-user-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 編集アクションを送信
    store.send(ExhibitionDetailStore.Action.editExhibition)

    // 編集シートが表示されないことを確認
    XCTAssertFalse(store.showEditSheet, "Edit sheet should not be shown when user is not organizer")
  }

  func testDeleteExhibitionActionShowsConfirmationWhenIsOrganizer() {
    // 現在のユーザーを主催者に設定
    mockCurrentUserClient.mockUser = User(uid: "organizer-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 削除アクションを送信
    store.send(ExhibitionDetailStore.Action.deleteExhibition)

    // 削除確認が表示されることを確認
    XCTAssertTrue(
      store.showDeleteConfirmation, "Delete confirmation should be shown when user is organizer")
  }

  func testDeleteExhibitionActionDoesNotShowConfirmationWhenNotOrganizer() {
    // 現在のユーザーを主催者以外に設定
    mockCurrentUserClient.mockUser = User(uid: "different-user-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 削除アクションを送信
    store.send(ExhibitionDetailStore.Action.deleteExhibition)

    // 削除確認が表示されないことを確認
    XCTAssertFalse(
      store.showDeleteConfirmation,
      "Delete confirmation should not be shown when user is not organizer")
  }

  // MARK: - 削除機能のテスト

  func testConfirmDeleteCallsDeleteOnExhibitionsClient() async {
    // 現在のユーザーを主催者に設定
    mockCurrentUserClient.mockUser = User(uid: "organizer-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 削除確認アクションを送信
    store.send(ExhibitionDetailStore.Action.confirmDelete)

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockExhibitionsClient.deleteExpectation], timeout: 1.0)

    // 削除メソッドが呼ばれたことを確認
    XCTAssertTrue(mockExhibitionsClient.deleteWasCalled, "Delete method should be called")
    XCTAssertEqual(
      mockExhibitionsClient.deletedExhibitionId, "test-exhibition-id",
      "Correct exhibition ID should be passed to delete method")
  }

  func testConfirmDeleteDoesNotCallDeleteWhenNotOrganizer() async {
    // 現在のユーザーを主催者以外に設定
    mockCurrentUserClient.mockUser = User(uid: "different-user-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 削除確認アクションを送信
    store.send(ExhibitionDetailStore.Action.confirmDelete)

    // 少し待機
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 削除メソッドが呼ばれないことを確認
    XCTAssertFalse(
      mockExhibitionsClient.deleteWasCalled,
      "Delete method should not be called when user is not organizer")
  }

  func testSuccessfulDeleteSetsShouldDismissToTrue() async {
    // 現在のユーザーを主催者に設定
    mockCurrentUserClient.mockUser = User(uid: "organizer-id")

    // 削除成功を設定
    mockExhibitionsClient.shouldSucceed = true

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 削除確認アクションを送信
    store.send(ExhibitionDetailStore.Action.confirmDelete)

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockExhibitionsClient.deleteExpectation], timeout: 1.0)

    // shouldDismissがtrueになることを確認
    XCTAssertTrue(
      store.shouldDismiss, "shouldDismiss should be set to true after successful deletion")
  }

  func testFailedDeleteSetsErrorAndDoesNotSetShouldDismiss() async {
    // 現在のユーザーを主催者に設定
    mockCurrentUserClient.mockUser = User(uid: "organizer-id")

    // 削除失敗を設定
    mockExhibitionsClient.shouldSucceed = false
    mockExhibitionsClient.errorToThrow = NSError(
      domain: "test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 削除確認アクションを送信
    store.send(ExhibitionDetailStore.Action.confirmDelete)

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockExhibitionsClient.deleteExpectation], timeout: 1.0)

    // エラーが設定されることを確認
    XCTAssertNotNil(store.error, "Error should be set after failed deletion")

    // shouldDismissがfalseのままであることを確認
    XCTAssertFalse(store.shouldDismiss, "shouldDismiss should remain false after failed deletion")
  }

  // MARK: - 画像読み込みのテスト

  func testLoadCoverImageCallsStorageClient() async {
    // 現在のユーザーを設定
    mockCurrentUserClient.mockUser = User(uid: "user-id")

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 画像読み込みアクションを送信
    store.send(ExhibitionDetailStore.Action.loadCoverImage)

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockStorageImageCache.getImageURLExpectation], timeout: 1.0)

    // StorageImageCacheのgetImageURLメソッドが呼ばれたことを確認
    XCTAssertTrue(mockStorageImageCache.getImageURLWasCalled, "getImageURL method should be called")
    XCTAssertEqual(
      mockStorageImageCache.getImageURLPath, "test/cover-image.jpg",
      "Correct path should be passed to getImageURL method")
  }

  func testLoadCoverImageDoesNothingWhenNoCoverImagePath() {
    // カバー画像パスがない展示会を作成
    let exhibitionWithoutCover = Exhibition(
      id: "test-exhibition-id",
      name: "Test Exhibition",
      description: "Test Description",
      from: Date(),
      to: Date().addingTimeInterval(60 * 60 * 24 * 7),
      organizer: Member(
        id: "organizer-id",
        name: "Organizer Name",
        icon: nil,
        createdAt: Date(),
        updatedAt: Date()
      ),
      coverImagePath: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: exhibitionWithoutCover,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 画像読み込みアクションを送信
    store.send(ExhibitionDetailStore.Action.loadCoverImage)

    // StorageImageCacheのgetImageURLメソッドが呼ばれないことを確認
    XCTAssertFalse(
      mockStorageImageCache.getImageURLWasCalled,
      "getImageURL method should not be called when there is no cover image path")
  }

  func testLoadCoverImageHandlesError() async {
    // エラーを投げるように設定
    mockStorageImageCache.shouldThrowError = true

    // ストアの作成
    let store = ExhibitionDetailStore(
      exhibition: testExhibition,
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache
    )

    // 画像読み込みアクションを送信
    store.send(ExhibitionDetailStore.Action.loadCoverImage)

    // 非同期処理の完了を待つ
    await fulfillment(of: [mockStorageImageCache.getImageURLExpectation], timeout: 1.0)

    // エラーが処理されることを確認
    XCTAssertTrue(
      store.isLoadingCoverImage == false, "isLoadingCoverImage should be false after error")
    XCTAssertNil(store.coverImageURL, "coverImageURL should be nil after error")
  }
}
