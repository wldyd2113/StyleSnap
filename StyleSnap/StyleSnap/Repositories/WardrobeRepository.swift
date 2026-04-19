import Foundation
import RealmSwift

protocol WardrobeRepositoryProtocol {
    func addClothing(_ clothing: ClothingObject)
    func fetchAll() -> [ClothingObject]
    func getAllItems() -> [ClothingItem] // 도메인 모델로 변환하여 반환하는 메서드 추가
    func deleteClothing(_ clothing: ClothingObject)
}

final class WardrobeRepository: WardrobeRepositoryProtocol {
    static let shared = WardrobeRepository() // 싱글톤 추가
    
    private var realm: Realm {
        try! Realm()
    }
    
    private init() {} // 싱글톤 패턴을 위해 private init
    
    func addClothing(_ clothing: ClothingObject) {
        let r = self.realm
        try? r.write {
            r.add(clothing)
        }
    }
    
    func fetchAll() -> [ClothingObject] {
        return Array(realm.objects(ClothingObject.self).sorted(byKeyPath: "createdAt", ascending: false))
    }
    
    // 도메인 모델(ClothingItem)로 변환하여 반환
    func getAllItems() -> [ClothingItem] {
        return fetchAll().map { $0.toDomain() }
    }
    
    func deleteClothing(_ clothing: ClothingObject) {
        let r = self.realm
        try? r.write {
            if let object = r.object(ofType: ClothingObject.self, forPrimaryKey: clothing.id) {
                r.delete(object)
            }
        }
    }
}
