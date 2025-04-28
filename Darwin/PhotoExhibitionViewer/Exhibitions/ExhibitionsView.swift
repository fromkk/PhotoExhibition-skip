import SwiftUI
import Viewer

@Observable
final class ExhibitionsStore: Store {
  let exhibitionsClient: ExhibitionsClient
  init(exhibitionsClient: ExhibitionsClient, imageClient: any StorageImageCacheProtocol) {
    self.exhibitionsClient = exhibitionsClient
    self.imageClient = imageClient
  }

  let imageClient: any StorageImageCacheProtocol
  var exhibitions: [ExhibitionItemStore] = []
  var isLoading: Bool = false
  var cursor: String?
  var error: (any Error)?
  var hasMore: Bool {
    cursor != nil
  }

  var selectedExhibitionStore: ExhibitionDetailStore?

  enum Action {
    case refreshed
    case nextCalled
    case selected(Exhibition)
  }

  func send(_ action: Action) {
    switch action {
    case .refreshed:
      refresh()
    case .nextCalled:
      next()
    case let .selected(exhibition):
      selectedExhibitionStore = ExhibitionDetailStore(
        exhibition: exhibition,
        photosClient: .liveValue,
        imageClient: StorageImageCache.shared
      )
    }
  }

  func refresh() {
    exhibitions = []
    cursor = nil
    next()
  }

  func next() {
    isLoading = true
    let now = Date()
    Task {
      do {
        let (exhibitions, cursor) = try await exhibitionsClient.fetch(now, cursor)
        self.exhibitions.append(
          contentsOf: exhibitions.map {
            ExhibitionItemStore(exhibition: $0, imageClient: imageClient)
          })
        self.cursor = cursor
        self.isLoading = false
      } catch {
        self.error = error
        self.isLoading = false
      }
    }
  }
}

struct ExhibitionsView: View {
  @Bindable var store: ExhibitionsStore

  var body: some View {
    NavigationStack {
      if store.exhibitions.isEmpty, store.isLoading {
        ProgressView()
      } else {
        if store.exhibitions.isEmpty {
          ContentUnavailableView("No Exhibitions", systemImage: "photo")
        } else {
          ScrollView(.horizontal) {
            LazyHStack {
              ForEach(store.exhibitions) { itemStore in
                ExhibitionItemView(store: itemStore) {
                  store.send(.selected(itemStore.exhibition))
                }
              }
              if store.hasMore {
                ProgressView()
                  .task {
                    store.send(.nextCalled)
                  }
              }
            }
          }
          .refreshable {
            store.send(.refreshed)
          }
          .navigationDestination(item: $store.selectedExhibitionStore) { store in
            ExhibitionDetailView(store: store)
          }
        }
      }
    }
    .task {
      store.send(.refreshed)
    }
  }
}

#Preview {
  ExhibitionsView(
    store: ExhibitionsStore(
      exhibitionsClient: ExhibitionsClient(fetch: { _, _ in ([], nil) }),
      imageClient: StorageImageCache.shared
    ))
}
