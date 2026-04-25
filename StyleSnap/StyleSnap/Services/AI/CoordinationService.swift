import SwiftUI
import RealmSwift

// MARK: - Coordination Service
struct RecommendedItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let style: String
    let matchScore: Float
    let imageURL: String // 옷 이미지 URL (컬러 대신 사용)
}

final class CoordinationService {
    static let shared = CoordinationService()
    private let realm = try! Realm()
    
    private init() {}
    
    // [핵심] 사용자의 선호를 반영하여 실제 '옷' 아이템을 추천
    func recommend(category: String, style: String, color: Color) async -> [RecommendedItem] {
        let preferences = realm.objects(UserPreferenceObject.self)
        
        // 1. 스타일별 추천 DB (가상 데이터베이스)
        let clothingDB: [String: [(name: String, image: String)]] = [
            "미니멀": [
                ("오버사이즈 울 코트", "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=300"),
                ("슬림핏 슬랙스", "https://images.unsplash.com/photo-1624371414361-e6e9ea362127?q=80&w=300"),
                ("화이트 옥스포드 셔츠", "https://images.unsplash.com/photo-1598033129183-c4f50c717658?q=80&w=300")
            ],
            "스트릿": [
                ("그래픽 후디", "https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=300"),
                ("와이드 카고 팬츠", "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?q=80&w=300"),
                ("오버핏 바시티 자켓", "https://images.unsplash.com/photo-1551028719-00167b16eac5?q=80&w=300")
            ],
            "포멀": [
                ("더블 브레스티드 블레이저", "https://images.unsplash.com/photo-1594932224828-b4b059b6fe68?q=80&w=300"),
                ("태슬 로퍼", "https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?q=80&w=300"),
                ("실크 타이", "https://images.unsplash.com/photo-1589756823253-573a763870e2?q=80&w=300")
            ]
        ]
        
        // 2. 현재 감지된 스타일 + 사용자 선호 스타일 결합
        let targetStyle = style // 기본값은 AI 분석 결과 사용
        let items = clothingDB[targetStyle] ?? clothingDB["미니멀"]!
        
        // 3. 필터링 및 점수 계산
        let filtered = items.compactMap { item -> RecommendedItem? in
            let pref = preferences.filter("styleName == %@", targetStyle).first
            if let p = pref, p.preferenceScore < -3 { return nil } // 싫어요 많으면 제외
            
            var score = 0.85 + Float.random(in: 0...0.1)
            if let p = pref { score += Float(p.likeCount) * 0.02 } // 좋아요 가중치
            
            return RecommendedItem(
                name: item.name,
                category: "추천 아이템",
                style: targetStyle,
                matchScore: min(score, 0.99),
                imageURL: item.image
            )
        }
        
        return filtered.shuffled().prefix(4).map { $0 }
    }
    
    func recordFeedback(style: String, isLiked: Bool) {
        try? realm.write {
            let pref = realm.object(ofType: UserPreferenceObject.self, forPrimaryKey: style) ?? UserPreferenceObject()
            if pref.realm == nil { pref.styleName = style; realm.add(pref) }
            if isLiked { pref.likeCount += 1 } else { pref.dislikeCount += 1 }
            pref.updatedAt = Date()
        }
    }
    
    private func getColorName(for color: Color) -> String { "추천" }
}
