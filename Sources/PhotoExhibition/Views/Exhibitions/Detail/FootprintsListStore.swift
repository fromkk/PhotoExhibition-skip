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
  }

  private let exhibitionId: String
  private let footprintClient: any FootprintClient

  // 足跡関連
  var footprints: [Footprint] = []
  var isLoadingFootprints: Bool = false
  var footprintNextCursor: String? = nil
  var hasMoreFootprints: Bool = true
  var shouldDismiss: Bool = false

  weak var delegate: FootprintsListStoreDelegate?

  init(
    exhibitionId: String,
    footprintClient: any FootprintClient = DefaultFootprintClient(),
    delegate: FootprintsListStoreDelegate? = nil
  ) {
    self.exhibitionId = exhibitionId
    self.footprintClient = footprintClient
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
