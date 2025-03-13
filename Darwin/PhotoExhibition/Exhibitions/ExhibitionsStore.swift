import Foundation
import SkipFoundation
import SkipModel

@MainActor
public final class ExhibitionsStore: ObservableObject {
  @Published public private(set) var exhibitions: [Exhibition] = []
  @Published public private(set) var isLoading = false
  @Published public private(set) var error: Error?
  @Published public private(set) var hasMore = false

  private let client: ExhibitionsClient
  private var currentCursor: String?

  public init(client: ExhibitionsClient) {
    self.client = client
  }

  public func fetch() async {
    guard !isLoading else { return }

    isLoading = true
    error = nil

    do {
      let response = try await client.fetch(cursor: currentCursor)
      if currentCursor == nil {
        exhibitions = response.exhibitions
      } else {
        exhibitions.append(contentsOf: response.exhibitions)
      }
      currentCursor = response.nextCursor
      hasMore = response.nextCursor != nil
    } catch {
      self.error = error
    }

    isLoading = false
  }

  public func loadMoreIfNeeded(currentItem item: Exhibition) async {
    guard !isLoading, hasMore else { return }

    let thresholdIndex = exhibitions.index(exhibitions.endIndex, offsetBy: -5)
    if exhibitions.firstIndex(where: { $0.id == item.id }) ?? 0 >= thresholdIndex {
      await fetch()
    }
  }
}
