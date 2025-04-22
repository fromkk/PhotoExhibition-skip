import RealityKit
import SwiftUI

@Observable
final class PhotoDetailStore: Store {
  let exhibitionId: String
  let photoId: String
  let imageCache: any StorageImageCacheProtocol
  init(exhibitionid: String, photoId: String, imageCache: any StorageImageCacheProtocol) {
    self.exhibitionId = exhibitionid
    self.photoId = photoId
    self.imageCache = imageCache
  }

  enum Action {
    case task
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      return
    }
  }
}

struct PhotoDetailView: View {
  @Bindable var store: PhotoDetailStore

  var body: some View {
    RealityView { context, attachment in
      let mesh = MeshResource.generateBox(width: 0.6, height: 0.6, depth: 0.01)
      let material = SimpleMaterial(color: .white, isMetallic: false)
      let boxEntity = ModelEntity(mesh: mesh, materials: [material])
      context.add(boxEntity)
    } attachments: {

    }
    .task {
      store.send(.task)
    }
  }
}
