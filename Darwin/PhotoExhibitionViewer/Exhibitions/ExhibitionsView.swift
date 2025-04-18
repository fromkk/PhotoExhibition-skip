import SwiftUI

@Observable
final class ExhibitionsStore {
  let exhibitionsClient: ExhibitionsClient
  init(exhibitionsClient: ExhibitionsClient, imageClient: any StorageImageCacheProtocol) {
    self.exhibitionsClient = exhibitionsClient
    self.imageClient = imageClient
  }

  let imageClient: any StorageImageCacheProtocol
  var exhibitions: [ExhibitionItemStore] = []
  var cursor: String?
  var error: (any Error)?
  var hasMore: Bool {
    cursor != nil
  }

  func refresh() {
    exhibitions = []
    cursor = nil
    next()
  }

  func next() {
    let now = Date()
    Task {
      do {
        let (exhibitions, cursor) = try await exhibitionsClient.fetch(now, cursor)
        self.exhibitions.append(
          contentsOf: exhibitions.map {
            ExhibitionItemStore(exhibition: $0, imageClient: imageClient)
          })
        self.cursor = cursor
      } catch {
        self.error = error
      }
    }
  }
}

struct ExhibitionsView: View {
  @Bindable var store: ExhibitionsStore

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(store.exhibitions) { itemStore in
          ExhibitionItemView(store: itemStore)
        }

        if store.hasMore {
          ProgressView()
        }
      }
    }
    .refreshable {
      store.refresh()
    }
    .task {
      store.next()
    }
  }
}
