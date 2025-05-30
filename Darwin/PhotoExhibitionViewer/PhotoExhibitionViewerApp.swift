import FirebaseCore
import SwiftUI
import Viewer

@main
struct PhotoExhibitionViewerApp: App {
  @State var contentStore: ContentStore = .init()

  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView(store: contentStore)
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
      } else {
        EmptyView()
      }
    }
    .windowStyle(.volumetric)
  }
}
