import Foundation
import PhotoExhibitionModel
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
    case blockButtonTapped
    case unblockButtonTapped
    case blockUserCompleted
    case unblockUserCompleted
    case blockStateChanged(Bool)
  }

  var organizer: Member
  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true
  var organizerIconURL: URL? = nil
  var isLoadingIcon: Bool = false
  var isBlocked: Bool = false
  var isBlockingUser: Bool = false

  var canShowBlockButton: Bool {
    guard let currentUser = currentUserClient.currentUser() else { return false }
    return currentUser.uid != organizer.id
  }

  // 選択された展示会の詳細画面用のストアを保持
  var exhibitionDetailStore: ExhibitionDetailStore?

  private let exhibitionsClient: any ExhibitionsClient
  private let imageCache: any StorageImageCacheProtocol
  private let analyticsClient: any AnalyticsClient
  private let photoClient: any PhotoClient
  private let currentUserClient: any CurrentUserClient
  private let storageClient: any StorageClient
  private var blockClient: any BlockClient

  init(
    organizer: Member,
    exhibitionsClient: any ExhibitionsClient = DefaultExhibitionsClient(),
    imageCache: any StorageImageCacheProtocol = StorageImageCache.shared,
    analyticsClient: any AnalyticsClient = DefaultAnalyticsClient(),
    photoClient: any PhotoClient = DefaultPhotoClient(),
    currentUserClient: any CurrentUserClient = DefaultCurrentUserClient(),
    storageClient: any StorageClient = DefaultStorageClient(),
    blockClient: any BlockClient = DefaultBlockClient.shared
  ) {
    self.organizer = organizer
    self.exhibitionsClient = exhibitionsClient
    self.imageCache = imageCache
    self.analyticsClient = analyticsClient
    self.photoClient = photoClient
    self.currentUserClient = currentUserClient
    self.storageClient = storageClient
    self.blockClient = blockClient
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
      checkBlockStatus()

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

    case .blockButtonTapped:
      blockUser()

    case .unblockButtonTapped:
      unblockUser()

    case .blockUserCompleted:
      isBlocked = true
      isBlockingUser = false

    case .unblockUserCompleted:
      isBlocked = false
      isBlockingUser = false

    case .blockStateChanged(let isBlocked):
      self.isBlocked = isBlocked
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
        let result = try await exhibitionsClient.fetchPublishedActiveExhibitions(
          organizerID: organizer.id, now: Date(), cursor: nil)

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
        let result = try await exhibitionsClient.fetchPublishedActiveExhibitions(
          organizerID: organizer.id, now: Date(), cursor: cursor)

        exhibitions.append(contentsOf: result.exhibitions)
        nextCursor = result.nextCursor
        hasMore = result.nextCursor != nil
      } catch {
        self.error = error
      }

      isLoading = false
    }
  }

  private func checkBlockStatus() {
    guard let currentUser = currentUserClient.currentUser() else {
      return
    }

    Task {
      do {
        let isBlocked = try await blockClient.isBlocked(
          currentUserId: currentUser.uid, blockUserId: organizer.id)
        send(.blockStateChanged(isBlocked))
      } catch {
        print("Failed to check block status: \(error.localizedDescription)")
      }
    }
  }

  private func blockUser() {
    guard let currentUser = currentUserClient.currentUser(),
      !isBlockingUser
    else { return }

    isBlockingUser = true

    Task {
      do {
        try await blockClient.blockUser(currentUserId: currentUser.uid, blockUserId: organizer.id)
        send(.blockUserCompleted)
      } catch {
        print("Failed to block user: \(error.localizedDescription)")
        isBlockingUser = false
      }
    }
  }

  private func unblockUser() {
    guard let currentUser = currentUserClient.currentUser(),
      !isBlockingUser
    else { return }

    isBlockingUser = true

    Task {
      do {
        try await blockClient.unblockUser(currentUserId: currentUser.uid, blockUserId: organizer.id)
        send(.unblockUserCompleted)
      } catch {
        print("Failed to unblock user: \(error.localizedDescription)")
        isBlockingUser = false
      }
    }
  }
}

extension AnalyticsEvents {
  static let organizerViewed = "organizer_viewed"
}
