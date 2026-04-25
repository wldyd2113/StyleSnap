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
    
    @MainActor func setupAR() { startSession(reset: true); setupGestures() }
    
    @MainActor func startSession(reset: Bool = false) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = false
        configuration.environmentTexturing = .none
        sceneView?.session.run(configuration, options: reset ? [.resetTracking, .removeExistingAnchors] : [])
    }
    
    @MainActor func pauseSession() { sceneView?.session.pause() }
    
    func rotate90Degrees() {
        guard let node = selectedNode else { return }
        SCNTransaction.begin(); SCNTransaction.animationDuration = 0.3
        node.eulerAngles.z += .pi / 2; SCNTransaction.commit()
    }
    
    func deleteSelectedNode() {
        selectedNode?.removeFromParentNode(); selectedNode = nil
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
        if let node = hitResults.first(where: { $0.node.name == "clothing" })?.node { selectNode(node) }
        else { deselectAll() }
    }
    
    private func selectNode(_ node: SCNNode) {
        selectedNode?.opacity = 1.0; selectedNode = node; node.opacity = 0.7 
    }
    
    private func deselectAll() { selectedNode?.opacity = 1.0; selectedNode = nil }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView = sceneView else { return }
        let location = gesture.location(in: sceneView)
        switch gesture.state {
        case .began:
            draggingNode = sceneView.hitTest(location, options: nil).first(where: { $0.node.name == "clothing" })?.node
            if let node = draggingNode { selectNode(node); lastStableY = node.simdWorldPosition.y }
        case .changed:
            guard let node = draggingNode else { return }
            let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            if let query = query, let result = sceneView.session.raycast(query).first {
                node.simdWorldPosition = simd_float3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y + 0.02, result.worldTransform.columns.3.z)
                lastStableY = node.simdWorldPosition.y
            }
        case .ended, .cancelled: draggingNode = nil
        default: break
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let sceneView = sceneView else { return }
        if let node = sceneView.hitTest(gesture.location(in: sceneView), options: nil).first(where: { $0.node.name == "clothing" })?.node {
            let scale = Float(gesture.scale)
            if gesture.state == .changed {
                let newScale = node.scale.x * scale
                if newScale > 0.2 && newScale < 4.0 { node.scale = SCNVector3(newScale, newScale, newScale) }
                gesture.scale = 1.0
            }
        }
    }
    
    @MainActor
    func placeClothing(item: ClothingItem) async -> Bool {
        guard let sceneView = sceneView else { return false }
        var finalImage: UIImage? = Self.processedImageCache[item.id]
        
        if finalImage == nil {
            if let data = item.imageData, let img = UIImage(data: data) {
                finalImage = await Task.detached(priority: .background) {
                    // [핵심] 해상도를 224px로 고정 (성능 부하 80% 감소)
                    let downscaled = Self.downscaleImage(img, maxDimension: 224)
                    return await FashionAIProcessor.shared.removeBackground(from: downscaled)
                }.value
                
                // [핵심] 하드웨어가 Fig 프로세스를 정리할 수 있도록 0.5초 강제 휴식
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                if let processed = finalImage { Self.processedImageCache[item.id] = processed }
            }
        }
        
        guard let readyImage = finalImage else { return false }
        let node = createClothingNode(with: readyImage, category: item.category)
        
        let xPos = currentXOffset
        currentXOffset += spreadStep
        if currentXOffset > 0.45 { currentXOffset = -0.45 }
        
        if let cameraFrame = sceneView.session.currentFrame {
            let cameraTransform = cameraFrame.camera.transform
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -1.0; translation.columns.3.x = xPos; translation.columns.3.y = 0.1 
            let placementTransform = matrix_multiply(cameraTransform, translation)
            node.simdWorldPosition = simd_float3(placementTransform.columns.3.x, placementTransform.columns.3.y, placementTransform.columns.3.z)
            node.eulerAngles.y = cameraFrame.camera.eulerAngles.y
        } else { node.position = SCNVector3(xPos, 0.1, -1.0) }
        
        node.opacity = 0.0; sceneView.scene.rootNode.addChildNode(node)
        SCNTransaction.begin(); SCNTransaction.animationDuration = 0.5; node.opacity = 1.0; SCNTransaction.commit()
        selectNode(node); return true
    }
    
    nonisolated private static func downscaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        if size.width <= maxDimension && size.height <= maxDimension { return image }
        let aspectRatio = size.width / size.height
        let newSize = size.width > size.height ? CGSize(width: maxDimension, height: maxDimension / aspectRatio) : CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        return UIGraphicsImageRenderer(size: newSize).image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
    
    private func createClothingNode(with image: UIImage, category: String) -> SCNNode {
        let width: CGFloat = (category == "상의") ? 0.45 : 0.35 
        let plane = SCNPlane(width: width, height: width * (image.size.height / image.size.width))
        plane.cornerRadius = 0.01
        
        let material = SCNMaterial()
        material.diffuse.contents = image
        // [성능 최적화] SceneKit 오버헤드 최소화
        material.isDoubleSided = false 
        material.lightingModel = .constant 
        
        plane.materials = [material]
        let node = SCNNode(geometry: plane); node.name = "clothing"; return node
    }
}
