import Foundation

struct GetUserRequestByID: HTTPSendbirdAPIRequest {
    let identifier: UUID = .init()

    typealias Response = SBUserResponse
    
    let apiConfig: APIConfiguration
    let userId: String

    init(_ apiConfig: APIConfiguration, userId: String) {
        self.apiConfig = apiConfig
        self.userId = userId
    }
    
    var path: String {
        "/v3/users/\(userId)"
    }
}
