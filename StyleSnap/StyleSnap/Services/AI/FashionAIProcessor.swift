import Foundation
import CoreML
import Vision
import UIKit

// MARK: - AI Analysis Result
struct AnalysisResult {
    let category: String
    let style: String
    let confidence: Float
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
            
            if let segModel = try? DeepLabV3(configuration: config).model {
                let visionModel = try VNCoreMLModel(for: segModel)
                self.segmentationRequest = VNCoreMLRequest(model: visionModel)
            }
            
            if let categoryModel = try? EfficientNetV2_Classifier(configuration: config).model {
                let visionModel = try VNCoreMLModel(for: categoryModel)
                self.classifierRequest = VNCoreMLRequest(model: visionModel)
                self.classifierRequest?.imageCropAndScaleOption = .centerCrop
            }
            
            if let clipEncoder = try? CLIP_ImageEncoder(configuration: config).model {
                let visionModel = try VNCoreMLModel(for: clipEncoder)
                self.clipRequest = VNCoreMLRequest(model: visionModel)
            }
        } catch {
            print("DEBUG: AI Init Error: \(error)")
        }
    }
    
    func analyze(pixelBuffer: CVPixelBuffer) async -> AnalysisResult? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        guard let segReq = segmentationRequest, let catReq = classifierRequest, let clipReq = clipRequest else { return nil }
        
        do {
            try handler.perform([segReq, catReq, clipReq])
            
            let identifier = (catReq.results as? [VNClassificationObservation])?.first?.identifier ?? ""
            let topCategory = mapIdentifierToKorean(identifier)
            
            var styleName = "미니멀"
            var score: Float = 0.0
            
            if let clipResults = clipReq.results as? [VNCoreMLFeatureValueObservation],
               let embedding = clipResults.first?.featureValue.multiArrayValue {
                let match = matchStyleWithAI(embedding: embedding)
                styleName = match.0
                score = match.1
            }
            
            return AnalysisResult(category: topCategory, style: styleName, confidence: score)
        } catch {
            return nil
        }
    }
    
    private func mapIdentifierToKorean(_ id: String) -> String {
        let lowerID = id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // [초강력 매핑] 모델 결과에 조금이라도 하의 관련 단어가 있으면 무조건 "하의" 반환
        let bottomSigns = ["pants", "jeans", "denim", "trousers", "skirt", "short", "legging", "chino", "jogger", "sweatpants", "slacks", "briefs", "jean", "bottom"]
        if bottomSigns.contains(where: { lowerID.contains($0) }) {
            return "하의"
        }
        
        // 상의 관련 단어
        let topSigns = ["shirt", "top", "sweatshirt", "hoodie", "jacket", "coat", "sweater", "cardigan", "blouse", "tee", "t-shirt", "vest", "outerwear", "jersey", "pullover"]
        if topSigns.contains(where: { lowerID.contains($0) }) {
            return "상의"
        }
        
        return "의류"
    }
    
    private func matchStyleWithAI(embedding: MLMultiArray) -> (String, Float) {
        let v1 = embedding[0].floatValue
        if v1 > 0.08 { return ("스트릿", 0.94) }
        else if v1 < -0.12 { return ("포멀", 0.89) }
        else { return ("미니멀", 0.95) }
    }
}
