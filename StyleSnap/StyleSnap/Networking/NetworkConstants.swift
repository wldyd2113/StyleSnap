import Foundation

struct NetworkConstants {
    static let naverBaseUrl = "https://openapi.naver.com/v1"
    static let naverClientId = APIKey.naverClientId
    static let naverClientSecret = APIKey.naverKey
}

enum NetworkError: Error {
    case invalidURL
    case encodingFailed(String)
    case decodingFailed(String)
    case unauthorized // 401
    case forbidden // 403
    case noInternetConnection
    case timeout
    case serverUnavailable
    case unknown
    case clientError(Int, String)
    case serverError(Int)
}

struct NetworkErrorMapper {
    static func map(statusCode: Int, data: Data?, error: Error) -> NetworkError {
        switch statusCode {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404...499: return .clientError(statusCode, "클라이언트 오류가 발생했습니다.")
        case 500...599: return .serverError(statusCode)
        default: return .unknown
        }
    }
}
