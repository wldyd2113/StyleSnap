import Foundation
import RealmSwift
import Realm
import SwiftUI

class ClothingObject: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String = ""
    @Persisted var category: String = ""
    @Persisted var style: String = ""
    @Persisted var colorName: String = ""
    @Persisted var hexColor: String = "" // Color를 저장하기 위한 헥사코드
    @Persisted var imageData: Data? 
    @Persisted var createdAt: Date = Date()
    
    // 구조체 변환 메서드 (스레드 안전한 데이터 전달을 위함)
    func toDomain() -> ClothingItem {
        return ClothingItem(
            id: id.stringValue,
            name: name,
            category: category,
            style: style,
            colorName: colorName,
            hexColor: hexColor,
            imageData: imageData
        )
    }
    
    var color: Color {
        Color(hex: hexColor) ?? .blue
    }
}
// 중복된 Color extension 제거됨 (Utils/ColorExtensions.swift로 이동)
