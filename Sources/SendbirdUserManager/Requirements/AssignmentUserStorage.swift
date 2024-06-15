import Foundation

typealias UserID = String

actor AssignmentUserStorage: SBUserStorage {
    private var cache = [UserID: SBUser]()
            
    func upsertUser(_ user: SBUser) {
        cache[user.userId] = user
    }
    
    func getUsers() -> [SBUser] {
        cache.values.compactMap { $0 }
    }
    
    func getUsers(for nickname: String) -> [SBUser] {
        cache.values.filter { $0.nickname == nickname }
    }
    
    func getUser(for userId: String) -> (SBUser)? {
        cache[userId]
    }
    
    func reset() {
        cache = [UserID: SBUser]()
    }
}
