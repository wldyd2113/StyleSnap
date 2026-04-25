import SwiftUI
import Combine

enum OOTDIntent {
    case selectDate(Date)
    case addLog(itemIds: [String])
    case deleteLog(UUID)
    case changeMonth(Date)
}

struct OOTDState {
    var selectedDate: Date = Date()
    var currentMonth: Date = Date()
    var logs: [OOTDLog] = []
    var wardrobeItems: [ClothingItem] = []
}

class OOTDViewModel: ObservableObject {
    @Published private(set) var state = OOTDState()
    private var cancellables = Set<AnyCancellable>()
    private let repository: OOTDRepositoryProtocol
    private let wardrobeRepository = WardrobeRepository.shared
    
    init(repository: OOTDRepositoryProtocol = OOTDRepository.shared) {
        self.repository = repository
        bind()
    }
    
    private func bind() {
        // 현재 선택된 달의 로그 구독
        repository.fetchLogs(for: state.currentMonth)
            .assign(to: \.state.logs, on: self)
            .store(in: &cancellables)
            
        // 옷장 아이템 목록 가져오기
        state.wardrobeItems = wardrobeRepository.getAllItems()
    }
    
    func send(intent: OOTDIntent) {
        switch intent {
        case .selectDate(let date):
            state.selectedDate = date
        case .addLog(let itemIds):
            handleSaveLog(itemIds: itemIds)
        case .deleteLog(let id):
            repository.deleteLog(id: id)
        case .changeMonth(let date):
            state.currentMonth = date
            bind()
        }
    }
    
    private func handleSaveLog(itemIds: [String]) {
        // 옷장에서 스냅샷 생성 - 반환 타입을 명확히 하여 nil 에러 해결
        let snapshots: [ClothingItemSnapshot] = itemIds.compactMap { (id: String) -> ClothingItemSnapshot? in
            guard let item = state.wardrobeItems.first(where: { $0.id == id }) else { return nil }
            return ClothingItemSnapshot(
                id: item.id, 
                name: item.name, 
                style: item.style, // [복구] 스타일 정보 전달
                imageData: item.imageData
            )
        }
        
        let newLog = OOTDLog(
            id: UUID(),
            date: state.selectedDate,
            itemIds: itemIds,
            note: "",
            rating: 5,
            itemSnapshots: snapshots
        )
        repository.saveLog(newLog)
    }
    
    // Insight 계산 로직
    func calculateInsights() -> (top: [ClothingItemSnapshot], neglected: [ClothingItem]) {
        let allLogs = state.logs
        var counts: [String: Int] = [:]
        allLogs.forEach { log in
            log.itemIds.forEach { counts[$0, default: 0] += 1 }
        }
        
        // 1. 가장 많이 입은 상위 3개 스냅샷
        let topSnapshots: [ClothingItemSnapshot] = counts.sorted(by: { $0.value > $1.value })
            .prefix(3)
            .compactMap { (dict: (key: String, value: Int)) -> ClothingItemSnapshot? in
                // 스냅샷들 중에서 해당 ID를 가진 첫 번째 아이템 찾기
                allLogs.flatMap { $0.itemSnapshots }.first(where: { $0.id == dict.key })
            }
            
        // 2. 잠자고 있는 아이템 (기록에 없는 옷)
        let wornIds = Set(allLogs.flatMap { $0.itemIds })
        let neglected = state.wardrobeItems.filter { !wornIds.contains($0.id) }
        
        return (topSnapshots, neglected)
    }
}
