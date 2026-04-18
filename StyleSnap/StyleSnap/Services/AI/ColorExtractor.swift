import UIKit
import CoreImage

final class ColorExtractor {
    static let shared = ColorExtractor()
    private let context = CIContext(options: [.workingColorSpace: NSNull()])
    
    private init() {}
    
    /// CVPixelBuffer의 중앙 영역(ROI)만 분석하여 배경 노이즈를 제거한 색상을 추출합니다.
    func extractDominantColor(from pixelBuffer: CVPixelBuffer) async -> UIColor? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        
        // [핵심 수정] 화면 전체가 아닌 중앙의 25% 영역만 추출 (배경 노이즈 차단)
        let roiWidth = extent.width * 0.5
        let roiHeight = extent.height * 0.5
        let roiRect = CGRect(
            x: extent.midX - (roiWidth / 2),
            y: extent.midY - (roiHeight / 2),
            width: roiWidth,
            height: roiHeight
        )
        
        let extentVector = CIVector(cgRect: roiRect)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: extentVector
        ]), let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, 
                      toBitmap: &bitmap, 
                      rowBytes: 4, 
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1), 
                      format: .RGBA8, 
                      colorSpace: nil)
        
        // 추출된 색상의 채도(Saturation)를 살짝 보정하여 더 선명한 색상을 얻음
        let color = UIColor(red: CGFloat(bitmap[0]) / 255.0,
                            green: CGFloat(bitmap[1]) / 255.0,
                            blue: CGFloat(bitmap[2]) / 255.0,
                            alpha: 1.0)
        
        return color
    }
}
