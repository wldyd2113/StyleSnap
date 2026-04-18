import SwiftUI
import RealmSwift

struct WardrobeView: View {
    @StateObject private var viewModel = WardrobeViewModel()
    @State private var showingAddView = false
    
    let categories = ["상의", "하의", "신발"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 카테고리 탭
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: { 
                                viewModel.send(intent: .changeCategory(category)) 
                            }) {
                                Text(category)
                                    .font(.system(size: 14, weight: viewModel.state.selectedCategory == category ? .bold : .medium))
                                    .foregroundColor(viewModel.state.selectedCategory == category ? .black : .gray)
                                    .padding(.bottom, 8)
                                    .overlay(
                                        Rectangle()
                                            .fill(viewModel.state.selectedCategory == category ? Color.black : Color.clear)
                                            .frame(height: 2)
                                            .offset(y: 12)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .padding(.bottom, 16)
                .background(Color.white)
                
                // 2. 옷장 그리드
                ScrollView {
                    if viewModel.state.isLoading {
                        ProgressView().padding(.top, 100)
                    } else if viewModel.state.clothes.isEmpty {
                        VStack(spacing: 20) {
                            Spacer(minLength: 100)
                            Image(systemName: "hanger")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("\(viewModel.state.selectedCategory)에 등록된 옷이 없습니다.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(viewModel.state.clothes) { clothing in
                                // [수정] itemName 대신 clothingId를 전달합니다.
                                NavigationLink(destination: ItemDetailView(clothingId: clothing.id)) {
                                    WardrobeItemCard(clothing: clothing)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // 3. 하단 액션
                Button(action: { viewModel.send(intent: .generateOutfit) }) {
                    Text("내 옷으로 코디 추천받기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("내 옷장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddView = true }) {
                        Image(systemName: "plus").foregroundColor(.black)
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
            if let data = clothing.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Rectangle().fill(Color.gray.opacity(0.1)).aspectRatio(1, contentMode: .fill).cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(clothing.name).font(.system(size: 12, weight: .bold)).foregroundColor(.black).lineLimit(1)
                HStack(spacing: 4) {
                    Circle().fill(clothing.color).frame(width: 8, height: 8)
                    Text(clothing.colorName).font(.system(size: 10)).foregroundColor(.gray)
                }
            }
        }
    }
}

struct WardrobeView_Previews: PreviewProvider {
    static var previews: some View {
        WardrobeView()
    }
}
