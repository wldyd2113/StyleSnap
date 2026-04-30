import Foundation
import CoreML
import Vision
import UIKit
import CoreImage

// MARK: - AI Analysis Result
struct AnalysisResult {
    let category: String
    let style: String
    let confidence: Float
    let embedding: [Float]?
}

final class FashionAIProcessor {
    static let shared = FashionAIProcessor()
    
    // [격리] AR 세션 보호를 위해 CPU 기반의 렌더러 사용
    private lazy var ciContext = CIContext(options: [
        .useSoftwareRenderer: true,
        .priorityRequestLow: true
    ])
    
    // [지연 로딩] 모델 인스턴스 캐싱 (필요할 때만 메모리에 로드)
    private lazy var classifierModel: VNCoreMLModel? = {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly // [핵심] AR 충돌 완전 차단
        guard let model = try? EfficientNetV2_Classifier(configuration: config).model else { return nil }
        return try? VNCoreMLModel(for: model)
    }()
    
    private lazy var clipEncoderModel: VNCoreMLModel? = {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly
        guard let model = try? CLIP_ImageEncoder(configuration: config).model else { return nil }
        return try? VNCoreMLModel(for: model)
    }()
    
    private init() {}
    
    // MARK: - Core Functions
    
    /// 배경 제거 (DeepLabV3 사용)
    func removeBackground(from image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        
        return await Task.detached(priority: .background) {
            autoreleasepool {
                do {
                    let config = MLModelConfiguration()
                    config.computeUnits = .cpuOnly
                    
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
                    
                    return self.applyMask(originalImage: cgImage, maskBuffer: maskBuffer)
                } catch {
                    return image
                }
            }
        }.value
    }
    
    /// 옷 분석 (카테고리 + CLIP 임베딩 특징 추출)
    func analyze(pixelBuffer: CVPixelBuffer) async -> AnalysisResult? {
        do {
            // 1. 카테고리 분류 (EfficientNetV2)
            guard let catVision = classifierModel else { return nil }
            let catRequest = VNCoreMLRequest(model: catVision)
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([catRequest])
            
            let topCategory = (catRequest.results as? [VNClassificationObservation])?.first
            let categoryName = mapIdentifierToKorean(topCategory?.identifier ?? "unknown")
            
            // 2. 패션 임베딩 추출 (CLIP)
            guard let clipVision = clipEncoderModel else { return nil }
            let clipRequest = VNCoreMLRequest(model: clipVision)
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([clipRequest])
            
            var finalEmbedding: [Float]? = nil
            if let clipResults = clipRequest.results as? [VNCoreMLFeatureValueObservation],
               let embeddingArray = clipResults.first?.featureValue.multiArrayValue {
                finalEmbedding = convertMultiArrayToArray(embeddingArray)
            }
            
            return AnalysisResult(
                category: categoryName,
                style: "미니멀", // 기본값 설정
                confidence: topCategory?.confidence ?? 0.0,
                embedding: finalEmbedding
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func applyMask(originalImage: CGImage, maskBuffer: CVPixelBuffer) -> UIImage {
        let originalCI = CIImage(cgImage: originalImage)
        let maskCI = CIImage(cvPixelBuffer: maskBuffer)
        
        let scaleX = originalCI.extent.width / maskCI.extent.width
        let scaleY = originalCI.extent.height / maskCI.extent.height
        let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            .applyingFilter("CIColorThreshold", parameters: ["inputThreshold": 0.1])
        
        guard let filter = CIFilter(name: "CIBlendWithMask") else { return UIImage(cgImage: originalImage) }
        filter.setValue(originalCI, forKey: kCIInputImageKey)
        filter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        filter.setValue(CIImage(color: .clear).cropped(to: originalCI.extent), forKey: kCIInputBackgroundImageKey)
        
        if let outputCI = filter.outputImage,
           let finalCG = self.ciContext.createCGImage(outputCI, from: originalCI.extent) {
            return UIImage(cgImage: finalCG)
        }
        return UIImage(cgImage: originalImage)
    }
    
    private func convertMultiArrayToArray(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        var array = [Float](repeating: 0, count: count)
        let ptr = UnsafeMutablePointer<Float>(OpaquePointer(multiArray.dataPointer))
        for i in 0..<count { array[i] = ptr[i] }
        return array
    }
    
    private func mapIdentifierToKorean(_ id: String) -> String {
        let lowerID = id.lowercased()
        if lowerID.contains("pants") || lowerID.contains("bottom") { return "하의" }
        if lowerID.contains("shirt") || lowerID.contains("top") { return "상의" }
        if lowerID.contains("shoes") || lowerID.contains("sneakers") { return "신발" }
        return "의류"
    }
}
