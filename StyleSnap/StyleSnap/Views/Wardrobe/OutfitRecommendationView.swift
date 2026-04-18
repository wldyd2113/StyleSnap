import SwiftUI

struct OutfitRecommendationView: View {
    let outfit: OutfitSet
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(white: 0.96).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                VStack(spacing: 8) {
                    Text("AI 코디 제안").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                    Text("오늘의 베스트 룩").font(.system(size: 28, weight: .black))
                }
                .padding(.top, 40)
                
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        OutfitItemCell(item: outfit.top, label: "상의")
                        OutfitItemCell(item: outfit.bottom, label: "하의")
                    }
                    OutfitItemCell(item: outfit.shoes, label: "신발")
                        .frame(width: 160)
                }
                .padding()
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("AI 분석 리포트")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    
                    Text(outfit.reason)
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.vertical, 20).frame(maxWidth: .infinity).background(Color.white).cornerRadius(20).padding(.horizontal)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("확인").font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.black).cornerRadius(15)
                }
                .padding(.horizontal, 20).padding(.bottom, 30)
            }
        }
    }
}

struct OutfitItemCell: View {
    let item: ClothingItem // [수정] 구조체 타입 사용
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.white).padding(.horizontal, 8).padding(.vertical, 4).background(Color.black).cornerRadius(5)
            
            ZStack {
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().aspectRatio(1, contentMode: .fill)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.1))
                }
            }
            .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit).cornerRadius(12).clipped()
            
            Text(item.name).font(.system(size: 13, weight: .bold)).lineLimit(1)
        }
        .padding(12).background(Color.white).cornerRadius(18).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
