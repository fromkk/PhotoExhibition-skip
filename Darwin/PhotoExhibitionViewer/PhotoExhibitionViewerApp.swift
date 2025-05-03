import FirebaseCore
import SwiftUI
import Viewer

@Observable
final class ImmersiveStore: Store {
  var isImmersivePresented: Bool = false

  enum Action {
    case toggleIsImmersivePresented
  }
  func send(_ action: Action) {
    switch action {
    case .toggleIsImmersivePresented:
      isImmersivePresented.toggle()
    }
  }
}

@main
struct PhotoExhibitionViewerApp: App {
  @Bindable var store = ImmersiveStore()

  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(store)
    }

    WindowGroup(id: "PhotoDetail", for: ImagePaths.self) { $imagePaths in
      if let imagePath = imagePaths?.imagePath, let imagePaths = imagePaths?.imagePaths {
        PhotoDetailView(
          store: PhotoDetailStore(
            imagePath: imagePath,
            imagePaths: imagePaths,
            imageCache: StorageImageCache.shared
          )
        )
        .environment(store)
      } else {
        EmptyView()
      }
    }
    .windowStyle(.volumetric)

    ImmersiveSpace(id: "ImeersivePhotoDetail", for: ImagePaths.self) { $imagePaths in
      if let imagePath = imagePaths?.imagePath, let imagePaths = imagePaths?.imagePaths {
        PhotoDetailView(
          store: PhotoDetailStore(
            imagePath: imagePath,
            imagePaths: imagePaths,
            imageCache: StorageImageCache.shared
          )
        )
        .environment(store)
        .onAppear {
          store.isImmersivePresented = true
        }
      } else {
        EmptyView()
      }
    }
  }
}
