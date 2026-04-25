import Foundation
import RealmSwift

class UserPreferenceObject: Object {
    @Persisted(primaryKey: true) var styleName: String = "" // 스타일 명 (예: 미니멀, 스트릿)
    @Persisted var likeCount: Int = 0                     // 좋아요 누른 횟수
    @Persisted var dislikeCount: Int = 0                  // 싫어요 누른 횟수
    @Persisted var updatedAt: Date = Date()
    
    // 점수 계산 (좋아요 - 싫어요)
    var preferenceScore: Int {
        return likeCount - (dislikeCount * 5) // 싫어요에 더 강한 페널티 부여
    }
}
