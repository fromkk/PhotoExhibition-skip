import XCTest

@testable import PhotoExhibition

@MainActor
final class ExhibitionsStoreTests: XCTestCase {
  // テスト用のモックデータ
  private var mockExhibitions: [Exhibition]!
  private var mockExhibitionsClient: MockExhibitionsClient!
  private var mockCurrentUserClient: MockCurrentUserClient!
  private var mockStorageClient: MockStorageClient!
  private var mockStorageImageCache: MockStorageImageCache!
  private var mockPhotoClient: MockPhotoClient!
  private var mockAnalyticsClient: MockAnalyticsClient!

  override func setUp() async throws {
    // テスト用の展示会データを作成
    let organizer = Member(
      id: "organizer-id",
      name: "Organizer Name",
      icon: nil,
      createdAt: Date(),
      updatedAt: Date()
    )

    mockExhibitions = [
      Exhibition(
        id: "exhibition-1",
        name: "Exhibition 1",
        description: "Description 1",
        from: Date(),
        to: Date().addingTimeInterval(60 * 60 * 24 * 7),
        organizer: organizer,
        coverImagePath: "test/cover-1.jpg",
        cover_256x256: "test/cover-1_256x256.jpg",
        cover_512x512: "test/cover-1_512x512.jpg",
        cover_1024x1024: "test/cover-1_1024x1024.jpg",
        createdAt: Date(),
        updatedAt: Date()
      ),
      Exhibition(
        id: "exhibition-2",
        name: "Exhibition 2",
        description: "Description 2",
        from: Date().addingTimeInterval(60 * 60 * 24 * 10),
        to: Date().addingTimeInterval(60 * 60 * 24 * 17),
        organizer: organizer,
        coverImagePath: "test/cover-2.jpg",
        cover_256x256: "test/cover-2_256x256.jpg",
        cover_512x512: "test/cover-2_512x512.jpg",
        cover_1024x1024: "test/cover-2_1024x1024.jpg",
        createdAt: Date(),
        updatedAt: Date()
      ),
    ]

    // モックの作成
    mockExhibitionsClient = MockExhibitionsClient()
    mockExhibitionsClient.mockExhibitions = mockExhibitions
    mockExhibitionsClient.mockNextCursor = "next-cursor"

    mockCurrentUserClient = MockCurrentUserClient()
    mockStorageClient = MockStorageClient()
    mockStorageImageCache = MockStorageImageCache()
    mockPhotoClient = MockPhotoClient()
    mockAnalyticsClient = MockAnalyticsClient()
  }

  override func tearDown() async throws {
    mockExhibitions = nil
    mockExhibitionsClient = nil
    mockCurrentUserClient = nil
    mockStorageClient = nil
    mockStorageImageCache = nil
    mockPhotoClient = nil
    mockAnalyticsClient = nil
  }

  // MARK: - 初期化のテスト

