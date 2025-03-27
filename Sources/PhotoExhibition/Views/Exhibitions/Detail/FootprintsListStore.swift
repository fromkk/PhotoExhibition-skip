import Foundation
import OSLog
import SkipKit
import SwiftUI

#if canImport(Observation)
  import Observation
#endif

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FootprintsList")

@MainActor
protocol FootprintsListStoreDelegate: AnyObject {
  func footprintsListDidClose()
}

@Observable
final class FootprintsListStore: Store {
  enum Action {
    case loadFootprints
    case loadMoreFootprints
    case closeButtonTapped
    case userTapped(userId: String)
  }

  private let exhibitionId: String
  private let footprintClient: any FootprintClient
  private let membersClient: any MembersClient
  private let imageCache: any StorageImageCacheProtocol

  // 足跡関連
  var footprints: [Footprint] = []
  var isLoadingFootprints: Bool = false
  var footprintNextCursor: String? = nil
  var hasMoreFootprints: Bool = true
  var shouldDismiss: Bool = false

  // 訪問者プロフィール表示関連
  private(set) var memberProfileStore: OrganizerProfileStore?
  var showMemberProfile: Bool = false

  weak var delegate: FootprintsListStoreDelegate?

  init(
    exhibitionId: String,
    footprintClient: any FootprintClient = DefaultFootprintClient(),
    membersClient: any MembersClient = DefaultMembersClient(),
    imageCache: any StorageImageCacheProtocol = StorageImageCache.shared,
    delegate: FootprintsListStoreDelegate? = nil
  ) {
    self.exhibitionId = exhibitionId
    self.footprintClient = footprintClient
    self.membersClient = membersClient
    self.imageCache = imageCache
    self.delegate = delegate
  }

  func send(_ action: Action) {
    switch action {
    case .loadFootprints:
      loadFootprints()
    case .loadMoreFootprints:
      loadMoreFootprints()
    case .closeButtonTapped:
      shouldDismiss = true
      delegate?.footprintsListDidClose()
    case .userTapped(let userId):
      showUserProfile(userId: userId)
    }
  }

  private func showUserProfile(userId: String) {
    Task {
      do {
        let userIds = [userId]
        let members = try await membersClient.fetch(userIds)
        if let member = members.first {
          self.memberProfileStore = OrganizerProfileStore(organizer: member)
          self.showMemberProfile = true
        }
      } catch {
        logger.error("Failed to fetch member: \(error.localizedDescription)")
      }
    }
  }

  private func loadFootprints() {
    isLoadingFootprints = true
    footprints = []
    footprintNextCursor = nil
    hasMoreFootprints = true

    Task {
      do {
        let result = try await footprintClient.fetchFootprints(
          exhibitionId: exhibitionId, cursor: nil)
        footprints = result.footprints
        footprintNextCursor = result.nextCursor
        hasMoreFootprints = result.nextCursor != nil
      } catch {
        logger.error("Failed to load footprints: \(error.localizedDescription)")
      }

      isLoadingFootprints = false
    }
  }

  private func loadMoreFootprints() {
    guard !isLoadingFootprints, hasMoreFootprints, let cursor = footprintNextCursor else { return }

    isLoadingFootprints = true

    Task {
      do {
        let result = try await footprintClient.fetchFootprints(
          exhibitionId: exhibitionId, cursor: cursor)
        footprints.append(contentsOf: result.footprints)
        footprintNextCursor = result.nextCursor
        hasMoreFootprints = result.nextCursor != nil
      } catch {
        logger.error("Failed to load more footprints: \(error.localizedDescription)")
      }

      isLoadingFootprints = false
    }
  }
}
