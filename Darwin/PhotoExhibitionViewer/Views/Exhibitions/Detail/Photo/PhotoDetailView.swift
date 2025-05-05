import RealityKit
import SwiftUI
import Viewer

@Observable
final class PhotoDetailStore: Store {
  var imagePath: String
  let imagePaths: [String]
  let imageCache: any StorageImageCacheProtocol
  init(
    imagePath: String,
    imagePaths: [String],
    imageCache: any StorageImageCacheProtocol
  ) {
    self.imagePath = imagePath
    self.imagePaths = imagePaths
    self.imageCache = imageCache
  }
  var imageURL: URL?
  var isLoading: Bool = false

  enum Action {
    case task
    case showPreviousPhoto
    case showNextPhoto
  }

  func send(_ action: Action) {
    switch action {
    case .task:
      Task {
        do {
          imageURL = try await imageCache.getImageURL(for: imagePath)
        }
      }
    case .showPreviousPhoto:
      guard !imagePaths.isEmpty else { return }

      if let currentIndex = imagePaths.firstIndex(of: imagePath) {
        // If at the first photo, go to the last photo
        if currentIndex == 0 {
          imagePath = imagePaths[imagePaths.count - 1]
        } else {
          imagePath = imagePaths[currentIndex - 1]
        }
      } else if !imagePaths.isEmpty {
        // If current image not in paths, show the first one
        imagePath = imagePaths[0]
      }

      imageURL = nil
      Task {
        do {
          imageURL = try await imageCache.getImageURL(for: imagePath)
        }
      }
    case .showNextPhoto:
      guard !imagePaths.isEmpty else { return }

      if let currentIndex = imagePaths.firstIndex(of: imagePath) {
        // If at the last photo, go to the first photo
        if currentIndex == imagePaths.count - 1 {
          imagePath = imagePaths[0]
        } else {
          imagePath = imagePaths[currentIndex + 1]
        }
      } else if !imagePaths.isEmpty {
        // If current image not in paths, show the first one
        imagePath = imagePaths[0]
      }

      imageURL = nil
      Task {
        do {
          imageURL = try await imageCache.getImageURL(for: imagePath)
        }
      }
    }
  }

  var canShowPreviousPhoto: Bool {
    return imagePaths.count > 1
  }

  var canShowNextPhoto: Bool {
    return imagePaths.count > 1
  }
}

struct PhotoDetailView: View {
  @Environment(\.dismissWindow) var dismissWindow
  @Bindable var store: PhotoDetailStore

  var body: some View {
    RealityView { content, attachment in
      let mesh = MeshResource.generateBox(width: 1, height: 1, depth: 0.01)
      let material = SimpleMaterial(color: .white, isMetallic: false)
      let boxEntity = ModelEntity(mesh: mesh, materials: [material])
      content.add(boxEntity)
      if let photo = attachment.entity(for: "photo") {
        photo.position = [0, 0, 0.006]  // Z座標を調整して手前に移動
        content.add(photo)
      }

      if let buttons = attachment.entity(for: "button") {
        buttons.position = [0, 0, 0.01]
        content.add(buttons)
      }

      if let close = attachment.entity(for: "close") {
        close.position = [0.4, 0, 0.02]
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
              store.send(.showPreviousPhoto)
            } label: {
              Image(systemName: "chevron.backward")
            }
            .buttonStyle(.primaryButtonStyle)
            .accessibilityLabel(Text("Backward"))
            .disabled(!store.canShowPreviousPhoto)
            .hoverEffect { effect, isActive, _ in
              effect.scaleEffect(!isActive ? 1 : 1.5)
            }

            Spacer()
              .frame(width: 300)

            Button {
              store.send(.showNextPhoto)
            } label: {
              Image(systemName: "chevron.forward")
            }
            .buttonStyle(.primaryButtonStyle)
            .accessibilityLabel(Text("Forward"))
            .disabled(!store.canShowNextPhoto)
            .hoverEffect { effect, isActive, _ in
              effect.scaleEffect(!isActive ? 1 : 1.5)
            }
          }
        }
        .padding()
      }

      Attachment(id: "close") {
        VStack(alignment: .trailing) {
          HStack(spacing: 16) {
            Button {
              Task {
                dismissWindow()
              }
            } label: {
              Image(systemName: "xmark")
            }
            .buttonStyle(.secondaryButtonStyle)
            .hoverEffect { effect, isActive, _ in
              effect.scaleEffect(!isActive ? 1 : 1.2)
            }
          }

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
      imagePath: "",
      imagePaths: [],
      imageCache: StorageImageCache.shared
    )
  )
}
