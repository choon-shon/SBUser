import Foundation

struct GetUsersByNicknameRequest: HTTPSendbirdAPIRequest {
    let identifier: UUID = .init()

    typealias Response = SBUsersResponse
    
    let apiConfig: APIConfiguration
    let nickname: String

    init(_ apiConfig: APIConfiguration, nickname: String) {
        self.apiConfig = apiConfig
        self.nickname = nickname
    }
    
    var path: String {
        "/v3/users"
    }
    
    var queries: [String : Any?] {
        ["nickname": nickname,
         "limit": 100]
    }
}
