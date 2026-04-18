import Foundation

// MARK: - Shopping Insight Request DTO
struct ShoppingInsightRequestDTO: Encodable {
    let startDate: String
    let endDate: String
    let timeUnit: String // date, week, month
    let category: [CategoryParamDTO]
    let device: String?
    let gender: String?
    let ages: [String]?
}

struct CategoryParamDTO: Encodable {
    let name: String
    let param: [String]
}

// MARK: - Shopping Insight Response DTO
struct ShoppingInsightResponseDTO: Decodable {
    let startDate: String
    let endDate: String
    let timeUnit: String
    let results: [InsightResultDTO]
}

struct InsightResultDTO: Decodable {
    let title: String
    let category: [String]
    let data: [InsightDataDTO]
}

struct InsightDataDTO: Decodable {
    let period: String
    let ratio: Double
    let group: String? // device API에서 사용
}

// MARK: - Domain Model for Trend
struct FashionTrend: Identifiable {
    let id = UUID()
    let title: String
    let period: String
    let ratio: Double
}
