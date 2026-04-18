import UIKit
import VideoToolbox

extension UIImage {
    /// UIImage를 CVPixelBuffer로 변환
    func toPixelBuffer() -> CVPixelBuffer? {
        let width = self.size.width
        let height = self.size.height
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, 
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, .init(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0)) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: pixelData, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        
        return buffer
    }
    
    /// CVPixelBuffer를 UIImage로 변환 (추가된 기능)
    static func from(pixelBuffer: CVPixelBuffer) -> UIImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        guard let cgImage = cgImage else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}
