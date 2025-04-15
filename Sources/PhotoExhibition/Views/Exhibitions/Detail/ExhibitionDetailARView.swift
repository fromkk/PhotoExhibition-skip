#if !SKIP
  @preconcurrency import ARKit
  import UIKit
  import SceneKit
  import SwiftUI

  extension SCNNode: @unchecked @retroactive Sendable {}

  final class ExhibitionDetailARViewController: UIViewController,
    ARSCNViewDelegate
  {
    var image: UIImage?  // 表示する画像を保持するプロパティ
    private var imageNode: SCNNode?  // 画像ノードを保持

    var sceneView: ARSCNView = {
      let view = ARSCNView()
      view.translatesAutoresizingMaskIntoConstraints = false
      return view
    }()

    override func viewDidLoad() {
      super.viewDidLoad()

      view.addSubview(sceneView)
      NSLayoutConstraint.activate([
        sceneView.topAnchor.constraint(equalTo: view.topAnchor),
        sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      ])

      // Set the view's delegate
      sceneView.delegate = self

      // Show statistics such as fps and timing information
      #if DEBUG
        // sceneView.showsStatistics = true
      #endif

      // Create a new scene
      let scene = SCNScene()

      // Set the scene to the view
      sceneView.scene = scene
    }

    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)

      // Create and configure session configuration
      let configuration = ARWorldTrackingConfiguration()
      configuration.sceneReconstruction = .meshWithClassification
      configuration.planeDetection = [.vertical]
      configuration.isLightEstimationEnabled = true

      // メッシュ化とオブジェクトの分類
      configuration.sceneReconstruction = .meshWithClassification

      // オクルージョンを有効化
      if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
        // People Occlusionを適用
        configuration.frameSemantics = [.personSegmentationWithDepth]
      }

      // Run the view's session
      sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    nonisolated func renderer(
      _ renderer: SCNSceneRenderer,
      didAdd node: SCNNode,
      for anchor: ARAnchor
    ) {
      guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
      Task {
        await addCanvasIfNeeded(node, planeAnchor: planeAnchor)
      }
    }

    private var canvasNode: SCNNode?

    private func addCanvasIfNeeded(_ node: SCNNode, planeAnchor: ARPlaneAnchor) {
      guard canvasNode == nil else { return }
      // 壁の中心に配置する
      let canvasNode = createCanvas()

      // 壁の中心位置を取得
      let center = SCNVector3(
        planeAnchor.center.x,
        planeAnchor.center.y,
        planeAnchor.center.z
      )

      // 壁の向きを取得
      let transform = SCNMatrix4(planeAnchor.transform)

      // 壁の法線ベクトルを取得
      let normal = SCNVector3(transform.m31, transform.m32, transform.m33)

      // 壁に沿った向きを計算
      let rotation = SCNVector3(
        atan2(normal.y, normal.z),
        atan2(-normal.x, sqrt(normal.y * normal.y + normal.z * normal.z)),
        0  // Z軸の回転は0に固定
      )

      // 位置と向きを設定
      canvasNode.position = center
      canvasNode.eulerAngles = rotation

      node.addChildNode(canvasNode)
      self.canvasNode = canvasNode
    }

    // キャンバスを作成するメソッド
    func createCanvas() -> SCNNode {
      let canvas = SCNPlane(width: 0.6, height: 0.6)

      // キャンバスの背景
      let backgroundMaterial = SCNMaterial()
      backgroundMaterial.diffuse.contents = UIImage(resource: .canvas)
      backgroundMaterial.transparency = 1
      backgroundMaterial.isDoubleSided = true
      backgroundMaterial.writesToDepthBuffer = true
      backgroundMaterial.readsFromDepthBuffer = true

      // 画像を表示するための平面
      let imagePlane = SCNPlane(width: 0.5, height: 0.5)  // キャンバスより少し小さく
      let imageMaterial = SCNMaterial()

      if let image = image {
        updateImagePlane(imagePlane, with: image)
        imageMaterial.diffuse.contents = image
      }
      imageMaterial.isDoubleSided = true
      imageMaterial.writesToDepthBuffer = true
      imageMaterial.readsFromDepthBuffer = true

      // 背景と画像の平面を組み合わせる
      let backgroundNode = SCNNode(geometry: canvas)
      backgroundNode.geometry?.materials = [backgroundMaterial]

      let imageNode = SCNNode(geometry: imagePlane)
      imageNode.geometry?.materials = [imageMaterial]

      // 画像を背景の前面に配置
      imageNode.position = SCNVector3(0, 0, 0.001)  // わずかに前面に配置

      backgroundNode.addChildNode(imageNode)
      self.imageNode = imageNode  // 画像ノードを保持
      return backgroundNode
    }

    // 画像を更新するメソッド
    func replaceImage(with newImage: UIImage) {
      self.image = newImage
      // imageNodeがなければreturn
      guard let parent = imageNode?.parent else { return }
      // 新しいSCNPlaneを作成し、アスペクト比を更新
      let imagePlane = SCNPlane(width: 0.5, height: 0.5)
      updateImagePlane(imagePlane, with: newImage)
      let imageMaterial = SCNMaterial()
      imageMaterial.diffuse.contents = newImage
      imageMaterial.isDoubleSided = true
      imageMaterial.writesToDepthBuffer = true
      imageMaterial.readsFromDepthBuffer = true
      imagePlane.materials = [imageMaterial]
      // 新しいノードを作成
      let newNode = SCNNode(geometry: imagePlane)
      newNode.position = SCNVector3(0, 0, 0.001)
      // 古いノードを削除して新しいノードを追加
      parent.childNodes.forEach { $0.removeFromParentNode() }
      parent.addChildNode(newNode)
      self.imageNode = newNode
    }

    // 画像のアスペクト比に合わせて平面のサイズを更新するヘルパーメソッド
    private func updateImagePlane(_ plane: SCNPlane, with image: UIImage) {
      let imageAspect = image.size.width / image.size.height
      let planeAspect = plane.width / plane.height

      if imageAspect > planeAspect {
        // 画像が横長の場合
        plane.width = 0.5
        plane.height = 0.5 / imageAspect
      } else {
        // 画像が縦長の場合
        plane.height = 0.5
        plane.width = 0.5 * imageAspect
      }
    }
  }

  struct ExhibitionDetailARViewContainer: View {
    let photos: [Photo]
    let imageCache: any StorageImageCacheProtocol

    @State private var currentIndex: Int = 0
    @State private var currentImage: UIImage?
    @State private var isLoading: Bool = false

    var body: some View {
      ZStack {
        ExhibitionDetailARView(image: currentImage)
          .toolbar {
            ToolbarItem(placement: .bottomBar) {
              HStack {
                Button(action: showPrevious) {
                  Image(systemName: "chevron.backward")
                    .font(.body)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("Backward")
                }
                .disabled(photos.count <= 1)
                Spacer()
                Button(action: showNext) {
                  Image(systemName: "chevron.forward")
                    .font(.body)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("Forward")
                }
                .disabled(photos.count <= 1)
              }
            }
          }
          .ignoresSafeArea()

        if isLoading {
          ProgressView()
        }
      }
      .onAppear { loadImage(for: currentIndex) }
      .onChange(of: currentIndex) { _, index in loadImage(for: index) }
    }

    private func loadImage(for index: Int) {
      guard photos.indices.contains(index), let path = photos[index].imagePath else { return }
      isLoading = true
      Task {
        defer { isLoading = false }
        do {
          let url = try await imageCache.getImageURL(for: path)
          if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            currentImage = image
          } else {
            currentImage = nil
          }
        } catch {
          currentImage = nil
        }
      }
    }

    private func showPrevious() {
      guard !photos.isEmpty else { return }
      currentIndex = (currentIndex - 1 + photos.count) % photos.count
    }

    private func showNext() {
      guard !photos.isEmpty else { return }
      currentIndex = (currentIndex + 1) % photos.count
    }
  }

  struct ExhibitionDetailARView: UIViewControllerRepresentable {
    let image: UIImage?

    func makeUIViewController(context: Context) -> ExhibitionDetailARViewController {
      let vc = ExhibitionDetailARViewController()
      vc.image = image
      return vc
    }

    func updateUIViewController(
      _ uiViewController: ExhibitionDetailARViewController, context: Context
    ) {
      if let image = image {
        uiViewController.replaceImage(with: image)
      }
    }
  }

#endif
