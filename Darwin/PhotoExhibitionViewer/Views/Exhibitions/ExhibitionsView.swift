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

  func showExhibitionDetail(exhibitionId: String) {
    Task {
      do {
        // 展示会の詳細を取得
        let exhibition = try await exhibitionsClient.get(exhibitionId)

        // 展示が非公開の場合は何もしない
        guard exhibition.status == .published || exhibition.status == .limited else {
          print("Exhibition is not published: \(exhibitionId)")
          return
        }

        // 展示の期間外の場合は何もしない
        let now = Date()
        guard exhibition.from <= now && now <= exhibition.to else {
          print("Exhibition is not active: \(exhibitionId)")
          return
        }

        // メインスレッドで展示会の詳細画面を表示
        await MainActor.run {
          selectedExhibitionStore = .init(
            exhibition: exhibition, photosClient: PhotosClient.liveValue,
            imageClient: StorageImageCache.shared)
        }
      } catch {
        print("Failed to fetch exhibition: \(error.localizedDescription)")
      }
    }
  }
}

struct ExhibitionsView: View {
  @Bindable var store: ExhibitionsStore

  var body: some View {
    NavigationStack {
      Group {
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
      .navigationTitle(Text("Exhibitions"))
    }
    .task {
      store.send(.refreshed)
    }
  }
}

#Preview {
  ExhibitionsView(
    store: ExhibitionsStore(
      exhibitionsClient: ExhibitionsClient(fetch: { _, _ in ([], nil) }, get: { _ in .test }),
      imageClient: StorageImageCache.shared
    ))
}
