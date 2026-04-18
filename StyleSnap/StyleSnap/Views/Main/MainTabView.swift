import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("홈")
                }
                .tag(0)
            
            CameraAnalysisView()
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text("스캔")
                }
                .tag(1)
            
            WardrobeView()
                .tabItem {
                    Image(systemName: "hanger")
                    Text("옷장")
                }
                .tag(2)
        }
        .accentColor(.black)
        .onAppear {
            print("DEBUG: MainTabView appeared with 3-tab layout")
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