  func testInit() {
    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // 初期値を確認
    XCTAssertTrue(store.exhibitions.isEmpty)
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.showCreateExhibition)
    XCTAssertNil(store.exhibitionToEdit)
    XCTAssertNil(store.exhibitionDetailStore)
    XCTAssertFalse(store.isExhibitionDetailShown)
  }

  // MARK: - アクションのテスト

  func testTaskActionFetchesExhibitionsAndTracksScreen() async throws {
    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // 初期状態を確認
    XCTAssertTrue(store.exhibitions.isEmpty)
    XCTAssertFalse(store.isLoading)

    // taskアクションを送信
    store.send(ExhibitionsStore.Action.task)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 展示会データが取得されることを確認
    XCTAssertEqual(store.exhibitions.count, 2)
    XCTAssertEqual(store.exhibitions[0].id, "exhibition-1")
    XCTAssertEqual(store.exhibitions[1].id, "exhibition-2")

    // isLoadingがfalseに戻ることを確認
    XCTAssertFalse(store.isLoading)

    // スクリーントラッキングが呼ばれることを確認
    XCTAssertEqual(mockAnalyticsClient.screenCalls.count, 1)
    XCTAssertEqual(mockAnalyticsClient.screenCalls.first?.name, "ExhibitionsView")
  }

  func testLoadMoreActionFetchesMoreExhibitions() async throws {
    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // 初期データを取得
    store.send(ExhibitionsStore.Action.task)
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 次のページのデータを設定
    let nextPageExhibitions = [
      Exhibition(
        id: "exhibition-3",
        name: "Exhibition 3",
        description: "Description 3",
        from: Date().addingTimeInterval(60 * 60 * 24 * 20),
        to: Date().addingTimeInterval(60 * 60 * 24 * 27),
        organizer: mockExhibitions[0].organizer,
        coverImagePath: "test/cover-3.jpg",
        cover_256x256: "test/cover-3_256x256.jpg",
        cover_512x512: "test/cover-3_512x512.jpg",
        cover_1024x1024: "test/cover-3_1024x1024.jpg",
        createdAt: Date(),
        updatedAt: Date()
      )
    ]
    mockExhibitionsClient.mockExhibitions = nextPageExhibitions
    mockExhibitionsClient.mockNextCursor = nil

    // loadMoreアクションを送信
    store.send(ExhibitionsStore.Action.loadMore)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 展示会データが追加されることを確認
    XCTAssertEqual(store.exhibitions.count, 3)
    XCTAssertEqual(store.exhibitions[2].id, "exhibition-3")

    // isLoadingがfalseに戻ることを確認
    XCTAssertFalse(store.isLoading)

    // hasMoreがfalseになることを確認
    XCTAssertFalse(store.hasMore)
  }

  func testLoadMoreActionDoesNotFetchWhenNoMoreData() async throws {
    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // 初期データを取得
    store.send(ExhibitionsStore.Action.task)
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 次のページのデータがないことを設定
    mockExhibitionsClient.mockNextCursor = nil
    store.hasMore = false

    // loadMoreアクションを送信
    store.send(ExhibitionsStore.Action.loadMore)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // isLoadingがfalseのままであることを確認
    XCTAssertFalse(store.isLoading)

    // 展示会データが変更されていないことを確認
    XCTAssertEqual(store.exhibitions.count, 2)
  }

  func testRefreshActionFetchesExhibitions() async throws {
    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // refreshアクションを送信
    store.send(ExhibitionsStore.Action.refresh)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 展示会データが取得されることを確認
    XCTAssertEqual(store.exhibitions.count, 2)

    // isLoadingがfalseに戻ることを確認
    XCTAssertFalse(store.isLoading)
  }

  func testCreateExhibitionActionShowsCreateSheet() {
    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // createExhibitionアクションを送信
    store.send(ExhibitionsStore.Action.createExhibition)

    // 作成シートが表示されることを確認
    XCTAssertTrue(store.showCreateExhibition)
  }

  func testEditExhibitionActionSetsExhibitionToEdit() {
    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // 編集する展示会
    let exhibitionToEdit = mockExhibitions[0]

    // editExhibitionアクションを送信
    store.send(ExhibitionsStore.Action.editExhibition(exhibitionToEdit))

    // 編集対象の展示会が設定されることを確認
    XCTAssertEqual(store.exhibitionToEdit, exhibitionToEdit)
  }

  func testShowExhibitionDetailActionSetsExhibitionDetailStore() {
    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // 詳細表示する展示会
    let exhibitionToShow = mockExhibitions[1]

    // showExhibitionDetailアクションを送信
    store.send(ExhibitionsStore.Action.showExhibitionDetail(exhibitionToShow))

    // 展示会詳細ストアが設定されることを確認
    XCTAssertNotNil(store.exhibitionDetailStore)
    XCTAssertEqual(store.exhibitionDetailStore?.exhibition.id, exhibitionToShow.id)

    // 詳細画面への遷移状態がtrueになることを確認
    XCTAssertTrue(store.isExhibitionDetailShown)
  }

  // MARK: - エラー処理のテスト

  func testFetchExhibitionsHandlesError() async throws {
    // エラーを設定
    mockExhibitionsClient.shouldSucceed = false
    mockExhibitionsClient.errorToThrow = NSError(
      domain: "test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Fetch error"])

    // ストアの作成
    let store = ExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      storageClient: mockStorageClient,
      imageCache: mockStorageImageCache,
      photoClient: mockPhotoClient,
      analyticsClient: mockAnalyticsClient
    )

    // taskアクションを送信
    store.send(ExhibitionsStore.Action.task)

    // 非同期処理の完了を待つ
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // エラーが設定されることを確認
    XCTAssertNotNil(store.error)

    // 展示会データは空のままであることを確認
    XCTAssertTrue(store.exhibitions.isEmpty)

    // isLoadingがfalseに戻ることを確認
    XCTAssertFalse(store.isLoading)
  }
}
