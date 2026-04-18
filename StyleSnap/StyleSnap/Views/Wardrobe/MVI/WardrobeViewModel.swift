import Foundation
import Combine
import SwiftUI
import RealmSwift

// MARK: - MVI Components
enum WardrobeIntent {
    case loadClothes
    case changeCategory(String)
    case deleteClothing(ClothingItem)
    case generateOutfit
}

struct WardrobeState {
    var isLoading: Bool = false
    var clothes: [ClothingItem] = []
    var selectedCategory: String = "상의"
    var recommendedOutfit: OutfitSet? = nil
    var isShowingRecommendation: Bool = false
    var errorMessage: String? = nil
}

// MARK: - ViewModel
@MainActor
final class WardrobeViewModel: ObservableObject {
    @Published private(set) var state = WardrobeState()
    
    private let repository: WardrobeRepositoryProtocol
    private let outfitEngine = OutfitEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: WardrobeRepositoryProtocol = WardrobeRepository()) {
        self.repository = repository
    }
    
    func send(intent: WardrobeIntent) {
        switch intent {
        case .loadClothes:
            fetchClothes()
        case .changeCategory(let category):
            state.selectedCategory = category
            fetchClothes()
        case .deleteClothing(let item):
            // 실제 삭제 로직 (생략 가능하나 구조상 포함)
            print("DEBUG: Delete item intent received for \(item.name)")
        case .generateOutfit:
            Task { await handleGenerateOutfit() }
        }
    }
    
    private func fetchClothes() {
        state.isLoading = true
        // 리포지토리에서 데이터를 가져와 구조체로 변환
        let results = repository.fetchAll()
            .filter { $0.category == state.selectedCategory }
            .map { $0.toDomain() }
        
        state.clothes = results
        state.isLoading = false
    }
    
    private func handleGenerateOutfit() async {
        state.isLoading = true
        if let outfit = await outfitEngine.generateFullOutfit() {
            state.recommendedOutfit = outfit
            state.isShowingRecommendation = true
        } else {
            state.errorMessage = "추천 가능한 조합이 없습니다."
        }
        state.isLoading = false
    }
    
    func dismissRecommendation() {
        state.isShowingRecommendation = false
    }
}
