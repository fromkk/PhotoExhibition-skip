import QuickLook
import SwiftUI
import Viewer

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

  var reportStore: ReportStore?

  enum Action {
    case task
    case reportButtonTapped
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
    case .reportButtonTapped:
      guard let exhibitionId = exhibition.id else { return }
      reportStore = ReportStore(type: .exhibition, id: exhibitionId)
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
      VStack(spacing: 16) {
        Text(store.exhibition.name)
          .font(.headline.bold())
          .frame(maxWidth: .infinity, alignment: .leading)
          .multilineTextAlignment(.leading)

        if let description = store.exhibition.description {
          Text(description)
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }

        LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
          ForEach(store.photos, id: \.self) { itemStore in
            PhotoItemView(store: itemStore) {

              if let imageURL = itemStore.imageURL, imageURL.isSpatialPhoto {
                let previewItem = PreviewItem(
                  url: imageURL, displayName: itemStore.photo.title, editingMode: .disabled)
                let _ = PreviewApplication.open(items: [previewItem])
                return
              }

              guard let imagePath = itemStore.photo.imagePath else {
                return
              }
              openWindow(
                id: "PhotoDetail",
                value: ImagePaths(
                  imagePath: imagePath,
                  imagePaths: store.photos.compactMap {
                    $0.photo.imagePath
                  }
                )
              )
            }
            .frame(maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fill)
          }
        }
      }
      .padding()
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.reportButtonTapped)
        } label: {
          Image(systemName: "exclamationmark.triangle")
            .accessibilityLabel("Report exhibition")
        }
        .accessibilityLabel(Text("Report"))
      }
    }
    .sheet(
      item: $store.reportStore
    ) { reportStore in
      ReportView(store: reportStore)
    }
    .alert(
      "Error",
      isPresented: Binding(
        get: { store.error != nil },
        set: { if !$0 { store.error = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(store.error?.localizedDescription ?? "An error occurred")
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
