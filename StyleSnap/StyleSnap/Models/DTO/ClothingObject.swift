import Foundation
import RealmSwift
import Realm // [추가] ObjectId.stringValue 사용을 위해 필요

class ClothingObject: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String = ""
    @Persisted var category: String = ""
    @Persisted var style: String = ""
    @Persisted var colorName: String = ""
    @Persisted var hexColor: String = ""
    @Persisted var imageData: Data? = nil
    @Persisted var createdAt: Date = Date()
    @Persisted var embeddingData: Data? = nil // [추가] 벡터 데이터를 Data 형태로 압축 저장

    func toDomain() -> ClothingItem {
        var embedding: [Float]? = nil
        if let data = embeddingData {
            // Data를 [Float] 배열로 복원
            embedding = data.withUnsafeBytes { pointer in
                Array(pointer.bindMemory(to: Float.self))
            }
        }
        
        return ClothingItem(
            id: id.stringValue,
            name: name,
            category: category,
            style: style,
            colorName: colorName,
            hexColor: hexColor,
            imageData: imageData,
            embedding: embedding
        )
    }
}
