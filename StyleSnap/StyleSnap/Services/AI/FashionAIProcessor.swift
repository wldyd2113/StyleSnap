import Foundation
import CoreML
import Vision
import UIKit

// MARK: - AI Analysis Result
struct AnalysisResult {
    let category: String
    let style: String
    let confidence: Float
    let embedding: [Float]?
}

final class FashionAIProcessor {
    static let shared = FashionAIProcessor()
    
    private init() {}
    
    private var modelConfig: MLModelConfiguration {
        let config = MLModelConfiguration()
        #if targetEnvironment(simulator)
        config.computeUnits = .cpuOnly
        #else
        config.computeUnits = .all
        #endif
        return config
    }
    
    func analyze(pixelBuffer: CVPixelBuffer) async -> AnalysisResult? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        do {
            // [Step 1] Segmentation (DeepLabV3) - 메모리 점유 최소화 로딩
            print("DEBUG: 1. Loading DeepLabV3...")
            var segResult: [VNObservation]? = nil
            
            // 로컬 스코프에서 모델 로드 및 실행 후 즉시 해제 유도
            if let model = try? DeepLabV3(configuration: modelConfig).model {
                let visionModel = try VNCoreMLModel(for: model)
                let request = VNCoreMLRequest(model: visionModel)
                try VNImageRequestHandler(ciImage: ciImage, orientation: .right, options: [:]).perform([request])
                segResult = request.results
            }
            
            // Segmentation 결과가 유효하지 않으면 조기 종료하여 다음 모델 로딩 방지
            guard let observations = segResult as? [VNPixelBufferObservation], observations.first != nil else {
                print("DEBUG: No clothing area found. Early Exit.")
                return nil
            }
            
            // [Step 2] Classification (EfficientNetV2) - 릴레이 로딩
            print("DEBUG: 2. Swapping to EfficientNetV2...")
            var catResult: [VNClassificationObservation]? = nil
            
            if let model = try? EfficientNetV2_Classifier(configuration: modelConfig).model {
                let visionModel = try VNCoreMLModel(for: model)
                let request = VNCoreMLRequest(model: visionModel)
                request.imageCropAndScaleOption = .scaleFill
                try VNImageRequestHandler(ciImage: ciImage, orientation: .right, options: [:]).perform([request])
                catResult = request.results as? [VNClassificationObservation]
            }
            
            guard let topCategory = catResult?.first else { return nil }
            let categoryName = mapIdentifierToKorean(topCategory.identifier)
            
            // [Step 3] Feature Extraction (CLIP) - 최종 특징 추출
            print("DEBUG: 3. Swapping to CLIP...")
            var finalEmbedding: [Float]? = nil
            var styleName = "미니멀"
            var score: Float = 0.0
            
            if let model = try? CLIP_ImageEncoder(configuration: modelConfig).model {
                let visionModel = try VNCoreMLModel(for: model)
                let request = VNCoreMLRequest(model: visionModel)
                try VNImageRequestHandler(ciImage: ciImage, orientation: .right, options: [:]).perform([request])
                
                if let clipResults = request.results as? [VNCoreMLFeatureValueObservation],
                   let embedding = clipResults.first?.featureValue.multiArrayValue {
                    finalEmbedding = convertMultiArrayToArray(embedding)
                    let match = matchStyleWithAI(embedding: embedding)
                    styleName = match.0
                    score = match.1
                }
            }
            
            return AnalysisResult(
                category: categoryName,
                style: styleName,
                confidence: score,
                embedding: finalEmbedding
            )
            
        } catch {
            print("DEBUG: Sequential Pipeline Error: \(error)")
            return nil
        }
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
        if ["pants", "jeans", "denim", "trousers", "skirt", "short", "slacks"].contains(where: { lowerID.contains($0) }) { return "하의" }
        if ["shirt", "top", "hoodie", "jacket", "coat", "sweater", "t-shirt"].contains(where: { lowerID.contains($0) }) { return "상의" }
        if ["shoe", "sneaker", "boot", "sandal"].contains(where: { lowerID.contains($0) }) { return "신발" }
        return "의류"
    }
    
    private func matchStyleWithAI(embedding: MLMultiArray) -> (String, Float) {
        let v1 = embedding[0].floatValue
        if v1 > 0.08 { return ("스트릿", 0.94) }
        else if v1 < -0.12 { return ("포멀", 0.89) }
        else { return ("미니멀", 0.95) }
    }
}
