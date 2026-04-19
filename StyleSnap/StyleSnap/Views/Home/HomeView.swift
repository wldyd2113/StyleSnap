import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    let categories = ["전체", "캐주얼", "스트릿", "미니멀", "포멀"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                StyleTag(text: category, isSelected: viewModel.state.selectedCategory == category)
                                    .onTapGesture {
                                        viewModel.send(intent: .fetchHomeData(category: category))
                                        print("DEBUG: Category selected: \(category)")
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if viewModel.state.isLoading {
                        ProgressView().padding(.top, 40)
                    } else if let error = viewModel.state.errorMessage {
                        Text(error).foregroundColor(.red).padding()
                    } else {
                        // Seasonal Recommendations
                        VStack(spacing: 16) {
                            SectionHeader(title: "\(viewModel.state.selectedCategory) 시즌 추천 코디")
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.state.recommendations) { item in
                                        // [수정] NavigationLink로 상세 화면 연결
                                        NavigationLink(destination: HomeItemDetailView(item: item)) {
                                            FashionCard(
                                                title: item.name,
                                                subtitle: item.brand,
                                                imageURL: item.imageURL
                                            )
                                            .frame(width: 160)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Style of the Day
                        VStack(spacing: 16) {
                            SectionHeader(title: "현재 인기 스타일")
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                ForEach(viewModel.state.trendingStyles) { item in
                                    // [수정] NavigationLink로 상세 화면 연결
                                    NavigationLink(destination: HomeItemDetailView(item: item)) {
                                        FashionCard(
                                            title: item.name,
                                            subtitle: "\(item.price)원",
                                            imageURL: item.imageURL
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("StyleSnap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .tabBar) // 상세화면에서 돌아왔을 때 탭바가 보이도록 설정
            .onAppear {
                viewModel.send(intent: .fetchHomeData(category: viewModel.state.selectedCategory))
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
