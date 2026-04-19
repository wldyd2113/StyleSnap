import SwiftUI
import RealmSwift

struct WardrobeView: View {
    @StateObject private var viewModel = WardrobeViewModel()
    @State private var showingAddView = false
    
    let categories = ["상의", "하의", "신발"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 카테고리 탭 (개선된 구조)
                HStack(spacing: 0) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { 
                            viewModel.send(intent: .changeCategory(category)) 
                        }) {
                            VStack(spacing: 12) {
                                Text(category)
                                    .font(.system(size: 15, weight: viewModel.state.selectedCategory == category ? .bold : .medium))
                                    .foregroundColor(viewModel.state.selectedCategory == category ? .black : .gray)
                                
                                // 인디케이터를 고정 높이의 사각형으로 배치하여 레이아웃 흔들림 방지
                                Rectangle()
                                    .fill(viewModel.state.selectedCategory == category ? Color.black : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 16)
                .background(Color.white)
                
                Divider() // 카테고리와 콘텐츠 구분선
                
                // 2. 옷장 그리드 및 엠프티 뷰
                ScrollView {
                    if viewModel.state.isLoading {
                        ProgressView().padding(.top, 100)
                    } else if viewModel.state.clothes.isEmpty {
                        // 개선된 엠프티 뷰: 화면 중앙에 안정적으로 배치
                        VStack(spacing: 16) {
                            Image(systemName: "hanger")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("\(viewModel.state.selectedCategory)에 등록된 옷이 없습니다.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 120)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.state.clothes) { clothing in
                                NavigationLink(destination: ItemDetailView(clothingId: clothing.id)) {
                                    WardrobeItemCard(clothing: clothing)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                
                // 3. 하단 코디 추천 버튼
                Button(action: { viewModel.send(intent: .generateOutfit) }) {
                    Text("내 옷으로 코디 추천받기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("내 옷장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: OOTDCalendarView()) {
                            Image(systemName: "calendar.badge.plus").foregroundColor(.black)
                        }
                        
                        Button(action: { showingAddView = true }) {
                            Image(systemName: "plus").foregroundColor(.black)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddClothingView()
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.state.isShowingRecommendation },
                set: { _ in viewModel.dismissRecommendation() }
            )) {
                if let outfit = viewModel.state.recommendedOutfit {
                    OutfitRecommendationView(outfit: outfit)
                }
            }
            .onAppear {
                viewModel.send(intent: .loadClothes)
            }
        }
    }
}

// MARK: - Reusable Card Component
struct WardrobeItemCard: View {
    let clothing: ClothingItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let data = clothing.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.1))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(10)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(clothing.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(clothing.color)
                        .frame(width: 8, height: 8)
                    Text(clothing.colorName)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
