import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var tabManager: TabManager
    
    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
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
            
            AROOTDView()
                .tabItem {
                    Image(systemName: "arkit")
                    Text("AR 룩")
                }
                .tag(2)
            
            WardrobeView()
                .tabItem {
                    Image(systemName: "hanger")
                    Text("옷장")
                }
                .tag(3)
        }
        .accentColor(.black)
        .onAppear {
            print("DEBUG: MainTabView restored with 4-tab layout (Canvas removed)")
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
