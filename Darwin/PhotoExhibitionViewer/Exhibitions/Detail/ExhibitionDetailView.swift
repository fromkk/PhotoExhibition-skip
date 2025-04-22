import RealityKit
import SwiftUI

@Observable
final class ExhibitionDetailStore: Hashable {
  var exhibition: Exhibition
  let photosClient: PhotosClient
  let imageClient: any StorageImageCacheProtocol
  init(
    exhibition: Exhibition, photosClient: PhotosClient, imageClient: any StorageImageCacheProtocol
  ) {
    self.exhibition = exhibition
    self.photosClient = photosClient
    self.imageClient = imageClient
  }

  var photos: [Photo] = []
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
          photos = try await photosClient.fetch(exhibitionId)
        } catch {
          self.error = error
        }
      }
      return
    }
  }

  static func == (lhs: ExhibitionDetailStore, rhs: ExhibitionDetailStore) -> Bool {
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

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(store.photos, id: \.self) { photo in

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
