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
  @Bindable var store: PhotoDetailStore

  var body: some View {
    RealityView { content, attachment in
      let mesh = MeshResource.generateBox(width: 0.6, height: 0.6, depth: 0.01)
      let material = SimpleMaterial(color: .white, isMetallic: false)
      let boxEntity = ModelEntity(mesh: mesh, materials: [material])
      content.add(boxEntity)
      if let sceneAttachment = attachment.entity(for: store.photoId) {
        sceneAttachment.position = [0, 0, 0.006]  // Z座標を調整して手前に移動
        sceneAttachment.scale = [0.6, 0.6, 1.0]  // Boxの前面の幅と高さに合わせるスケール
        content.add(sceneAttachment)
      }
    } placeholder: {
      ProgressView()
    } attachments: {
      Attachment(id: store.photoId) {
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
