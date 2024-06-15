import Foundation

public protocol Request {
    associatedtype Response: Decodable
    var identifier: UUID { get }
}

public enum HTTPMethod: String {
    case GET
    case PUT
    case POST
    case DELETE
    case PATCH
}

public protocol HTTPSendbirdAPIRequest: Request {
    var apiConfig: APIConfiguration { get }
    var httpMethod: HTTPMethod { get }
    var path: String { get }
    var httpHeaderFields: [String: String] { get }
    var queries: [String: Any?] { get }
    var httpBody: Data? { get }
}

extension HTTPSendbirdAPIRequest {
    var httpMethod: HTTPMethod { .GET }
    
    var baseURL: String {
        "api-\(apiConfig.applicationId).sendbird.com"
    }
    
    var httpHeaderFields: [String: String] {
        ["Api-Token": apiConfig.apiToken,
         "Accept": "application/json",
         "Content-Type": "application/json"]
    }
    
    var queries: [String : Any?] { [:] }
    
    var httpBody: Data? { nil }
    
    var url: URL {
        get throws {
            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = baseURL
            urlComponents.path = path
            urlComponents.queryItems = queries
                .compactMapValues { $0 }
                .map { .init(name: $0.key, value: "\($0.value)") }
            guard let url = urlComponents.url else {
                throw URLError(.badURL)
            }
            return url
        }
    }
    
    func makeURLRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: try url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.httpBody = httpBody
        urlRequest.allHTTPHeaderFields = httpHeaderFields
        urlRequest.cachePolicy = .returnCacheDataElseLoad
        return urlRequest
    }
}
