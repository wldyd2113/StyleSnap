import ARKit
import SceneKit
import SwiftUI
import Vision
import Combine

@MainActor
class ARCoordinator: NSObject, ARSCNViewDelegate, ObservableObject {
    var sceneView: ARSCNView?
    @Published var selectedNode: SCNNode? = nil
    
    private static var processedImageCache: [String: UIImage] = [:]
    private var currentXOffset: Float = 0.0
    private let spreadStep: Float = 0.15
    private var draggingNode: SCNNode? = nil
    private var lastStableY: Float = 0.0
    
    @MainActor func setupAR() { 
        startSession(reset: true)
        setupGestures() 
    }
    
    // [복구] AROOTDView에서 호출하는 세션 시작 메서드
    @MainActor func startSession(reset: Bool = false) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = false
        
        let options: ARSession.RunOptions = reset ? [.resetTracking, .removeExistingAnchors] : []
        sceneView?.session.run(configuration, options: options)
    }
    
    // [복구] AROOTDView에서 호출하는 세션 중지 메서드
    @MainActor func pauseSession() { 
        sceneView?.session.pause() 
    }
    
    // [복구] 사진 90도 회전 기능
    func rotate90Degrees() {
        guard let node = selectedNode else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        node.eulerAngles.z += .pi / 2
        SCNTransaction.commit()
    }
    
    func deleteSelectedNode() { 
        selectedNode?.removeFromParentNode()
        selectedNode = nil 
    }

    private func setupGestures() {
        guard let sceneView = sceneView else { return }
        sceneView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        sceneView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let sceneView = sceneView else { return }
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        if let node = hitResults.first(where: { $0.node.name == "clothing" })?.node {
            selectedNode = node
        } else {
            selectedNode = nil
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView = sceneView else { return }
        let location = gesture.location(in: sceneView)
        switch gesture.state {
        case .changed:
            guard let node = selectedNode else { return }
            let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            if let query = query, let result = sceneView.session.raycast(query).first {
                node.simdWorldPosition = simd_float3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y + 0.01, result.worldTransform.columns.3.z)
            }
        default: break
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let sceneView = sceneView else { return }
        if let node = sceneView.hitTest(gesture.location(in: sceneView), options: nil).first(where: { $0.node.name == "clothing" })?.node {
            let scale = Float(gesture.scale)
            node.scale = SCNVector3(node.scale.x * scale, node.scale.y * scale, node.scale.z * scale)
            gesture.scale = 1.0
        }
    }
    
    @MainActor
    func placeClothing(item: ClothingItem) async -> Bool {
        guard let sceneView = sceneView, let data = item.imageData, let img = UIImage(data: data) else { return false }
        
        var finalImage: UIImage? = Self.processedImageCache[item.id]
        
        if finalImage == nil {
            // [최적화 유지] CPU 전용 + 224px 해상도 축소로 충돌 방지
            finalImage = await Task.detached(priority: .background) {
                let size = CGSize(width: 224, height: 224 * (img.size.height / img.size.width))
                let downscaled = UIGraphicsImageRenderer(size: size).image { _ in img.draw(in: CGRect(origin: .zero, size: size)) }
                return await FashionAIProcessor.shared.removeBackground(from: downscaled)
            }.value
            
            if let processed = finalImage { Self.processedImageCache[item.id] = processed }
        }
        
        guard let readyImage = finalImage else { return false }
        let node = createNode(with: readyImage)
        
        let xPos = currentXOffset
        currentXOffset += 0.2
        if currentXOffset > 0.4 { currentXOffset = -0.4 }
        
        if let frame = sceneView.session.currentFrame {
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -1.0; translation.columns.3.x = xPos
            let transform = matrix_multiply(frame.camera.transform, translation)
            node.simdWorldPosition = simd_float3(transform.columns.3.x, -0.1, transform.columns.3.z)
            node.eulerAngles.y = frame.camera.eulerAngles.y
        }
        
        sceneView.scene.rootNode.addChildNode(node)
        selectedNode = node
        return true
    }
    
    private func createNode(with image: UIImage) -> SCNNode {
        let plane = SCNPlane(width: 0.4, height: 0.4 * (image.size.height / image.size.width))
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = true
        material.lightingModel = .constant
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        node.name = "clothing"
        return node
    }
}
