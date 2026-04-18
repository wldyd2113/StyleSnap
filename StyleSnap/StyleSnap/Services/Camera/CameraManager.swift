import Foundation
import AVFoundation
import UIKit
import Combine // Published 사용을 위해 필수

protocol CameraManagerDelegate: AnyObject {
    func didCaptureFrame(_ pixelBuffer: CVPixelBuffer) // UIImage 대신 Buffer로 변경
}

final class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    weak var delegate: CameraManagerDelegate?
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private var lastAnalyzedTime: Date = Date()
    private let analysisInterval: TimeInterval = 1.0
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.startSession() }
            }
        default:
            print("DEBUG: Camera permission denied")
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        
        session.addInput(input)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.video.queue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.session.stopRunning()
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        guard now.timeIntervalSince(lastAnalyzedTime) >= analysisInterval else { return }
        lastAnalyzedTime = now
        
        // Zero-copy: Buffer를 직접 추출하여 델리게이트로 전달
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        delegate?.didCaptureFrame(pixelBuffer)
    }
}
