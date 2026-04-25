import SwiftUI

struct OutfitRecommendationView: View {
    let outfit: OutfitSet
    @Environment(\.dismiss) var dismiss
    @State private var hasFeedbackGiven = false 
    
    var body: some View {
        ZStack {
            // 배경색 (스크린샷의 연한 그레이 톤)
            Color(white: 0.96).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 1. 헤더 섹션
                VStack(spacing: 8) {
                    Text("AI 코디 제안")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("오늘의 베스트 룩")
                        .font(.system(size: 28, weight: .black))
                }
                .padding(.top, 50)
                .padding(.bottom, 30)
                
                // 2. 코디 그리드 (2+1 배치)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 상의 & 하의 나란히 배치
                        HStack(spacing: 15) {
                            OutfitItemCell(item: outfit.top, label: "상의")
                            OutfitItemCell(item: outfit.bottom, label: "하의")
                        }
                        
                        // 신발 하단 중앙 배치
                        OutfitItemCell(item: outfit.shoes, label: "신발")
                            .frame(width: UIScreen.main.bounds.width * 0.46) 
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // 3. 피드백 섹션 (작고 깔끔하게)
                    VStack(spacing: 16) {
                        if !hasFeedbackGiven {
                            Text("이 제안이 마음에 드시나요?")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 45) {
                                Button(action: { giveFeedback(isLiked: true) }) {
                                    FeedbackButton(icon: "hand.thumbsup.fill", label: "좋아요", color: .blue)
                                }
                                
                                Button(action: { giveFeedback(isLiked: false) }) {
                                    FeedbackButton(icon: "hand.thumbsdown.fill", label: "싫어요", color: .red)
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("취향 학습 완료").font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.green)
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(.top, 10)
                }
                
                // 4. 하단 확인 버튼
                Button(action: { dismiss() }) {
                    Text("확인")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func giveFeedback(isLiked: Bool) {
        withAnimation(.spring()) { hasFeedbackGiven = true }
        let styles = [outfit.top.style, outfit.bottom.style, outfit.shoes.style]
        for style in styles {
            CoordinationService.shared.recordFeedback(style: style, isLiked: isLiked)
        }
    }
}

// 스크린샷의 카드 디자인을 완벽히 재현한 Cell
struct OutfitItemCell: View {
    let item: ClothingItem 
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 검정색 카테고리 박스
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black)
                .cornerRadius(4)
            
            // 이미지 영역 (그레이 배경 박스)
            ZStack {
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(10)
                } else {
                    Image(systemName: "hanger").foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(Color(white: 0.94)) 
            .cornerRadius(12)
            
            // 아이템 명칭 (볼드)
            Text(item.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}

// 더 작아진 피드백 버튼
struct FeedbackButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
        }
    }
}
