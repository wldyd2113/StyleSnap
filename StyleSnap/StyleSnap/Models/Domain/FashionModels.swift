import Foundation

// MARK: - DTO (Data Transfer Object)
struct NaverShoppingResponseDTO: Codable {
    let items: [ShoppingItemDTO]
}

struct ShoppingItemDTO: Codable {
    let title: String
    let link: String
    let image: String
    let lprice: String
    let hprice: String
    let mallName: String
    let productId: String
    let productType: String
    let brand: String
    let maker: String
    let category1: String
    let category2: String
    let category3: String
    let category4: String
    
    // Convert to Domain Entity
    func toDomain() -> FashionItem {
        return FashionItem(
            id: productId,
            name: title.replacingOccurrences(of: "<b>", with: "").replacingOccurrences(of: "</b>", with: ""),
            brand: brand,
            price: Int(lprice) ?? 0,
            imageURL: image,
            mallName: mallName,
            category: category1
        )
    }
}

// MARK: - Domain Model (Entity)
struct FashionItem: Identifiable, Equatable {
    let id: String
    let name: String
    let brand: String
    let price: Int
    let imageURL: String
    let mallName: String
    let category: String
}
