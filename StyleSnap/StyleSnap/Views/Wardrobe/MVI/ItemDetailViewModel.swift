import Foundation
import Combine
import SwiftUI
import RealmSwift
import Realm

// MARK: - MVI Components
enum ItemDetailIntent {
    case loadItem(String)
    case deleteItem
}

struct ItemDetailState {
    var isLoading: Bool = false
    var item: ClothingItem? = nil
    var matchingRecommendations: [ClothingItem] = []
    var isDeleted: Bool = false
}

// MARK: - ViewModel
@MainActor
final class ItemDetailViewModel: ObservableObject {
    @Published private(set) var state = ItemDetailState()
    
    // 리포지토리 직접 참조 (싱글톤 인스턴스 사용)
    private let repository: WardrobeRepositoryProtocol = WardrobeRepository.shared
    
    init() {}
    
    func send(intent: ItemDetailIntent) {
        switch intent {
        case .loadItem(let id):
            fetchItemDetail(id: id)
        case .deleteItem:
            handleDelete()
        }
    }
    
    private func fetchItemDetail(id: String) {
        state.isLoading = true
        
        let allObjects = repository.fetchAll()
        if let foundObject = allObjects.first(where: { $0.id.stringValue == id }) {
            let domainItem = foundObject.toDomain()
            state.item = domainItem
            
            // AI 기반 매칭 찾기
            findMatchingClothes(for: domainItem)
        }
        
        state.isLoading = false
    }
    
    private func findMatchingClothes(for currentItem: ClothingItem) {
        let allItems = repository.fetchAll().map { $0.toDomain() }
        
        // 1. 대칭 카테고리 결정
        let targetCategory = (currentItem.category == "상의") ? "하의" : "상의"
        
        // [수정] 복잡한 체인을 명시적인 단계로 분리하여 컴파일 타임아웃 해결
        // 1단계: 카테고리와 ID로 필터링
        let filtered = allItems.filter { item in
            return item.id != currentItem.id && item.category == targetCategory
        }
        
        // 2단계: 스타일 무드 일치 여부로 정렬
        let sorted = filtered.sorted { (item1, item2) -> Bool in
            let match1 = item1.style == currentItem.style
            let match2 = item2.style == currentItem.style
            if match1 != match2 {
                return match1 // 스타일이 맞는 쪽을 앞으로
            }
            return false
        }
        
        state.matchingRecommendations = Array(sorted.prefix(5))
    }
    
    private func handleDelete() {
        guard let item = state.item else { return }
        // 리포지토리에서 실제 객체 찾아 삭제
        let all = repository.fetchAll()
        if let objectToDelete = all.first(where: { $0.id.stringValue == item.id }) {
            repository.deleteClothing(objectToDelete)
            state.isDeleted = true
        }
    }
}
