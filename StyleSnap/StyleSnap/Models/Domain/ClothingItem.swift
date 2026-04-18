import Foundation
import SwiftUI

// UI와 추천 엔진에서 사용할 스레드 안전한 구조체
struct ClothingItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let style: String
    let colorName: String
    let hexColor: String
    let imageData: Data?
    
    var color: Color {
        Color(hex: hexColor) ?? .blue
    }
}
