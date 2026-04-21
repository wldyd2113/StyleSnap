import SwiftUI
import Combine

class TabManager: ObservableObject {
    @Published var selectedTab: Int = 0
}
