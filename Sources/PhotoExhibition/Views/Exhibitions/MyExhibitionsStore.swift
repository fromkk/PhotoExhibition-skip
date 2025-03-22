import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class MyExhibitionsStore: Store, ExhibitionEditStoreDelegate {
  enum Action {
    case task
    case refresh
    case loadMore
    case addButtonTapped
    case exhibitionSelected(Exhibition)
  }

  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true

  private let exhibitionsClient: any ExhibitionsClient
  private let currentUserClient: any CurrentUserClient
  private let analyticsClient: any AnalyticsClient

  var isExhibitionShown: Bool = false
  // 選択された展示会の詳細画面用のストアを保持
  private(set) var exhibitionDetailStore: ExhibitionDetailStore?

  var isExhibitionEditShown: Bool = false
  private(set) var exhibitionEditStore: ExhibitionEditStore?

  init(
    exhibitionsClient: any ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
    self.analyticsClient = analyticsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      fetchMyExhibitions()
      Task {
        await analyticsClient.analyticsScreen(name: "MyExhibitionsView")
      }
    case .refresh:
      fetchMyExhibitions()
    case .loadMore:
      if !isLoading && hasMore {
        fetchMoreExhibitions()
      }
    case let .exhibitionSelected(exhibition):
      exhibitionDetailStore = createExhibitionDetailStore(for: exhibition)
      isExhibitionShown = true
    case .addButtonTapped:
      exhibitionEditStore = ExhibitionEditStore(mode: .create, delegate: self)
      isExhibitionEditShown = true
    }
  }

  // 展示会詳細画面用のストアを作成するメソッド
  private func createExhibitionDetailStore(for exhibition: Exhibition) -> ExhibitionDetailStore {
    return ExhibitionDetailStore(exhibition: exhibition)
  }

  private func fetchMyExhibitions() {
    guard let currentUser = currentUserClient.currentUser() else {
      return
    }

    isLoading = true
    exhibitions = []
    nextCursor = nil
    hasMore = true

    Task {
      do {
        let result = try await exhibitionsClient.fetchMyExhibitions(
          organizerID: currentUser.uid, cursor: nil)
        exhibitions = result.exhibitions
        nextCursor = result.nextCursor
        hasMore = result.nextCursor != nil
      } catch {
        self.error = error
      }

      isLoading = false
    }
  }

  private func fetchMoreExhibitions() {
    guard let cursor = nextCursor, let currentUser = currentUserClient.currentUser() else { return }

    isLoading = true

    Task {
      do {
        let result = try await exhibitionsClient.fetchMyExhibitions(
          organizerID: currentUser.uid, cursor: cursor)
        exhibitions.append(contentsOf: result.exhibitions)
        nextCursor = result.nextCursor
        hasMore = result.nextCursor != nil
      } catch {
        self.error = error
      }

      isLoading = false
    }
  }

  func didSaveExhibition() {
    fetchMyExhibitions()
  }

  func didCancelExhibition() {
    // nop
  }
}
