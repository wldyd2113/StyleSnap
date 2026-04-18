import Foundation
import Combine

// MARK: - MVI Components
enum HomeIntent {
    case fetchHomeData(category: String)
    case selectCategory(String)
}

struct HomeState {
    var isLoading: Bool = false
    var recommendations: [FashionItem] = []
    var trendingStyles: [FashionItem] = []
    var selectedCategory: String = "전체"
    var errorMessage: String? = nil
}

// MARK: - ViewModel
final class HomeViewModel: ObservableObject {
    @Published private(set) var state = HomeState()
    
    private let repository: FashionRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private let intentSubject = PassthroughSubject<HomeIntent, Never>()
    
    init(repository: FashionRepositoryProtocol = FashionRepository()) {
        self.repository = repository
        setupIntentPipeline()
    }
    
    func send(intent: HomeIntent) {
        intentSubject.send(intent)
    }
    
    private func setupIntentPipeline() {
        intentSubject
            .flatMap { [weak self] intent -> AnyPublisher<HomeState, Never> in
                guard let self = self else { return Just(HomeState()).eraseToAnyPublisher() }
                switch intent {
                case .fetchHomeData(let category):
                    return self.handleFetchHomeData(category: category)
                case .selectCategory(let category):
                    var newState = self.state
                    newState.selectedCategory = category
                    return Just(newState).eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.state = newState
            }
            .store(in: &cancellables)
    }
    
    private func handleFetchHomeData(category: String) -> AnyPublisher<HomeState, Never> {
        var loadingState = self.state
        loadingState.isLoading = true
        
        let query = category == "전체" ? "2024 봄 코디" : "2024 \(category) 코디"
        
        return repository.searchFashionItems(query: query, display: 20)
            .map { result -> HomeState in
                var newState = self.state
                newState.isLoading = false
                switch result {
                case .success(let items):
                    newState.recommendations = Array(items.prefix(10))
                    newState.trendingStyles = Array(items.suffix(max(0, items.count - 10)))
                case .failure(let error):
                    newState.errorMessage = error.localizedDescription
                }
                return newState
            }
            .prepend(loadingState)
            .eraseToAnyPublisher()
    }
}
