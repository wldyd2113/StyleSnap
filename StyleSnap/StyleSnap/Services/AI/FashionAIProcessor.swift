import Foundation
import CoreML
import Vision
import UIKit
import CoreImage

struct AnalysisResult {
    let category: String
    let style: String
    let confidence: Float
    let embedding: [Float]?
}

final class FashionAIProcessor {
    static let shared = FashionAIProcessor()
    
    // [격리] GPU를 전혀 쓰지 않는 순수 CPU 렌더러
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: true,
        .priorityRequestLow: true
    ])
    
    private init() {}
    
    // [최종 안정화] DeepLabV3 + CPU Only 모드
    func removeBackground(from image: UIImage) async -> UIImage? {
        print("DEBUG: AI - 초경량 CPU 모드 시작")
        guard let cgImage = image.cgImage else { return image }
        
        return await Task.detached(priority: .background) {
            autoreleasepool {
                do {
                    let config = MLModelConfiguration()
                    config.computeUnits = .cpuOnly // [핵심] AR 충돌 완전 차단
                    
                    let model = try DeepLabV3(configuration: config).model
                    let visionModel = try VNCoreMLModel(for: model)
                    let request = VNCoreMLRequest(model: visionModel)
                    request.imageCropAndScaleOption = .scaleFill
                    
                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try handler.perform([request])
                    
                    guard let observations = request.results as? [VNPixelBufferObservation],
                          let maskBuffer = observations.first?.pixelBuffer else {
                        return image
                    }
                    
                    let originalCI = CIImage(cgImage: cgImage)
                    let maskCI = CIImage(cvPixelBuffer: maskBuffer)
                    
                    let scaleX = originalCI.extent.width / maskCI.extent.width
                    let scaleY = originalCI.extent.height / maskCI.extent.height
                    let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                        .applyingFilter("CIColorThreshold", parameters: ["inputThreshold": 0.1])
                    
                    guard let filter = CIFilter(name: "CIBlendWithMask") else { return image }
                    filter.setValue(originalCI, forKey: kCIInputImageKey)
                    filter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
                    filter.setValue(CIImage(color: .clear).cropped(to: originalCI.extent), forKey: kCIInputBackgroundImageKey)
                    
                    if let outputCI = filter.outputImage,
                       let finalCG = self.ciContext.createCGImage(outputCI, from: originalCI.extent) {
                        print("DEBUG: AI - 초경량 처리 성공")
                        return UIImage(cgImage: finalCG)
                    }
                    return image
                } catch {
                    return image
                }
            }
        }.value
    }
    
    func analyze(pixelBuffer: CVPixelBuffer) async -> AnalysisResult? {
        return AnalysisResult(category: "상의", style: "미니멀", confidence: 0.95, embedding: nil)
    }
}
