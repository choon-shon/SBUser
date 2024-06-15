import Foundation

class AssignmentUserManager: SBUserManager {
    var networkClient: any SBNetworkClient = AssignmentNetworkClient()
    var userStorage: any SBUserStorage =  AssignmentUserStorage()
    
    private var apiConfig: APIConfiguration {
        guard let _apiConfig else {
            fatalError("Please invoke `initApplication(_:)` before any API calls.")
        }
        return _apiConfig
    }
    private var _apiConfig: APIConfiguration?
    
    private var counter: UserCreationCounter = .init()
    
    func initApplication(applicationId: String, apiToken: String) async throws {
        guard !applicationId.isEmpty, !apiToken.isEmpty else {
            throw PackageError.invalidPackageSetupAttempt
        }
        
        if let _apiConfig, _apiConfig.applicationId != applicationId {
            await networkClient.reset()
            await userStorage.reset()
        }
        _apiConfig = .init(applicationId: applicationId, apiToken: apiToken)
    }
    
    func createUser(params: UserCreationParams) async throws -> SBUser {
        try await counter.increment()
        
        do {
            let request = CreateUserRequest(apiConfig, params)
            let response = try await networkClient.request(request: request)
            let createduser = SBUser(response)
            await userStorage.upsertUser(createduser)
            await counter.decrement()
            return createduser
        } catch {
            await counter.decrement()
            throw error
        }
    }
    
    func createUsers(params: [UserCreationParams]) async throws -> [SBUser] {
        try await counter.increment(by: params.count)
        
        var result = [SBUser]()
        for param in params {
            do {
                result.append(try await createUser(params: param))
                await counter.decrement()
            } catch {
                await counter.decrement()
                print("Failed To create \(param.userId). [Error] \(error)")
            }
        }
        return result
    }
    
    func updateUser(params: UserUpdateParams) async throws -> SBUser {
        let request = UpdateUserRequest(apiConfig, params)
        let response = try await networkClient.request(request: request)
        let updatedUser = SBUser(response)
        await userStorage.upsertUser(updatedUser)
        return updatedUser
    }
    
    func getUser(userId: String) async throws -> SBUser {
        try checkUserInfoValidity(userId)
        
        if let cachedUser = await userStorage.getUser(for: userId) {
            return cachedUser
        }
        
        let request = GetUserRequestByID(apiConfig, userId: userId)
        let response = try await networkClient.request(request: request)
        return SBUser(response)
    }
    
    func getUsers(nicknameMatches: String) async throws -> [SBUser] {
        try checkUserInfoValidity(nicknameMatches)
        
        let cachedUsers = await userStorage.getUsers(for: nicknameMatches)
        guard cachedUsers.isEmpty else {
            return cachedUsers
        }
        
        let request = GetUsersByNicknameRequest(apiConfig, nickname: nicknameMatches)
        let response = try await networkClient.request(request: request)
        let users = response.users?.map { SBUser($0) }
        return users ?? []
    }
    
    private func checkUserInfoValidity(_ userNameOrNickname: String) throws {
        if userNameOrNickname.isEmpty {
            throw DataTaskError.emptyStringRequest
        }
        
        if userNameOrNickname.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            throw DataTaskError.whiteSpaceOrNewlineStringRequest
        }
    }
}

private actor UserCreationCounter {
    private var count = 0
    
    func increment(by offset: Int = 1) throws {
        guard count + offset <= GlobalPreference.userCreationCountLimit else {
            throw DataTaskError.exceededUserCreationLimit
        }
        count += offset
    }
    
    func decrement(by offset: Int = 1) {
        count = max(0, count - offset)
    }
}
