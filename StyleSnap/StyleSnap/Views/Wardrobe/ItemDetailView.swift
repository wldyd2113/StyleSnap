import SwiftUI

struct ItemDetailView: View {
    let clothingId: String // ID를 받아 Realm에서 정확히 조회
    @StateObject private var viewModel = ItemDetailViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            if let item = viewModel.state.item {
                VStack(alignment: .leading, spacing: 20) {
                    // Item Image (Real Data)
                    ZStack {
                        if let data = item.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.gray.opacity(0.1))
                                .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Title and Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name)
                                .font(.system(size: 26, weight: .bold))
                            Text("\(item.category) / \(item.style)")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        
                        // Info Grid
                        HStack(spacing: 40) {
                            DetailInfoItem(label: "색상", value: item.colorName, color: item.color)
                            DetailInfoItem(label: "스타일 무드", value: item.style)
                        }
                        
                        Divider()
                        
                        // AI Matching Suggestions (내 옷장 연동)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("이 옷과 매칭하기 좋은 내 옷장 아이템")
                                .font(.system(size: 18, weight: .bold))
                            
                            if viewModel.state.matchingRecommendations.isEmpty {
                                Text("어울리는 하의나 신발을 더 등록해 보세요.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 10)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.state.matchingRecommendations) { match in
                                            NavigationLink(destination: ItemDetailView(clothingId: match.id)) {
                                                MatchItemCard(item: match)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Delete Button
                        Button(action: { viewModel.send(intent: .deleteItem) }) {
                            Text("옷 삭제")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                }
            } else {
                ProgressView("정보를 불러오는 중...").padding(.top, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.send(intent: .loadItem(clothingId))
        }
        .onChange(of: viewModel.state.isDeleted) { deleted in
            if deleted { dismiss() }
        }
    }
}

// MARK: - Sub Components
struct DetailInfoItem: View {
    let label: String
    let value: String
    var color: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundColor(.gray)
            HStack(spacing: 6) {
                if let dotColor = color {
                    Circle().fill(dotColor).frame(width: 10, height: 10)
                }
                Text(value).font(.system(size: 16, weight: .bold))
            }
        }
    }
}

struct MatchItemCard: View {
    let item: ClothingItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().aspectRatio(1, contentMode: .fill)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.1))
                }
            }
            .frame(width: 120, height: 150).cornerRadius(12).clipped()
            
            Text(item.name).font(.system(size: 12, weight: .bold)).foregroundColor(.black).lineLimit(1)
        }
    }
}

struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(clothingId: "preview_id")
    }
}
