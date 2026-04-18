import Foundation
import RealmSwift

protocol WardrobeRepositoryProtocol {
    func addClothing(_ clothing: ClothingObject)
    func fetchAll() -> [ClothingObject] // 결과를 일반 배열로 반환하여 스레드 안전성 확보
    func deleteClothing(_ clothing: ClothingObject)
}

final class WardrobeRepository: WardrobeRepositoryProtocol {
    // 매번 새로운 Realm 인스턴스를 가져오도록 게터(Getter)로 설정 (스레드 안전)
    private var realm: Realm {
        try! Realm()
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
    
    func deleteClothing(_ clothing: ClothingObject) {
        let r = self.realm
        try? r.write {
            if let object = r.object(ofType: ClothingObject.self, forPrimaryKey: clothing.id) {
                r.delete(object)
            }
        }
    }
}
