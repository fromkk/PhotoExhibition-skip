import SwiftUI
import Viewer

@Observable final class PhotoItemStore: Store, Hashable {
  var photo: Photo
  let imageCache: any StorageImageCacheProtocol
  init(
    photo: Photo,
    imageCache: any StorageImageCacheProtocol
  ) {
    self.photo = photo
    self.imageCache = imageCache
  }
  var imageURL: URL?
  var error: (any Error)?

  enum Action {
    case task
    case failed(any Error)
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      guard let path = photo.imagePath else { return }
      Task {
        do {
          imageURL = try await imageCache.getImageURL(for: path)
        } catch {
          send(.failed(error))
        }
      }
    case .failed(let error):
      self.error = error
    }
  }

  static func == (lhs: PhotoItemStore, rhs: PhotoItemStore) -> Bool {
    lhs.photo.id == rhs.photo.id
  }

  var hashValue: Int {
    photo.hashValue
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(photo.hashValue)
  }
}

struct PhotoItemView: View {
  @Bindable var store: PhotoItemStore
  let onTap: () -> Void

  var body: some View {
    Button {
      onTap()
    } label: {
      ZStack(alignment: .bottomLeading) {
        Color.gray
          .aspectRatio(1, contentMode: .fill)
          .overlay {
            AsyncImage(url: store.imageURL) { phase in
              switch phase {
              case .success(let image):
                image
                  .resizable()
                  .scaledToFill()
              default:
                ProgressView()
              }
            }
          }
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        LinearGradient(
          stops: [
            .init(color: .black.opacity(0), location: 0.7),
            .init(color: .black.opacity(0.5), location: 1),
          ],
          startPoint: .top,
          endPoint: .bottom
        )

        VStack(spacing: 8) {
          if let title = store.photo.title {
            Text(title)
              .font(.headline)
              .frame(maxWidth: .infinity, alignment: .leading)
              .multilineTextAlignment(.leading)
          }

          if let description = store.photo.description {
            Text(description)
              .font(.footnote)
              .frame(maxWidth: .infinity, alignment: .leading)
              .multilineTextAlignment(.leading)
          }
        }
        .padding()
      }
    }
    .buttonStyle(.plain)
    .task {
      store.send(.task)
    }
  }
}
