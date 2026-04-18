import Foundation
import Combine

protocol FashionRepositoryProtocol {
    func searchFashionItems(query: String, display: Int) -> AnyPublisher<Result<[FashionItem], NetworkError>, Never>
}

final class FashionRepository: FashionRepositoryProtocol {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }
    
    func searchFashionItems(query: String, display: Int = 20) -> AnyPublisher<Result<[FashionItem], NetworkError>, Never> {
        let router = NetworkRouter.naverShoppingSearch(query: query, display: display)
        return networkManager.request(router, type: NaverShoppingResponseDTO.self)
            .map { result in
                switch result {
                case .success(let dto):
                    let domainItems = dto.items.map { $0.toDomain() }
                    return .success(domainItems)
                case .failure(let error):
                    return .failure(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
