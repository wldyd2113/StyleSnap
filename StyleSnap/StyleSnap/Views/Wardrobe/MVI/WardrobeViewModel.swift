import Foundation
import Combine
import SwiftUI
import RealmSwift
import Realm // NotificationToken.invalidate()를 위해 필수

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
    var selectedCategory: String = "전체" // 기본값을 '전체'로 변경하여 초기 발견성 강화
    var recommendedOutfit: OutfitSet? = nil
    var isShowingRecommendation: Bool = false
    var errorMessage: String? = nil
}

// MARK: - ViewModel
@MainActor
final class WardrobeViewModel: ObservableObject {
    @Published private(set) var state = WardrobeState()
    
    // 리포지토리 및 엔진 직접 참조하여 빌드 안정성 확보
    private let repository: WardrobeRepositoryProtocol = WardrobeRepository.shared
    private let outfitEngine = OutfitEngine.shared
    private var notificationToken: NotificationToken?
    
    init() {
        setupObservation()
    }
    
    deinit {
        // 백그라운드 스레드에서 토큰을 무효화할 수 있도록 안전하게 처리
        notificationToken?.invalidate()
    }
    
    func send(intent: WardrobeIntent) {
        switch intent {
        case .loadClothes:
            fetchClothes()
        case .changeCategory(let category):
            state.selectedCategory = category
            fetchClothes()
        case .deleteClothing(let item):
            print("DEBUG: Delete item intent received for \(item.name)")
        case .generateOutfit:
            Task { await handleGenerateOutfit() }
        }
    }
    
    private func setupObservation() {
        do {
            let realm = try Realm()
            let results = realm.objects(ClothingObject.self)
            
            notificationToken = results.observe { [weak self] changes in
                guard let self = self else { return }
                Task { @MainActor in
                    self.fetchClothes()
                }
            }
        } catch {
            print("DEBUG: Failed to setup observation: \(error)")
        }
    }
    
    private func fetchClothes() {
        state.isLoading = true
        
        let allItems = repository.fetchAll().map { $0.toDomain() }
        
        // 디버깅 로그 강화
        print("DEBUG: fetchClothes - total items in DB: \(allItems.count)")
        
        let filtered: [ClothingItem]
        if state.selectedCategory == "전체" {
            filtered = allItems
        } else {
            filtered = allItems.filter { $0.category == state.selectedCategory }
        }
        
        state.clothes = filtered
        state.isLoading = false
        print("DEBUG: fetchClothes - final result: \(filtered.count) for category: \(state.selectedCategory)")
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
