import Foundation
import SwiftUI

struct ClothingItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let style: String
    let colorName: String
    let hexColor: String
    let imageData: Data?
    let embedding: [Float]? // [추가] AI가 분석한 패션 특징 벡터 (512차원)

    var color: Color {
        Color(hex: hexColor) ?? .blue
    }
}
