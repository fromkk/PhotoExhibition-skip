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
        sceneView.showsStatistics = true
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
      guard let imageNode = imageNode,
        let imagePlane = imageNode.geometry as? SCNPlane
      else {
        return
      }

      // 画像のアスペクト比に合わせて平面のサイズを更新
      updateImagePlane(imagePlane, with: newImage)

      // マテリアルの画像を更新
      if let material = imagePlane.materials.first {
        material.diffuse.contents = newImage
      }
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

  struct ExhibitionDetailARView: UIViewControllerRepresentable {
    let photos: [Photo]
    let imageCache: any StorageImageCacheProtocol

    func makeUIViewController(context: Context) -> ExhibitionDetailARViewController {
      ExhibitionDetailARViewController()
    }

    func updateUIViewController(
      _ uiViewController: ExhibitionDetailARViewController,
      context: Context
    ) {
      guard let first = photos.first, let path = first.imagePath else { return }
      Task {
        do {
          let url = try await imageCache.getImageURL(for: path)
          if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            uiViewController.replaceImage(with: image)
          }
        } catch {
          // エラー時は何もしない
        }
      }
    }
  }

#endif
