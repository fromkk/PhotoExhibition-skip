import SwiftUI

@Observable
final class ExhibitionDetailStore: Store, Hashable {
  var exhibition: Exhibition
  let photosClient: PhotosClient
  let imageClient: any StorageImageCacheProtocol
  init(
    exhibition: Exhibition,
    photosClient: PhotosClient,
    imageClient: any StorageImageCacheProtocol
  ) {
    self.exhibition = exhibition
    self.photosClient = photosClient
    self.imageClient = imageClient
  }

  var photos: [PhotoItemStore] = []
  var error: (any Error)?

  enum Action {
    case task
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        guard let exhibitionId = exhibition.id else { return }
        do {
          let photos = try await photosClient.fetch(exhibitionId)
          await MainActor.run {
            self.photos = photos.map {
              PhotoItemStore(photo: $0, imageCache: StorageImageCache.shared)
            }
          }
        } catch {
          self.error = error
        }
      }
    }
  }

  static func == (lhs: ExhibitionDetailStore, rhs: ExhibitionDetailStore)
    -> Bool
  {
    lhs.exhibition.id == rhs.exhibition.id
  }

  var hashValue: Int {
    exhibition.hashValue
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(exhibition.hashValue)
  }
}

struct ExhibitionDetailView: View {
  @Bindable var store: ExhibitionDetailStore

  @Environment(\.openWindow) var openWindow

  var body: some View {
    ScrollView {
      LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
        ForEach(store.photos, id: \.self) { itemStore in
          PhotoItemView(store: itemStore) {
            guard let exhibitionId = store.exhibition.id, let photoId = itemStore.photo.id else {
              return
            }
            openWindow(
              id: "PhotoDetail",
              value: WindowPhoto(
                exhibitionId: exhibitionId,
                photoId: photoId
              )
            )
          }
          .frame(maxHeight: .infinity)
          .aspectRatio(1, contentMode: .fill)
        }
      }
    }
    .task {
      store.send(.task)
    }
  }
}

#Preview {
  ExhibitionDetailView(
    store: ExhibitionDetailStore(
      exhibition: .test,
      photosClient: .liveValue,
      imageClient: StorageImageCache.shared
    )
  )
}
