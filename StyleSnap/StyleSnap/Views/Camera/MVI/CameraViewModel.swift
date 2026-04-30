import Foundation
import UIKit
import Combine
import SwiftUI
import AVFoundation

// MARK: - MVI Components
enum CameraIntent {
    case checkPermissions
    case startAnalysis
    case stopAnalysis
    case capturePhoto
    case analyzePixelBuffer(CVPixelBuffer)
    case analyzeGalleryImage(UIImage)
    case resetToRealtime
    case provideFeedback(style: String, isLiked: Bool)
}

struct CameraState {
    var isRunning: Bool = false
    var isShowingResult: Bool = false 
    var currentCategory: String = "분석 준비 중..."
    var currentStyle: String = "스타일 분석 중..."
    var dominantColor: Color = .fashionGray
    var confidence: Float = 0.0
    var recommendations: [ColorRecommendation] = []
    var isRecommendationLoading: Bool = false
    var capturedImage: UIImage? = nil 
}

// MARK: - ViewModel
@MainActor
final class CameraViewModel: ObservableObject, CameraManagerDelegate {
    @Published private(set) var state = CameraState()
    
    // [자원 격리] 하드웨어 충돌 방지를 위해 지연 로딩 적용
    lazy var cameraManager: CameraManager = {
        let manager = CameraManager()
        manager.delegate = self
        return manager
    }()
    
    private let colorExtractor = ColorExtractor.shared
    private let coordinationService = CoordinationService.shared
    
    private var isAnalyzing = false
    private var lastBuffer: CVPixelBuffer? 
    
    init() {
        // init에서는 아무것도 하지 않음 (lazy 로딩 대기)
    }
    
    func send(intent: CameraIntent) {
        Task {
            switch intent {
            case .checkPermissions:
                cameraManager.checkPermissions()
            case .startAnalysis:
                state.isRunning = true
                state.isShowingResult = false
                state.capturedImage = nil
                cameraManager.startSession()
            case .stopAnalysis:
                state.isRunning = false
                cameraManager.stopSession()
            case .capturePhoto:
                if let buffer = lastBuffer {
                    state.capturedImage = UIImage.from(pixelBuffer: buffer)
                }
                state.isRunning = false
                state.isShowingResult = true
                await fetchRecommendations()
            case .analyzePixelBuffer(let buffer):
                self.lastBuffer = buffer 
                await handleAnalysis(buffer: buffer)
            case .analyzeGalleryImage(let image):
                state.capturedImage = image 
                state.isRunning = false
                state.isShowingResult = true
                if let buffer = image.toPixelBuffer() {
                    await handleAnalysis(buffer: buffer)
                    await fetchRecommendations()
                }
            case .resetToRealtime:
                state.isShowingResult = false
                state.capturedImage = nil
                state.isRunning = true
                cameraManager.startSession()
            case .provideFeedback(let style, let isLiked):
                coordinationService.recordFeedback(style: style, isLiked: isLiked)
                await fetchRecommendations()
            }
        }
    }
    
    nonisolated func didCaptureFrame(_ pixelBuffer: CVPixelBuffer) {
        Task { @MainActor in
            guard state.isRunning, !state.isShowingResult, !isAnalyzing else { return }
            self.send(intent: .analyzePixelBuffer(pixelBuffer))
        }
    }
    
    private func handleAnalysis(buffer: CVPixelBuffer) async {
        isAnalyzing = true
        if let extractedColor = await colorExtractor.extractDominantColor(from: buffer) {
            self.state.dominantColor = Color(uiColor: extractedColor)
        }
        
        // [자원 격리] AI 엔진을 호출 시점에만 접근하여 초기 구동 부하 감소
        if let result = await FashionAIProcessor.shared.analyze(pixelBuffer: buffer) {
            self.state.currentCategory = result.category
            self.state.currentStyle = result.style
            self.state.confidence = result.confidence
        }
        isAnalyzing = false
    }
    
    private func fetchRecommendations() async {
        state.isRecommendationLoading = true
        // [색상 추천 전환]CoordinationService의 바뀐 메서드 호출
        state.recommendations = await coordinationService.recommendHarmoniousColors(
            for: state.dominantColor,
            style: state.currentStyle
        )
        state.isRecommendationLoading = false
    }
}
