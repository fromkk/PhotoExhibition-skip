import XCTest

@testable import PhotoExhibition

@MainActor
final class MyExhibitionsStoreTests: XCTestCase {
  private var mockExhibitionsClient: MockExhibitionsClient!
  private var mockCurrentUserClient: MockCurrentUserClient!
  private var mockMembersClient: MockMembersClient!
  private var mockMemberUpdateClient: MockMemberUpdateClient!
  private var mockAnalyticsClient: MockAnalyticsClient!

  override func setUp() async throws {
    mockExhibitionsClient = MockExhibitionsClient()
    mockCurrentUserClient = MockCurrentUserClient()
    mockMembersClient = MockMembersClient()
    mockMemberUpdateClient = MockMemberUpdateClient()
    mockAnalyticsClient = MockAnalyticsClient()
  }

  private func createStore() -> MyExhibitionsStore {
    return MyExhibitionsStore(
      exhibitionsClient: mockExhibitionsClient,
      currentUserClient: mockCurrentUserClient,
      membersClient: mockMembersClient,
      memberUpdateClient: mockMemberUpdateClient,
      analyticsClient: mockAnalyticsClient
    )
  }

  func testPostAgreement() async throws {
    let store = createStore()
    mockCurrentUserClient.mockUser = User(uid: "test-user")

    // メンバー情報のモックを設定
    mockMembersClient.mockMembers = [
      Member(
        id: "test-user",
        name: "Test User",
        icon: nil,
        postAgreement: false,
        createdAt: Date(),
        updatedAt: Date()
      )
    ]

    store.send(MyExhibitionsStore.Action.addButtonTapped)

    XCTAssertTrue(store.isLoadingMember)
    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertFalse(store.isLoadingMember)
    XCTAssertTrue(store.showPostAgreement)

    store.send(MyExhibitionsStore.Action.postAgreementAccepted)
    XCTAssertFalse(store.showPostAgreement)
    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertTrue(mockMemberUpdateClient.postAgreementCalled)
    XCTAssertEqual(mockMemberUpdateClient.postAgreementMemberID, "test-user")

    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertTrue(store.isExhibitionEditShown)
    XCTAssertNotNil(store.exhibitionEditStore)
  }

  // エラーケースのテストを追加
  func testPostAgreementError() async throws {
    let store = createStore()
    mockCurrentUserClient.mockUser = User(uid: "test-user")

    // エラーを設定
    mockMemberUpdateClient.postAgreementError = NSError(domain: "test", code: 123, userInfo: nil)

    store.send(MyExhibitionsStore.Action.postAgreementAccepted)

    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertNotNil(store.error)
    XCTAssertFalse(store.isExhibitionEditShown)
  }

  func testAddButtonTappedWithAgreedUser() async throws {
    let store = createStore()
    mockCurrentUserClient.mockUser = User(uid: "test-user")

    // メンバー情報のモックを設定（既にガイドラインに同意済み）
    mockMembersClient.mockMembers = [
      Member(
        id: "test-user",
        name: "Test User",
        icon: nil,
        postAgreement: true,  // 既に同意済み
        createdAt: Date(),
        updatedAt: Date()

      )
    ]

    store.send(MyExhibitionsStore.Action.addButtonTapped)
    XCTAssertTrue(store.isLoadingMember)

    try await Task.sleep(nanoseconds: 100_000_000)

    // ガイドライン同意済みなので、直接作成画面が表示される
    XCTAssertFalse(store.isLoadingMember)
    XCTAssertFalse(store.showPostAgreement)
    XCTAssertTrue(store.isExhibitionEditShown)
    XCTAssertNotNil(store.exhibitionEditStore)
  }

  // ... 他の既存のテスト ...
}
