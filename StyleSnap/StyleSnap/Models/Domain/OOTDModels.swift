import Foundation

struct OOTDLog: Identifiable, Codable {
    let id: UUID
    let date: Date           // 기록된 날짜 (시간은 startOfDay로 정규화 권장)
    let itemIds: [String]    // 연결된 옷 ID들
    var note: String?        // 한 줄 메모
    var rating: Int          // 만족도 (1~5)
    
    // 데이터 정합성을 위한 스냅샷 (아이템 삭제 대비)
    var itemSnapshots: [ClothingItemSnapshot]
}

struct ClothingItemSnapshot: Identifiable, Codable {
    let id: String
    let name: String
    let style: String        // [추가] 스타일 통계용
    let imageData: Data?     // Wardrobe 아이템의 실제 이미지 데이터 저장
}

struct OOTDInsight {
    let topItems: [(item: ClothingItem, count: Int)]
    let neglectedItems: [ClothingItem]
    let totalWearCount: Int
}
