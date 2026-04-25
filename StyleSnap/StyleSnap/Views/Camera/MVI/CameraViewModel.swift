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
    case provideFeedback(style: String, isLiked: Bool) // [복구]
}

struct CameraState {
    var isRunning: Bool = false
    var isShowingResult: Bool = false 
    var currentCategory: String = "분석 준비 중..."
    var currentStyle: String = "스타일 분석 중..."
    var dominantColor: Color = .fashionGray
    var confidence: Float = 0.0
    var recommendations: [RecommendedItem] = []
    var isRecommendationLoading: Bool = false
    var capturedImage: UIImage? = nil // [추가] 촬영된 이미지 저장
}

// MARK: - ViewModel
@MainActor
final class CameraViewModel: ObservableObject, CameraManagerDelegate {
    @Published private(set) var state = CameraState()
    
    let cameraManager = CameraManager()
    private let aiProcessor = FashionAIProcessor.shared
    private let colorExtractor = ColorExtractor.shared
    private let coordinationService = CoordinationService.shared
    
    private var isAnalyzing = false
    private var lastBuffer: CVPixelBuffer? // [추가] 최신 프레임 임시 저장
    
    init() {
        cameraManager.delegate = self
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
                // 최신 버퍼를 이미지로 변환하여 저장
                if let buffer = lastBuffer {
                    state.capturedImage = UIImage.from(pixelBuffer: buffer)
                }
                state.isRunning = false
                state.isShowingResult = true
                await fetchRecommendations()
            case .analyzePixelBuffer(let buffer):
                self.lastBuffer = buffer // 최신 버퍼 갱신
                await handleAnalysis(buffer: buffer)
            case .analyzeGalleryImage(let image):
                state.capturedImage = image // 갤러리 이미지 저장
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
        if let result = await aiProcessor.analyze(pixelBuffer: buffer) {
            self.state.currentCategory = result.category
            self.state.currentStyle = result.style
            self.state.confidence = result.confidence
        }
        isAnalyzing = false
    }
    
    private func fetchRecommendations() async {
        state.isRecommendationLoading = true
        state.recommendations = await coordinationService.recommend(
            category: state.currentCategory,
            style: state.currentStyle,
            color: state.dominantColor
        )
        state.isRecommendationLoading = false
    }
}
