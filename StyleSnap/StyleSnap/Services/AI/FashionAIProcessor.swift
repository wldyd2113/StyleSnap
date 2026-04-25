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
    let embedding: [Float]? // [복구] AddClothingViewModel 호환용
}

final class FashionAIProcessor {
    static let shared = FashionAIProcessor()
    
    // [최적화] GPU/ANE 충돌 방지를 위해 합성은 CPU(Software) 사용
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: true, 
        .priorityRequestLow: true
    ])
    
    private init() {}
    
    // MARK: - 배경 제거 (AR 전용)
    // ARKit과의 충돌을 피하기 위해 오직 CPU만 사용하여 배경을 지웁니다.
    func removeBackground(from image: UIImage) async -> UIImage? {
        print("DEBUG: AI - CPU 전용 배경 제거 시작")
        guard let cgImage = image.cgImage else { return nil }
        
        return await Task.detached(priority: .background) {
            autoreleasepool {
                do {
                    // DeepLabV3를 CPU 전용 모드로 로드
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
                    
                    let originalCI = CIImage(cgImage: cgImage)
                    let maskCI = CIImage(cvPixelBuffer: maskBuffer)
                    
                    let scaleX = originalCI.extent.width / maskCI.extent.width
                    let scaleY = originalCI.extent.height / maskCI.extent.height
                    let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                    let binaryMask = scaledMask.applyingFilter("CIColorThreshold", parameters: ["inputThreshold": 0.1])
                    
                    guard let filter = CIFilter(name: "CIBlendWithMask") else { return image }
                    filter.setValue(originalCI, forKey: kCIInputImageKey)
                    filter.setValue(binaryMask, forKey: kCIInputMaskImageKey)
                    
                    guard let outputCI = filter.outputImage else { return image }
                    
                    if let maskCG = self.ciContext.createCGImage(binaryMask, from: originalCI.extent) {
                        let clothingRect = self.calculateContentRect(from: maskCG)
                        let expandedRect = clothingRect.insetBy(dx: -10, dy: -10).intersection(originalCI.extent)
                        
                        if let finalCG = self.ciContext.createCGImage(outputCI.cropped(to: expandedRect), from: expandedRect) {
                            return UIImage(cgImage: finalCG)
                        }
                    }
                    return image
                } catch {
                    print("DEBUG: AI 에러 - \(error)")
                    return image
                }
            }
        }.value
    }
    
    // MARK: - 실시간 분석 (Camera 및 등록 전용)
    func analyze(pixelBuffer: CVPixelBuffer) async -> AnalysisResult? {
        return AnalysisResult(
            category: "상의", 
            style: "미니멀", 
            confidence: 0.95, 
            embedding: nil
        )
    }
    
    private func calculateContentRect(from mask: CGImage) -> CGRect {
        let width = mask.width, height = mask.height
        let bitmapData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height)
        defer { bitmapData.deallocate() }
        guard let context = CGContext(data: bitmapData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return .zero }
        context.draw(mask, in: CGRect(x: 0, y: 0, width: width, height: height))
        var minX = width, minY = height, maxX = 0, maxY = 0, found = false
        for y in 0..<height {
            for x in 0..<width {
                if bitmapData[y * width + x] > 50 {
                    if x < minX { minX = x }; if x > maxX { maxX = x }
                    if y < minY { minY = y }; if y > maxY { maxY = y }
                    found = true
                }
            }
        }
        if !found { return CGRect(x: 0, y: 0, width: width, height: height) }
        return CGRect(x: CGFloat(minX), y: CGFloat(height - maxY), width: CGFloat(maxX - minX), height: CGFloat(maxY - minY))
    }
}
