import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class ExhibitionsStore: Store, ExhibitionEditStoreDelegate {
  enum Action {
    case task
    case refresh
    case createExhibition
    case editExhibition(Exhibition)
    case showExhibitionDetail(Exhibition)
    case loadMore
    case exhibitionCreated(Exhibition)
    case exhibitionUpdated(Exhibition)
  }

  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  var showCreateExhibition: Bool = false
  var exhibitionToEdit: Exhibition? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true

  // 選択された展示会の詳細画面用のストアを保持
  private(set) var exhibitionDetailStore: ExhibitionDetailStore?
  // 詳細画面への遷移状態
  var isExhibitionDetailShown: Bool = false
  // 展示会編集画面用のストアを保持
  private(set) var exhibitionEditStore: ExhibitionEditStore?

  private let exhibitionsClient: any ExhibitionsClient
  private let currentUserClient: any CurrentUserClient
  private let storageClient: any StorageClient
  private let imageCache: any StorageImageCacheProtocol
  private let photoClient: any PhotoClient
  private let analyticsClient: any AnalyticsClient

  init(
    exhibitionsClient: any ExhibitionsClient = DefaultExhibitionsClient(),
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    storageClient: any StorageClient = DefaultStorageClient(),
    imageCache: any StorageImageCacheProtocol = StorageImageCache.shared,
    photoClient: any PhotoClient = DefaultPhotoClient(),
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient()
  ) {
    self.exhibitionsClient = exhibitionsClient
    self.currentUserClient = currentUserClient
    self.storageClient = storageClient
    self.imageCache = imageCache
    self.photoClient = photoClient
    self.analyticsClient = analyticsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      fetchExhibitions()
      Task {
        await analyticsClient.analyticsScreen(name: "ExhibitionsView")
      }
    case .refresh:
      fetchExhibitions()
    case .createExhibition:
      exhibitionEditStore = ExhibitionEditStore(
        mode: .create,
        delegate: self,
        currentUserClient: currentUserClient,
        exhibitionsClient: exhibitionsClient,
        storageClient: storageClient,
        imageCache: imageCache
      )
      showCreateExhibition = true
    case .editExhibition(let exhibition):
      exhibitionEditStore = ExhibitionEditStore(
        mode: .edit(exhibition),
        delegate: self,
        currentUserClient: currentUserClient,
        exhibitionsClient: exhibitionsClient,
        storageClient: storageClient,
        imageCache: imageCache
      )
      exhibitionToEdit = exhibition
    case .showExhibitionDetail(let exhibition):
      exhibitionDetailStore = ExhibitionDetailStore(
        exhibition: exhibition,
        exhibitionsClient: exhibitionsClient,
        currentUserClient: currentUserClient,
        storageClient: storageClient,
        imageCache: imageCache,
        photoClient: photoClient
      )
      isExhibitionDetailShown = true
    case .loadMore:
      if !isLoading && hasMore {
        fetchMoreExhibitions()
      }
    case .exhibitionCreated(let exhibition):
      exhibitions.insert(exhibition, at: 0)
      showCreateExhibition = false
      exhibitionEditStore = nil
    case .exhibitionUpdated(let exhibition):
      if let index = exhibitions.firstIndex(where: { $0.id == exhibition.id }) {
        exhibitions[index] = exhibition
      }
      exhibitionToEdit = nil
      exhibitionEditStore = nil
    }
  }

  // MARK: - ExhibitionEditStoreDelegate

  func didSaveExhibition() {
    send(.refresh)
  }

  func didCancelExhibition() {
    // nothing to do
  }

  private func fetchExhibitions() {
    isLoading = true
    exhibitions = []
    nextCursor = nil
    hasMore = true

    Task {
      do {
        let result = try await exhibitionsClient.fetch(now: Date(), cursor: nil)
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
    guard let cursor = nextCursor else { return }

    isLoading = true

    Task {
      do {
        let result = try await exhibitionsClient.fetch(now: Date(), cursor: cursor)
        exhibitions.append(contentsOf: result.exhibitions)
        nextCursor = result.nextCursor
        hasMore = result.nextCursor != nil
      } catch {
        self.error = error
      }

      isLoading = false
    }
  }
}
