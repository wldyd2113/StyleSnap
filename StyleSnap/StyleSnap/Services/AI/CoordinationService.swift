import SwiftUI
import RealmSwift

// MARK: - Color Recommendation Models
struct ColorRecommendation: Identifiable {
    let id = UUID()
    let name: String      // 예: "차분한 조화", "포인트 컬러"
    let color: Color      // [수정] 여러 개가 아닌 한 개만!
}

final class CoordinationService {
    static let shared = CoordinationService()
    private let realm = try! Realm()
    
    private init() {}
    
    /// 스캔된 색상을 기반으로 5가지 개별 추천 컬러를 제안합니다.
    func recommendHarmoniousColors(for baseColor: Color, style: String) async -> [ColorRecommendation] {
        let harmonyEngine = ColorHarmonyEngine.shared
        let harmonious = harmonyEngine.getHarmoniousColors(for: baseColor)
        
        // 5가지 개별 추천 컬러 생성
        return [
            ColorRecommendation(name: "차분한 조화", color: harmonious[0]),
            ColorRecommendation(name: "부드러운 매칭", color: harmonious[1]),
            ColorRecommendation(name: "강렬한 포인트", color: harmonious[2]),
            ColorRecommendation(name: "세련된 무드", color: harmonious[3]),
            ColorRecommendation(name: "신선한 느낌", color: harmonious[4])
        ]
    }
    
    func recordFeedback(style: String, isLiked: Bool) {
        try? realm.write {
            let pref = realm.object(ofType: UserPreferenceObject.self, forPrimaryKey: style) ?? UserPreferenceObject()
            if pref.realm == nil { pref.styleName = style; realm.add(pref) }
            if isLiked { pref.likeCount += 1 } else { pref.dislikeCount += 1 }
            pref.updatedAt = Date()
        }
    }
}
