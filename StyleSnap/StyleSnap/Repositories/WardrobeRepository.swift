import Foundation
import RealmSwift

protocol WardrobeRepositoryProtocol {
    func addClothing(_ clothing: ClothingObject)
    func fetchAll() -> [ClothingObject]
    func getAllItems() -> [ClothingItem]
    func deleteClothing(_ clothing: ClothingObject)
}

final class WardrobeRepository: WardrobeRepositoryProtocol {
    static let shared = WardrobeRepository()
    
    private var realm: Realm {
        return try! Realm()
    }
    
    private init() {
        // [수정] 앱 전체에서 동일한 설정을 사용하도록 기본 설정을 업데이트
        let config = Realm.Configuration(
            schemaVersion: 2,
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
        print("DEBUG: WardrobeRepository initialized with schema version 2")
    }
    
    func addClothing(_ clothing: ClothingObject) {
        let r = self.realm
        try? r.write {
            r.add(clothing)
        }
    }
    
    func fetchAll() -> [ClothingObject] {
        return Array(realm.objects(ClothingObject.self).sorted(byKeyPath: "createdAt", ascending: false))
    }
    
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
