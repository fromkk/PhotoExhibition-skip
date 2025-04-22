import FirebaseCore
import SwiftUI

@main
struct PhotoExhibitionViewerApp: App {
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }

    WindowGroup(id: "PhotoDetail", for: WindowPhoto.self) { $photo in
      if let exhibitionId = photo?.exhibitionId, let photoId = photo?.photoId {
        PhotoDetailView(
          store: PhotoDetailStore(
            exhibitionid: exhibitionId,
            photoId: photoId,
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
