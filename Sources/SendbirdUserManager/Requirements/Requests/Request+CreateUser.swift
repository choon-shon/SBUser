import Foundation

/// Request for creating a single user.
struct CreateUserRequest: HTTPSendbirdAPIRequest {
    let identifier: UUID = .init()
    
    typealias Response = SBUserResponse
    
    let apiConfig: APIConfiguration
    let params: UserCreationParams
    
    init(_ apiConfig: APIConfiguration, _ params: UserCreationParams) {
        self.apiConfig = apiConfig
        self.params = params
    }
    
    var httpMethod: HTTPMethod {
        .POST
    }
    
    var path: String {
        "/v3/users"
    }
    
    var httpBody: Data? {
        let params = ["user_id": params.userId,
                      "nickname": params.nickname,
                      "profile_url": params.profileURL]
        return try? JSONSerialization.data(withJSONObject: params)
    }
}

