import Foundation
import Combine
import SwiftUI
import PhotosUI

// MARK: - MVI Components
enum AddClothingIntent {
    case selectImage(PhotosPickerItem?)
    case updateName(String)
    case updateCategory(String)
    case updateStyle(String)
    case updateColorName(String)
    case updateColor(Color)
    case save
}

struct AddClothingState {
    var selectedPhotoItem: PhotosPickerItem? = nil
    var capturedImageData: Data? = nil
    var itemName: String = ""
    var selectedCategory: String = "상의"
    var selectedStyle: String = "미니멀"
    var colorName: String = ""
    var selectedColor: Color = .blue
    var isAnalyzing: Bool = false
    var isSaved: Bool = false
    var currentEmbedding: [Float]? = nil // [추가] 분석된 임베딩 임시 보관
}

// MARK: - ViewModel
@MainActor
final class AddClothingViewModel: ObservableObject {
    @Published private(set) var state = AddClothingState()
    
    private let repository: WardrobeRepositoryProtocol
    private let aiProcessor = FashionAIProcessor.shared
    private let colorExtractor = ColorExtractor.shared
    
    init(repository: WardrobeRepositoryProtocol = WardrobeRepository.shared) {
        self.repository = repository
    }
    
    func send(intent: AddClothingIntent) {
        switch intent {
        case .selectImage(let item):
            state.selectedPhotoItem = item
            handleImageSelection(item)
        case .updateName(let name):
            state.itemName = name
        case .updateCategory(let category):
            state.selectedCategory = category
        case .updateStyle(let style):
            state.selectedStyle = style
        case .updateColorName(let name):
            state.colorName = name
        case .updateColor(let color):
            state.selectedColor = color
        case .save:
            saveToRealm()
        }
    }
    
    private func handleImageSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        state.isAnalyzing = true
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                state.capturedImageData = data
                
                if let buffer = image.toPixelBuffer() {
                    // 1. 색상 추출
                    if let color = await colorExtractor.extractDominantColor(from: buffer) {
                        state.selectedColor = Color(uiColor: color)
                    }
                    
                    // 2. AI 분석 (카테고리 + 스타일 + 임베딩 특징 추출)
                    if let result = await aiProcessor.analyze(pixelBuffer: buffer) {
                        state.selectedCategory = result.category
                        state.selectedStyle = result.style
                        state.currentEmbedding = result.embedding // [추가] 특징 벡터 저장
                        
                        if state.itemName.isEmpty {
                            state.itemName = "\(result.style) \(result.category)"
                        }
                    }
                }
            }
            state.isAnalyzing = false
        }
    }
    
    private func saveToRealm() {
        let newClothing = ClothingObject()
        newClothing.name = state.itemName
        newClothing.category = state.selectedCategory
        newClothing.style = state.selectedStyle
        newClothing.colorName = state.colorName
        newClothing.hexColor = state.selectedColor.toHexStr()
        newClothing.imageData = state.capturedImageData
        
        // [추가] 특징 벡터(임베딩)를 데이터 형태로 변환하여 Realm에 저장
        if let embedding = state.currentEmbedding {
            newClothing.embeddingData = Data(bytes: embedding, count: embedding.count * MemoryLayout<Float>.size)
        }
        
        repository.addClothing(newClothing)
        state.isSaved = true
    }
}
