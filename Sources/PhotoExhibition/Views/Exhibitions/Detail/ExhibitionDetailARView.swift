#if !SKIP
  import ARKit
  import UIKit
  import SceneKit
  import SwiftUI

  @MainActor
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
      configuration.planeDetection = [.horizontal, .vertical]  // 垂直と水平の平面検出を有効にする

      // Run the view's session
      sceneView.session.run(configuration)
    }

    // MARK: - ARSCNViewDelegate

    nonisolated func renderer(
      _ renderer: SCNSceneRenderer,
      didAdd node: SCNNode,
      for anchor: ARAnchor
    ) {
      if let planeAnchor = anchor as? ARPlaneAnchor {
        switch planeAnchor.alignment {  // 平面の方向性を確認
        case .horizontal:
          print("Found a floor/ceiling")
        case .vertical:
          print("Found a wall")

          // 壁を見つけたら、何らかのアクションを取る
          let box = SCNBox(
            width: CGFloat(planeAnchor.planeExtent.width),
            height: 0.001,
            length: CGFloat(planeAnchor.planeExtent.height),
            chamferRadius: 0
          )

          let material = SCNMaterial()
          material.diffuse.contents = UIColor.green

          box.materials = [material]

          let boxNode = SCNNode(geometry: box)
          boxNode.position = SCNVector3(
            planeAnchor.center.x,
            planeAnchor.center.y,
            planeAnchor.center.z
          )

          node.addChildNode(boxNode)  // シーンに追加
        @unknown default:
          fatalError()
        }
      }
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
