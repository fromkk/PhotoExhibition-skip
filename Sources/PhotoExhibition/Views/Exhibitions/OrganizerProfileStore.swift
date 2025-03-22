import Foundation
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class OrganizerProfileStore: Store {
  enum Action: Sendable {
    case task
    case loadMoreExhibitions
    case showExhibitionDetail(Exhibition)
  }

  var organizer: Member
  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true
  var organizerIconURL: URL? = nil
  var isLoadingIcon: Bool = false

  // 選択された展示会の詳細画面用のストアを保持
  private(set) var exhibitionDetailStore: ExhibitionDetailStore?
  // 詳細画面への遷移状態
  var isExhibitionDetailShown: Bool = false

  private let exhibitionsClient: any ExhibitionsClient
  private let imageCache: any StorageImageCacheProtocol
  private let analyticsClient: any AnalyticsClient
  private let photoClient: any PhotoClient
  private let currentUserClient: any CurrentUserClient
  private let storageClient: any StorageClient

  init(
    organizer: Member,
    exhibitionsClient: any ExhibitionsClient = DefaultExhibitionsClient(),
    imageCache: any StorageImageCacheProtocol = StorageImageCache.shared,
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient(),
    photoClient: any PhotoClient = DefaultPhotoClient(),
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    storageClient: any StorageClient = DefaultStorageClient()
  ) {
    self.organizer = organizer
    self.exhibitionsClient = exhibitionsClient
    self.imageCache = imageCache
    self.analyticsClient = analyticsClient
    self.photoClient = photoClient
    self.currentUserClient = currentUserClient
    self.storageClient = storageClient
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        await analyticsClient.analyticsScreen(name: "OrganizerProfileView")
        await analyticsClient.send(
          AnalyticsEvents.screenView,
          parameters: ["organizer_id": organizer.id, "event_name": AnalyticsEvents.organizerViewed])
      }
      loadIcon()
      fetchExhibitions()

    case .loadMoreExhibitions:
      if !isLoading && hasMore {
        fetchMoreExhibitions()
      }

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
    }
  }

  private func loadIcon() {
    guard let iconPath = organizer.iconPath else { return }

    isLoadingIcon = true

    Task {
      do {
        let url = try await imageCache.getImageURL(for: iconPath)
        self.organizerIconURL = url
      } catch {
        print("Failed to load organizer icon: \(error.localizedDescription)")
      }

      isLoadingIcon = false
    }
  }

  private func fetchExhibitions() {
    isLoading = true
    exhibitions = []
    nextCursor = nil
    hasMore = true

    Task {
      do {
        let result = try await exhibitionsClient.fetchMyExhibitions(
          organizerID: organizer.id, cursor: nil)

        // 公開済みの展示会のみをフィルター
        exhibitions = result.exhibitions.filter { $0.status == .published }
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
        let result = try await exhibitionsClient.fetchMyExhibitions(
          organizerID: organizer.id, cursor: cursor)

        // 公開済みの展示会のみをフィルター
        let published = result.exhibitions.filter { $0.status == .published }
        exhibitions.append(contentsOf: published)
        nextCursor = result.nextCursor
        hasMore = result.nextCursor != nil
      } catch {
        self.error = error
      }

      isLoading = false
    }
  }
}

extension AnalyticsEvents {
  static let organizerViewed = "organizer_viewed"
}
