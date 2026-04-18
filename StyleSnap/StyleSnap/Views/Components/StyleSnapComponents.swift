import SwiftUI

// MARK: - Color Palette
extension Color {
    static let fashionBlack = Color.black
    static let fashionGray = Color(white: 0.95)
    static let secondaryGray = Color(white: 0.6)
}

// MARK: - Reusable Components
struct FashionCard: View {
    let title: String
    var subtitle: String? = nil
    var imageURL: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.fashionGray)
                .aspectRatio(3/4, contentMode: .fill)
                .overlay(
                    Group {
                        if let urlString = imageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondaryGray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondaryGray)
                        }
                    }
                )
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.fashionBlack)
                    .lineLimit(2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryGray)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct StyleTag: View {
    let text: String
    var isSelected: Bool = false
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.fashionBlack : Color.clear)
            .foregroundColor(isSelected ? .white : .fashionBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.fashionBlack, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.fashionBlack)
                .cornerRadius(8)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var showMore: Bool = true
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.fashionBlack)
            Spacer()
            if showMore {
                Button(action: { print("DEBUG: Show more tapped for \(title)") }) {
                    Text("See All")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryGray)
                }
            }
        }
        .padding(.horizontal)
    }
}
