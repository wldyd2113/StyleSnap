import Foundation
import Combine
import SwiftUI

// MARK: - MVI Components
enum HomeItemDetailIntent {
    case openShopLink
}

struct HomeItemDetailState {
    var item: FashionItem
}

// MARK: - ViewModel
@MainActor
final class HomeItemDetailViewModel: ObservableObject {
    @Published private(set) var state: HomeItemDetailState
    
    init(item: FashionItem) {
        self.state = HomeItemDetailState(item: item)
    }
    
    func send(intent: HomeItemDetailIntent) {
        switch intent {
        case .openShopLink:
            handleOpenLink()
        }
    }
    
    private func handleOpenLink() {
        guard let url = URL(string: state.item.shopLink) else { return }
        // 시스템 브라우저(Safari)로 열기
        UIApplication.shared.open(url)
    }
}
