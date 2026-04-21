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
    nonisolated private static let context = CIContext(options: [.useSoftwareRenderer: false])
    
    private var currentXOffset: Float = 0.0
    private let spreadStep: Float = 0.15
    
    // 드래그 안정화를 위한 변수
    private var draggingNode: SCNNode? = nil
    private var lastStableY: Float = 0.0
    
    @MainActor
    func setupAR() {
        startSession(reset: true)
        setupGestures()
    }
    
    @MainActor
    func startSession(reset: Bool = false) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = false
        
        let options: ARSession.RunOptions = reset ? [.resetTracking, .removeExistingAnchors] : []
        sceneView?.session.run(configuration, options: options)
        sceneView?.autoenablesDefaultLighting = false
    }
    
    @MainActor
    func pauseSession() {
        sceneView?.session.pause()
    }
    
    // [핵심 수정] 사진 방향 전환 (90도 회전)
    // 사진이 세로로 있으면 가로로, 가로로 있으면 세로로 돌려줍니다.
    func rotate90Degrees() {
        guard let node = selectedNode else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        // 평면 사진의 회전은 Z축을 기준으로 돌려야 우리가 원하는 가로세로 전환이 됩니다.
        node.eulerAngles.z += .pi / 2
        SCNTransaction.commit()
    }
    
    func deleteSelectedNode() {
        guard let node = selectedNode else { return }
        node.removeFromParentNode()
        selectedNode = nil
    }

    private func setupGestures() {
        guard let sceneView = sceneView else { return }
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let sceneView = sceneView else { return }
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        if let node = hitResults.first(where: { $0.node.name == "clothing" })?.node {
            selectNode(node)
        } else {
            deselectAll()
        }
    }
    
    private func selectNode(_ node: SCNNode) {
        selectedNode?.opacity = 1.0
        selectedNode = node
        node.opacity = 0.7 
    }
    
    private func deselectAll() {
        selectedNode?.opacity = 1.0
        selectedNode = nil
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView = sceneView else { return }
        let location = gesture.location(in: sceneView)
        
        switch gesture.state {
        case .began:
            let hitResults = sceneView.hitTest(location, options: nil)
            draggingNode = hitResults.first(where: { $0.node.name == "clothing" })?.node
            if let node = draggingNode {
                selectNode(node)
                lastStableY = node.simdWorldPosition.y
            }
            
        case .changed:
            guard let node = draggingNode else { return }
            let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            if let query = query, let result = sceneView.session.raycast(query).first {
                let newPos = result.worldTransform.columns.3
                node.simdWorldPosition = simd_float3(newPos.x, newPos.y + 0.02, newPos.z) // 약간 띄워서 겹침 방지
                lastStableY = newPos.y + 0.02
            } else {
                // 바닥 인식이 안 되면 현재 높이 유지하며 이동
                let unprojected = sceneView.unprojectPoint(SCNVector3(Float(location.x), Float(location.y), 0.99))
                node.simdWorldPosition = simd_float3(unprojected.x, lastStableY, unprojected.z)
            }
            
        case .ended, .cancelled:
            draggingNode = nil
        default:
            break
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let sceneView = sceneView else { return }
        let hitResults = sceneView.hitTest(gesture.location(in: sceneView), options: nil)
        if let node = hitResults.first(where: { $0.node.name == "clothing" })?.node {
            let scale = Float(gesture.scale)
            if gesture.state == .changed {
                let newScale = node.scale.x * scale
                if newScale > 0.2 && newScale < 4.0 {
                    node.scale = SCNVector3(newScale, newScale, newScale)
                }
                gesture.scale = 1.0
            }
        }
    }
    
    @MainActor
    func placeClothing(item: ClothingItem) async -> Bool {
        guard let sceneView = sceneView else { return false }
        
        var finalImage: UIImage? = Self.processedImageCache[item.id]
        if finalImage == nil {
            finalImage = await Task<UIImage?, Never>.detached(priority: .userInitiated) {
                autoreleasepool {
                    guard let data = item.imageData, var img = UIImage(data: data) else { return nil }
                    img = Self.downscaleImage(img, maxDimension: 512)
                    return Self.removeBackgroundSync(from: img)
                }
            }.value
            if let img = finalImage { Self.processedImageCache[item.id] = img }
        }
        
        guard let readyImage = finalImage else { return false }
        
        let node = createClothingNode(with: readyImage, category: item.category)
        
        // 가로 오프셋
        let xPos = currentXOffset
        currentXOffset += spreadStep
        if currentXOffset > 0.45 { currentXOffset = -0.45 }
        
        // [핵심] 사용자가 보고 있는 정면 바닥 기준 배치
        if let cameraTransform = sceneView.session.currentFrame?.camera.transform {
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.7 // 70cm 앞에 배치
            translation.columns.3.x = xPos
            let placementTransform = matrix_multiply(cameraTransform, translation)
            
            node.simdWorldPosition = simd_float3(placementTransform.columns.3.x, placementTransform.columns.3.y, placementTransform.columns.3.z)
            
            // [핵심] 사진이 사용자를 정면으로 바라보게 설정 (수직 배치)
            node.eulerAngles.y = sceneView.session.currentFrame?.camera.eulerAngles.y ?? 0
        }
        
        // eulerAngles.x = 0 이면 수직으로 서 있는 상태입니다.
        node.eulerAngles.x = 0 
        
        sceneView.scene.rootNode.addChildNode(node)
        selectNode(node)
        return true
    }
    
    nonisolated private static func downscaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        let newSize = size.width > size.height ? 
            CGSize(width: maxDimension, height: maxDimension / aspectRatio) :
            CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        if size.width <= maxDimension && size.height <= maxDimension { return image }
        return UIGraphicsImageRenderer(size: newSize).image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
    
    nonisolated private static func removeBackgroundSync(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let result = request.results?.first as? VNPixelBufferObservation else { return image }
            return applyMask(maskBuffer: result.pixelBuffer, to: image)
        } catch { return image }
    }
    
    nonisolated private static func applyMask(maskBuffer: CVPixelBuffer, to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let scaleX = ciImage.extent.width / maskImage.extent.width
        let scaleY = ciImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        guard let filter = CIFilter(name: "CIBlendWithMask") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        guard let outputImage = filter.outputImage, let outputCGImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: outputCGImage)
    }
    
    private func createClothingNode(with image: UIImage, category: String) -> SCNNode {
        let width: CGFloat = (category == "상의") ? 0.35 : 0.28
        let height: CGFloat = width * (image.size.height / image.size.width)
        let plane = SCNPlane(width: width, height: height)
        plane.cornerRadius = 0.01
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
