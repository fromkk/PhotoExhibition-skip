import XCTest

@testable import PhotoExhibition

@MainActor
final class ExhibitionsStoreTests: XCTestCase {
  // テスト用のモックデータ
  private var mockExhibitions: [Exhibition]!
  private var mockExhibitionsClient: MockExhibitionsClient!

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
        createdAt: Date(),
        updatedAt: Date()
      ),
    ]

    // モックの作成
    mockExhibitionsClient = MockExhibitionsClient()
    mockExhibitionsClient.mockExhibitions = mockExhibitions
    mockExhibitionsClient.mockNextCursor = "next-cursor"
  }

  override func tearDown() async throws {
    mockExhibitions = nil
    mockExhibitionsClient = nil
  }

  // MARK: - 初期化のテスト

  func testInit() {
    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // 初期値を確認
    XCTAssertTrue(store.exhibitions.isEmpty)
    XCTAssertFalse(store.isLoading)
    XCTAssertNil(store.error)
    XCTAssertFalse(store.showCreateExhibition)
    XCTAssertNil(store.exhibitionToEdit)
    XCTAssertNil(store.selectedExhibition)
  }

  // MARK: - アクションのテスト

  func testTaskActionFetchesExhibitions() async {
    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // 初期状態を確認
    XCTAssertTrue(store.exhibitions.isEmpty)
    XCTAssertFalse(store.isLoading)

    // taskアクションを送信
    store.send(ExhibitionsStore.Action.task)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    // 非同期処理の完了を待つ
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 展示会データが取得されることを確認
    XCTAssertEqual(store.exhibitions.count, 2)
    XCTAssertEqual(store.exhibitions[0].id, "exhibition-1")
    XCTAssertEqual(store.exhibitions[1].id, "exhibition-2")

    // isLoadingがfalseに戻ることを確認
    XCTAssertFalse(store.isLoading)
  }

  func testLoadMoreActionFetchesMoreExhibitions() async {
    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // 初期データを取得
    store.send(ExhibitionsStore.Action.task)
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

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
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 展示会データが追加されることを確認
    XCTAssertEqual(store.exhibitions.count, 3)
    XCTAssertEqual(store.exhibitions[2].id, "exhibition-3")

    // isLoadingがfalseに戻ることを確認
    XCTAssertFalse(store.isLoading)

    // hasMoreがfalseになることを確認
    XCTAssertFalse(store.hasMore)
  }

  func testLoadMoreActionDoesNotFetchWhenNoMoreData() async {
    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // 初期データを取得
    store.send(ExhibitionsStore.Action.task)
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 次のページのデータがないことを設定
    mockExhibitionsClient.mockNextCursor = nil
    store.hasMore = false

    // loadMoreアクションを送信
    store.send(ExhibitionsStore.Action.loadMore)

    // 非同期処理の完了を待つ
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // isLoadingがfalseのままであることを確認
    XCTAssertFalse(store.isLoading)

    // 展示会データが変更されていないことを確認
    XCTAssertEqual(store.exhibitions.count, 2)
  }

  func testRefreshActionFetchesExhibitions() async {
    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // refreshアクションを送信
    store.send(ExhibitionsStore.Action.refresh)

    // isLoadingがtrueになることを確認
    XCTAssertTrue(store.isLoading)

    // 非同期処理の完了を待つ
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // 展示会データが取得されることを確認
    XCTAssertEqual(store.exhibitions.count, 2)

    // isLoadingがfalseに戻ることを確認
    XCTAssertFalse(store.isLoading)
  }

  func testCreateExhibitionActionShowsCreateSheet() {
    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // createExhibitionアクションを送信
    store.send(ExhibitionsStore.Action.createExhibition)

    // 作成シートが表示されることを確認
    XCTAssertTrue(store.showCreateExhibition)
  }

  func testEditExhibitionActionSetsExhibitionToEdit() {
    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // 編集する展示会
    let exhibitionToEdit = mockExhibitions[0]

    // editExhibitionアクションを送信
    store.send(ExhibitionsStore.Action.editExhibition(exhibitionToEdit))

    // 編集対象の展示会が設定されることを確認
    XCTAssertEqual(store.exhibitionToEdit, exhibitionToEdit)
  }

  func testShowExhibitionDetailActionSetsSelectedExhibition() {
    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // 詳細表示する展示会
    let exhibitionToShow = mockExhibitions[1]

    // showExhibitionDetailアクションを送信
    store.send(ExhibitionsStore.Action.showExhibitionDetail(exhibitionToShow))

    // 選択された展示会が設定されることを確認
    XCTAssertEqual(store.selectedExhibition, exhibitionToShow)
  }

  // MARK: - エラー処理のテスト

  func testFetchExhibitionsHandlesError() async {
    // エラーを設定
    mockExhibitionsClient.shouldSucceed = false
    mockExhibitionsClient.errorToThrow = NSError(
      domain: "test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Fetch error"])

    // ストアの作成
    let store = ExhibitionsStore(exhibitionsClient: mockExhibitionsClient)

    // taskアクションを送信
    store.send(ExhibitionsStore.Action.task)

    // 非同期処理の完了を待つ
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

    // エラーが設定されることを確認
    XCTAssertNotNil(store.error)

    // 展示会データは空のままであることを確認
    XCTAssertTrue(store.exhibitions.isEmpty)

    // isLoadingがfalseに戻ることを確認
    XCTAssertFalse(store.isLoading)
  }
}
