import SwiftUI

#if canImport(Observation)
  import Observation
#endif

@Observable
final class ExhibitionsStore: Store {
  enum Action {
    case task
    case refresh
    case createExhibition
    case editExhibition(Exhibition)
    case showExhibitionDetail(Exhibition)
    case loadMore
  }

  var exhibitions: [Exhibition] = []
  var isLoading: Bool = false
  var error: Error? = nil
  var showCreateExhibition: Bool = false
  var exhibitionToEdit: Exhibition? = nil
  var selectedExhibition: Exhibition? = nil
  private var nextCursor: String? = nil
  var hasMore: Bool = true

  private let exhibitionsClient: ExhibitionsClient

  init(exhibitionsClient: ExhibitionsClient = DefaultExhibitionsClient()) {
    self.exhibitionsClient = exhibitionsClient
  }

  func send(_ action: Action) {
    switch action {
    case .task, .refresh:
      fetchExhibitions()
    case .createExhibition:
      showCreateExhibition = true
    case .editExhibition(let exhibition):
      exhibitionToEdit = exhibition
    case .showExhibitionDetail(let exhibition):
      selectedExhibition = exhibition
    case .loadMore:
      if !isLoading && hasMore {
        fetchMoreExhibitions()
      }
    }
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
