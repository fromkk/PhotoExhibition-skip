#if !SKIP
  import CoreMotion
  import Foundation
  import PhotoExhibitionModel
  import SwiftUI
  import UIKit

  #if canImport(RealityKit)
    import RealityKit
  #endif

  @Observable @MainActor
  final class PanoramaMotionManager {
    private let motionManager = CMMotionManager()
    var deviceRotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])

    func startTracking() {
      guard motionManager.isDeviceMotionAvailable else { return }

      motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
      motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) {
        [weak self] motion, error in
        guard let motion = motion, error == nil else { return }

        let quat = motion.attitude.quaternion
        let deviceRotation = simd_quatf(
          ix: Float(quat.x),
          iy: Float(quat.y),
          iz: Float(quat.z),
          r: Float(quat.w)
        )

        let x90 = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

        self?.deviceRotation = (x90 * deviceRotation).inverse
      }
    }

    func stopTracking() {
      motionManager.stopDeviceMotionUpdates()
    }
  }

  @available(iOS 18.0, *)
  struct PanoramaPhotoView: View {
    let photo: Photo
    let imageCache: any StorageImageCacheProtocol
    let onClose: () -> Void

    @State private var motionManager = PanoramaMotionManager()
    @State private var rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    @State private var lastRotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    @State private var useMotionTracking = true
    @State private var uiImage: UIImage?
    @State private var isLoading = true

    var body: some View {
      ZStack {
        Color.black.ignoresSafeArea()

        if isLoading {
          ProgressView()
            .tint(.white)
        } else if uiImage != nil {
          RealityView { content in
            guard let sphereEntity = createPanoramaSphere() else { return }
            content.add(sphereEntity)
          } update: { content in
            if let sphereEntity = content.entities.first {
              if useMotionTracking {
                sphereEntity.transform.rotation = motionManager.deviceRotation
              } else {
                sphereEntity.transform.rotation = rotation
              }
            }
          }
          .gesture(
            DragGesture()
              .onChanged { value in
                useMotionTracking = false

                let sensitivity: Float = 0.01
                let deltaX = Float(value.translation.width) * sensitivity
                let deltaY = Float(value.translation.height) * sensitivity

                let rotationX = simd_quatf(angle: -deltaY, axis: [1, 0, 0])
                let rotationY = simd_quatf(angle: -deltaX, axis: [0, 1, 0])

                rotation = rotationY * rotationX * lastRotation
              }
              .onEnded { _ in
                lastRotation = rotation
              }
          )
          .onAppear {
            motionManager.startTracking()
          }
          .onDisappear {
            motionManager.stopTracking()
          }
        } else {
          Text("Failed to load image")
            .foregroundStyle(.white)
        }

        if !useMotionTracking {
          VStack(alignment: .trailing) {
            ResetMotionTrackingButton {
              useMotionTracking.toggle()
            }

            Spacer()
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .trailing)
          .transition(.opacity)
        }
      }
      .task(id: photo.id) {
        resetViewState()
        await loadImage()
      }
    }

    private func loadImage() async {
      isLoading = true
      defer { isLoading = false }

      guard let imagePath = photo.path else { return }

      do {
        let url = try await imageCache.getImageURL(for: imagePath)
        if let data = try? Data(contentsOf: url),
          let image = UIImage(data: data)
        {
          uiImage = image
        }
      } catch {
        print("Failed to load panorama image: \(error)")
      }
    }

    private func resetViewState() {
      useMotionTracking = true
      rotation = simd_quatf(angle: 0, axis: [0, 1, 0])
      lastRotation = simd_quatf(angle: 0, axis: [0, 1, 0])
      uiImage = nil
    }

    private func createPanoramaSphere() -> ModelEntity? {
      guard let uiImage = uiImage else { return nil }

      var descriptor = MeshDescriptor()
      let radius: Float = 10.0
      let segments = 64

      var positions: [SIMD3<Float>] = []
      var normals: [SIMD3<Float>] = []
      var uvs: [SIMD2<Float>] = []
      var indices: [UInt32] = []

      for lat in 0...segments {
        let theta = Float(lat) * .pi / Float(segments)
        let sinTheta = sin(theta)
        let cosTheta = cos(theta)

        for lon in 0...segments {
          let phi = Float(lon) * 2 * .pi / Float(segments)
          let sinPhi = sin(phi)
          let cosPhi = cos(phi)

          let x = cosPhi * sinTheta
          let y = cosTheta
          let z = sinPhi * sinTheta

          positions.append([x * radius, y * radius, z * radius])
          normals.append([-x, -y, -z])
          uvs.append([Float(lon) / Float(segments), 1.0 - Float(lat) / Float(segments)])
        }
      }

      for lat in 0..<segments {
        for lon in 0..<segments {
          let first = UInt32(lat * (segments + 1) + lon)
          let second = UInt32(first + UInt32(segments + 1))

          indices.append(contentsOf: [first, second, first + 1])
          indices.append(contentsOf: [second, second + 1, first + 1])
        }
      }

      descriptor.positions = MeshBuffer(positions)
      descriptor.normals = MeshBuffer(normals)
      descriptor.textureCoordinates = MeshBuffer(uvs)
      descriptor.primitives = .triangles(indices)

      guard let mesh = try? MeshResource.generate(from: [descriptor]) else {
        return nil
      }

      var material = UnlitMaterial()
      if let texture = loadTexture(from: uiImage) {
        material.color = .init(texture: .init(texture))
      }

      let modelEntity = ModelEntity(mesh: mesh, materials: [material])
      return modelEntity
    }

    private func loadTexture(from image: UIImage) -> TextureResource? {
      let resizedImage = resizeImage(image, maxSize: 2048)

      guard let cgImage = resizedImage.cgImage else { return nil }

      return try? TextureResource(image: cgImage, options: .init(semantic: .color))
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
      let size = image.size
      let maxDimension = max(size.width, size.height)

      if maxDimension <= maxSize {
        return image
      }

      let scale = maxSize / maxDimension
      let newSize = CGSize(width: size.width * scale, height: size.height * scale)

      let renderer = UIGraphicsImageRenderer(size: newSize)
      return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
      }
    }
  }
#endif
