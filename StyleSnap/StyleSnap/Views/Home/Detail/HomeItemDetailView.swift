import SwiftUI

struct HomeItemDetailView: View {
    @StateObject private var viewModel: HomeItemDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    init(item: FashionItem) {
        _viewModel = StateObject(wrappedValue: HomeItemDetailViewModel(item: item))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. 메인 콘텐츠 영역 (스크롤)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 히어로 이미지 (4:5 비율 고정)
                    heroImageSection
                    
                    // 상세 정보 카드
                    detailCardSection
                    
                    // 하단 버튼 공간 확보 (플로팅 버튼 높이 고려)
                    Spacer(minLength: 140)
                }
            }
            
            // 2. 하단 플로팅 구매 버튼 (세련되게 축소)
            buyButtonSection
            
            // 3. 상단 커스텀 버튼 (뒤로가기)
            topOverlayButtons
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar) // 상세 화면에서 탭바 숨기기
    }
    
    private var heroImageSection: some View {
        ZStack(alignment: .top) {
            AsyncImage(url: URL(string: viewModel.state.item.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty:
                    ProgressView()
                default:
                    Rectangle().fill(Color.fashionGray)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.25)
            .background(Color.white)
            .clipped()
            
            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.15), .clear]), startPoint: .top, endPoint: .bottom)
                .frame(height: 80)
        }
    }
    
    private var detailCardSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.state.item.brand)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondaryGray)
                    .tracking(1)
                
                Text(viewModel.state.item.name)
                    .font(.system(size: 26, weight: .black))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("판매가")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(viewModel.state.item.price)원")
                        .font(.system(size: 32, weight: .heavy))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                Spacer()
                Text(viewModel.state.item.mallName)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.fashionGray).cornerRadius(8)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Product Info")
                    .font(.system(size: 18, weight: .bold))
                
                HStack {
                    Label("카테고리", systemImage: "tag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.state.item.category)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .padding(25)
        .background(Color.white)
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .padding(.top, -30)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
    
    // 구매 버튼 스타일 개선: 플로팅 스타일로 변경
    private var buyButtonSection: some View {
        VStack {
            Spacer()
            Button(action: { viewModel.send(intent: .openShopLink) }) {
                Text("BUY NOW")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.black)
                    .cornerRadius(15) // 버튼 모서리 둥글게
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 20) // 하단 세이프 에어리어 위로 살짝 띄움
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
    }
    
    private var topOverlayButtons: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                .padding(.leading, 20)
                .padding(.top, 10)
                Spacer()
            }
            Spacer()
        }
    }
}

// 둥근 모서리 선택 적용을 위한 Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct HomeItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HomeItemDetailView(item: FashionItem(
            id: "1", name: "샘플 프리미엄 패션 옷", brand: "STYLE SNAP", 
            price: 128000, imageURL: "", mallName: "공식 스토어", 
            category: "상의", shopLink: ""
        ))
    }
}
