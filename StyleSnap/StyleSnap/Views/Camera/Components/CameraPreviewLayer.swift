import SwiftUI
import AVFoundation

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 세션 업데이트가 필요한 경우 처리
        if uiView.videoPreviewLayer.session != session {
            uiView.videoPreviewLayer.session = session
        }
    }
    
    // UIView를 서브클래싱하여 레이아웃 서브뷰 갱신 시 프레임을 맞춤
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // 이 부분이 있어야 기기 회전이나 SwiftUI 레이아웃 변화 시 카메라 화면이 꽉 참
            videoPreviewLayer.frame = self.bounds
        }
    }
}
