import Foundation
import SwiftUI
import RealmSwift

// MARK: - Outfit Models
struct OutfitSet: Identifiable {
    let id = UUID()
    let top: ClothingItem
    let bottom: ClothingItem
    let shoes: ClothingItem
    let score: Float
    let reason: String
}

final class OutfitEngine {
    static let shared = OutfitEngine()
    private let repository: WardrobeRepositoryProtocol = WardrobeRepository.shared
    
    private init() {}
    
    func generateFullOutfit() async -> OutfitSet? {
        // [핵심] 데이터를 가져온 뒤 무작위로 섞음 (매번 다른 추천 유도)
        let allClothes = repository.fetchAll().map { $0.toDomain() }.shuffled()
        
        let tops = allClothes.filter { $0.category == "상의" }
        let bottoms = allClothes.filter { $0.category == "하의" }
        let shoesList = allClothes.filter { $0.category == "신발" }
        
        print("DEBUG: Processing \(tops.count) Tops, \(bottoms.count) Bottoms, \(shoesList.count) Shoes")
        
        guard !tops.isEmpty, !bottoms.isEmpty, !shoesList.isEmpty else { return nil }
        
        var candidates: [OutfitSet] = []
        
        // 상위 몇 개의 아이템들로 조합 후보군 생성
        for top in tops.prefix(5) {
            for bottom in bottoms.prefix(5) {
                for shoes in shoesList.prefix(5) {
                    
                    var score: Float = Float.random(in: 0.5...0.7) // 기본 점수에 약간의 랜덤 부여
                    var reasons: [String] = ["\(WeatherContext.currentSeason.rawValue) 시즌 컬렉션"]
                    
                    if top.style == bottom.style {
                        score += 0.2
                        reasons.append("\(top.style) 무드 밸런스")
                    }
                    
                    // 색상 조화 로직 (현재는 기본 적용)
                    score += 0.1
                    
                    let candidate = OutfitSet(
                        top: top,
                        bottom: bottom,
                        shoes: shoes,
                        score: score,
                        reason: reasons.joined(separator: ", ")
                    )
                    candidates.append(candidate)
                }
            }
        }
        
        // [핵심] 생성된 후보군 중 점수가 높은 것들 중에서 랜덤하게 하나 선택
        return candidates
            .sorted { $0.score > $1.score }
            .prefix(3) // 상위 3개 후보 중
            .randomElement() // 무작위 하나 반환
    }
}
