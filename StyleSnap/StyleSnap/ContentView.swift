import SwiftUI

struct ContentView: View {
    @StateObject var tabManager = TabManager()
    
    var body: some View {
        MainTabView()
            .environmentObject(tabManager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
