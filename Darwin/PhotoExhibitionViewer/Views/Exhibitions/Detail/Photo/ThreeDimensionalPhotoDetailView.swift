import RealityKit
import SwiftUI
import UIKit
import Viewer

struct ThreeDimensionalPhotoDetailView: View {
  let imagePath: String

  @State var uiImage: UIImage?

  var body: some View {
    Group {
      if let uiImage {
        RealityView { content in
          var materiel = SimpleMaterial()
          materiel.faceCulling = .none

          // UIImageからテクスチャを作成
          if let cgImage = uiImage.cgImage {
            let textureResource = try? TextureResource(
              image: cgImage,
              options: .init(semantic: .color)
            )
            if let textureResource = textureResource {
              materiel.color = .init(
                tint: .white,
                texture: .init(textureResource)
              )
            }
          }

          let sphere = ModelEntity(
            mesh: .generateSphere(radius: 10),
            materials: [materiel]
          )
          sphere.position = [0, 1, 0]
          // X軸を反転させて画像を左右反転
          sphere.scale.x *= -1
          content.add(sphere)
        }
      } else {
        ProgressView()
      }
    }
    .task {
      do {
        let url = try await StorageImageCache.shared.getImageURL(for: imagePath)
        let (imageData, _) = try await URLSession.shared.data(from: url)
        self.uiImage = UIImage(data: imageData)
      } catch {
        print("error \(error.localizedDescription)")
      }
    }
  }
}

extension View {
  @ViewBuilder
  func scaleToFit3DWithVisionOS26() -> some View {
    if #available(visionOS 26.0, *) {
      self
        .scaledToFit3D()
    } else {
      self
    }
  }
}

#Preview(immersionStyle: .full) {
  ThreeDimensionalPhotoDetailView(
    imagePath: "",
    uiImage: UIImage(resource: .logo)
  )
}
