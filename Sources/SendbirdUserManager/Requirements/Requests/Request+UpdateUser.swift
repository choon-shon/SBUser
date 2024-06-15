import Foundation

struct UpdateUserRequest: HTTPSendbirdAPIRequest {
    let identifier: UUID = .init()

    typealias Response = SBUserResponse
    
    let apiConfig: APIConfiguration
    let params: UserUpdateParams
    
    init(_ apiConfig: APIConfiguration, _  params: UserUpdateParams) {
        self.apiConfig = apiConfig
        self.params = params
    }
    
    var httpMethod: HTTPMethod { .PUT }

    
    var path: String {
        "/v3/users/\(params.userId)"
    }
    
    var httpBody: Data? {
        let params = ["nickname": params.nickname,
                      "profile_url": params.profileURL]
        let data = try? JSONSerialization.data(withJSONObject: params)
        return data
    }
}

