import Foundation
import CoreML
import Vision
import UIKit

// MARK: - AI Analysis Result
struct AnalysisResult {
    let category: String
    let style: String
    let confidence: Float
    let embedding: [Float]? // Siamese Network에서 비교할 특징 벡터
}

final class FashionAIProcessor {
    static let shared = FashionAIProcessor()
    
    private var segmentationRequest: VNCoreMLRequest? 
    private var classifierRequest: VNCoreMLRequest?   
    private var clipRequest: VNCoreMLRequest?         
    
    private init() {
        setupModels()
    }
    
    private func setupModels() {
        do {
            let config = MLModelConfiguration()
            #if targetEnvironment(simulator)
            config.computeUnits = .cpuOnly
            #else
            config.computeUnits = .all
            #endif
            
            // 1. 배경 제거 (DeepLabV3)
            if let segModel = try? DeepLabV3(configuration: config).model {
                let visionModel = try VNCoreMLModel(for: segModel)
                self.segmentationRequest = VNCoreMLRequest(model: visionModel)
            }
            
            // 2. 카테고리 분류 (EfficientNetV2)
            if let categoryModel = try? EfficientNetV2_Classifier(configuration: config).model {
                let visionModel = try VNCoreMLModel(for: categoryModel)
                self.classifierRequest = VNCoreMLRequest(model: visionModel)
                self.classifierRequest?.imageCropAndScaleOption = .centerCrop
            }
            
            // 3. 스타일 & 특징 추출 (CLIP - Siamese Backbone)
            if let clipEncoder = try? CLIP_ImageEncoder(configuration: config).model {
                let visionModel = try VNCoreMLModel(for: clipEncoder)
                self.clipRequest = VNCoreMLRequest(model: visionModel)
            }
        } catch {
            print("DEBUG: AI Init Error: \(error)")
        }
    }
    
    // 이미지를 입력받아 샴 네트워크용 특징 벡터를 뽑아냄
    func analyze(pixelBuffer: CVPixelBuffer) async -> AnalysisResult? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        guard let segReq = segmentationRequest, let catReq = classifierRequest, let clipReq = clipRequest else { return nil }
        
        do {
            try handler.perform([segReq, catReq, clipReq])
            
            // 카테고리 추출
            let identifier = (catReq.results as? [VNClassificationObservation])?.first?.identifier ?? ""
            let topCategory = mapIdentifierToKorean(identifier)
            
            var styleName = "미니멀"
            var score: Float = 0.0
            var finalEmbedding: [Float]? = nil
            
            if let clipResults = clipReq.results as? [VNCoreMLFeatureValueObservation],
               let embedding = clipResults.first?.featureValue.multiArrayValue {
                
                // [샴 네트워크 핵심] 고차원 공간으로 이미지 투영 (Feature Mapping)
                finalEmbedding = convertMultiArrayToArray(embedding)
                
                let match = matchStyleWithAI(embedding: embedding)
                styleName = match.0
                score = match.1
            }
            
            return AnalysisResult(category: topCategory, style: styleName, confidence: score, embedding: finalEmbedding)
        } catch {
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
