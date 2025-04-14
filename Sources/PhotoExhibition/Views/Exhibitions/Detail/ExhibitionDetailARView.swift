#if !SKIP
  @preconcurrency import ARKit
  import UIKit
  import SceneKit
  import SwiftUI

  extension SCNNode: @unchecked @retroactive Sendable {}

  final class ExhibitionDetailARViewController: UIViewController,
    ARSCNViewDelegate
  {

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
      let canvas = SCNPlane(width: 1, height: 1)  // 1m四方のキャンバス

      let material = SCNMaterial()
      material.diffuse.contents = UIColor.white  // フィルターカラーを白色にする（透明な場合はUIColor.clear）
      material.transparency = 1
      material.isDoubleSided = true
      material.writesToDepthBuffer = true  // 深度バッファへの書き込みを有効化
      material.readsFromDepthBuffer = true  // 深度バッファからの読み込みを有効化

      canvas.materials = [material]

      let boxNode = SCNNode(geometry: canvas)
      return boxNode
    }
  }

  struct ExhibitionDetailARView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context)
      -> ExhibitionDetailARViewController
    {
      return ExhibitionDetailARViewController()
    }

    func updateUIViewController(
      _ uiViewController: ExhibitionDetailARViewController,
      context: Context
    ) {}
  }

#endif
