import RealityKit
import SwiftUI

@Observable
final class PhotoDetailStore: Store {
  let exhibitionId: String
  let photoId: String
  let imageCache: any StorageImageCacheProtocol
  let photoClient: PhotoClient
  init(
    exhibitionid: String, photoId: String, imageCache: any StorageImageCacheProtocol,
    photoClient: PhotoClient
  ) {
    self.exhibitionId = exhibitionid
    self.photoId = photoId
    self.imageCache = imageCache
    self.photoClient = photoClient
  }
  var imageURL: URL?

  enum Action {
    case task
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        do {
          guard
            let imagePath = try await photoClient.fetch(exhibitionId, photoId)
              .imagePath
          else {
            return
          }
          imageURL = try await imageCache.getImageURL(for: imagePath)
        }
      }
    }
  }
}

struct PhotoDetailView: View {
  @Environment(\.dismissWindow) var dismissWindow
  @Bindable var store: PhotoDetailStore

  var body: some View {
    RealityView { content, attachment in
      let mesh = MeshResource.generateBox(width: 0.6, height: 0.6, depth: 0.01)
      let material = SimpleMaterial(color: .white, isMetallic: false)
      let boxEntity = ModelEntity(mesh: mesh, materials: [material])
      content.add(boxEntity)
      if let photo = attachment.entity(for: "photo") {
        photo.position = [0, 0, 0.006]  // Z座標を調整して手前に移動
        photo.scale = [0.6, 0.6, 1.0]  // Boxの前面の幅と高さに合わせるスケール
        content.add(photo)
      }

      if let buttons = attachment.entity(for: "button") {
        buttons.position = [0, 0, 0.01]
        content.add(buttons)
      }

      if let close = attachment.entity(for: "close") {
        close.position = [0.3, 0, 0.02]
        content.add(close)
      }
    } placeholder: {
      ProgressView()
    } attachments: {
      Attachment(id: "photo") {
        AsyncImage(url: store.imageURL) { phase in
          switch phase {
          case let .success(image):
            image
              .resizable()
              .scaledToFit()
          default:
            ProgressView()
          }
        }
      }

      Attachment(id: "button") {
        VStack {
          Spacer()

          HStack {
            Button {

            } label: {
              Image(systemName: "chevron.backward")
            }
            .buttonStyle(.primaryButtonStyle)
            .accessibilityLabel(Text("Backward"))

            Spacer()
              .frame(width: 300)

            Button {

            } label: {
              Image(systemName: "chevron.forward")
            }
            .buttonStyle(.primaryButtonStyle)
            .accessibilityLabel(Text("Forward"))
          }
        }
        .padding()
      }

      Attachment(id: "close") {
        VStack(alignment: .trailing) {
          Button {
            Task {
              dismissWindow()
            }
          } label: {
            Image(systemName: "xmark")
          }
          .buttonStyle(.secondaryButtonStyle)

          Spacer()
        }
        .padding()
      }
    }
    .task {
      store.send(.task)
    }
  }
}

#Preview {
  PhotoDetailView(
    store: PhotoDetailStore(
      exhibitionid: "exhibitionId", photoId: "photoId", imageCache: StorageImageCache.shared,
      photoClient: PhotoClient(fetch: { _, _ in .test })))
}
