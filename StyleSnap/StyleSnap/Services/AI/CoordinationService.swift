import SwiftUI

// MARK: - Coordination Service
struct RecommendedItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let matchScore: Float
    let color: Color
}

final class CoordinationService {
    static let shared = CoordinationService()
    private init() {}
    
    func recommend(category: String, style: String, color: Color) async -> [RecommendedItem] {
        let colorName = getColorName(for: color)
        let harmony = ColorHarmonyEngine.shared.getHarmoniousColors(for: color)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // [수정] harmony 배열의 각 인덱스를 순서대로 사용하여 중복 제거
        return [
            RecommendedItem(
                name: "\(colorName)와 톤온톤 매칭", 
                category: "조화로운 컬러", 
                matchScore: 0.98, 
                color: harmony[0]
            ),
            RecommendedItem(
                name: "세련된 보색 대비", 
                category: "포인트 컬러", 
                matchScore: 0.94, 
                color: harmony[1]
            ),
            RecommendedItem(
                name: "매력적인 유사색 조합", 
                category: "스타일리시 컬러", 
                matchScore: 0.89, 
                color: harmony[2]
            ),
            RecommendedItem(
                name: "데일리 컬러 매칭", 
                category: "추천 컬러", 
                matchScore: 0.85, 
                color: harmony[3]
            )
        ]
    }
    
    private func getColorName(for color: Color) -> String {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        if brightness < 0.15 { return "블랙" }
        if brightness > 0.85 { return "화이트" }
        if r > g && r > b { return "레드" }
        if g > r && g > b { return "그린" }
        if b > r && b > g { return "블루" }
        return "현재 컬러"
    }
}
