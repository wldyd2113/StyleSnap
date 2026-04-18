import Foundation
import Alamofire
import Combine

enum NetworkRouter: URLRequestConvertible {
    case naverShoppingSearch(query: String, display: Int = 10, start: Int = 1, sort: String = "sim")
    
    var baseURL: String {
        return NetworkConstants.naverBaseUrl
    }
    
    var path: String {
        switch self {
        case .naverShoppingSearch:
            return "/search/shop.json"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    func asURLRequest() throws -> URLRequest {
        let urlString = baseURL + path
        guard var urlComponents = URLComponents(string: urlString) else {
            throw AFError.parameterEncodingFailed(reason: .missingURL)
        }
        
        // 쿼리 파라미터 직접 설정 (인코딩 문제 방지)
        switch self {
        case .naverShoppingSearch(let query, let display, let start, let sort):
            urlComponents.queryItems = [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "display", value: "\(display)"),
                URLQueryItem(name: "start", value: "\(start)"),
                URLQueryItem(name: "sort", value: sort)
            ]
        }
        
        guard let finalURL = urlComponents.url else {
            throw AFError.parameterEncodingFailed(reason: .missingURL)
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        
        // 헤더를 하나씩 직접 추가 (매우 중요)
        request.addValue(NetworkConstants.naverClientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(NetworkConstants.naverClientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        return request
    }
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func request<T: Decodable>(_ convertible: URLRequestConvertible, type: T.Type) -> AnyPublisher<Result<T, NetworkError>, Never> {
        // validate(statusCode:)를 제거하여 401 에러 바디를 직접 확인하도록 합니다.
        return AF.request(convertible)
            .publishDecodable(type: T.self)
            .map { response in
                // 디버깅 로그: 최종적으로 전송된 정보들
                if let request = response.request {
                    print("DEBUG: Final URL: \(request.url?.absoluteString ?? "nil")")
                    print("DEBUG: Client-Id: [\(request.value(forHTTPHeaderField: "X-Naver-Client-Id") ?? "nil")]")
                    print("DEBUG: Secret: [\(request.value(forHTTPHeaderField: "X-Naver-Client-Secret") ?? "nil")]")
                }
                
                switch response.result {
                case .success(let value):
                    return .success(value)
                case .failure(let error):
                    let statusCode = response.response?.statusCode ?? 0
                    print("DEBUG: Error Status Code: \(statusCode)")
                    
                    if let data = response.data, let body = String(data: data, encoding: .utf8) {
                        print("DEBUG: Error Response Body: \(body)")
                    }
                    
                    if statusCode != 0 {
                        return .failure(NetworkErrorMapper.map(statusCode: statusCode, data: response.data, error: error))
                    }
                    return .failure(.noInternetConnection)
                }
            }
            .eraseToAnyPublisher()
    }
}
