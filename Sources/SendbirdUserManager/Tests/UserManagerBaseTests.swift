//
//  UserManagerBaseTests.swift
//  SendbirdUserManager
//
//  Created by Sendbird
//

import Foundation
import XCTest

/// Unit Testing을 위해 제공되는 base test suite입니다.
/// 사용을 위해서는 해당 클래스를 상속받고,
/// `open func userManager() -> SBUserManager?`를 override한뒤, 본인이 구현한 SBUserManager의 인스턴스를 반환하도록 합니다.
open class UserManagerBaseTests: XCTestCase {
    open func userManager() -> SBUserManager? { AssignmentUserManager() }
    
    public let applicationId = "7019EDC9-CEF9-47AC-BA8F-D23C2CF61063"
    public let apiToken = "c8c2d8d8106364397559da5d4c8137e63894bc55"
    
    public func testInitApplicationWithDifferentAppIdClearsData() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        
        // First init
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)    // Note: Add the first application ID and API Token
        
        let userId = UUID().uuidString
        let initialUser = UserCreationParams(userId: userId, nickname: "hello", profileURL: nil)
        let _ = try await userManager.createUser(params: initialUser)

        // Check if the data exist
        let users = await userManager.userStorage.getUsers()
        XCTAssertEqual(users.count, 1, "User should exist with an initial Application ID")
        
        // Second init with a different App ID
        try await userManager.initApplication(applicationId: "AppID2", apiToken: "Token2")    // Note: Add the second application ID and API Token
        
        // Check if the data is cleared
        let clearedUsers = await userManager.userStorage.getUsers()
        XCTAssertEqual(clearedUsers.count, 0, "Data should be cleared after initializing with a different Application ID")
    }
    
    public func testCreateUser() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)
        
        let userId = UUID().uuidString
        let userNickname = UUID().uuidString
        let params = UserCreationParams(userId: userId, nickname: userNickname, profileURL: nil)
        
        let user = try await userManager.createUser(params: params)
       
        XCTAssertNotNil(user)
        XCTAssertEqual(user.nickname, userNickname)
    }
    
    public func testCreateUsers() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId1 = UUID().uuidString
        let userNickname1 = UUID().uuidString
        
        let userId2 = UUID().uuidString
        let userNickname2 = UUID().uuidString
        
        let params1 = UserCreationParams(userId: userId1, nickname: userNickname1, profileURL: nil)
        let params2 = UserCreationParams(userId: userId2, nickname: userNickname2, profileURL: nil)
            
        let users = try await userManager.createUsers(params: [params1, params2])
        
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].nickname, userNickname1)
        XCTAssertEqual(users[1].nickname, userNickname2)
    }
    
    public func testUpdateUser() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId = UUID().uuidString
        let initialUserNickname = UUID().uuidString
        let updatedUserNickname = UUID().uuidString
        
        let initialParams = UserCreationParams(userId: userId, nickname: initialUserNickname, profileURL: nil)
        let updatedParams = UserUpdateParams(userId: userId, nickname: updatedUserNickname, profileURL: nil)
                
        let _ = try await userManager.createUser(params: initialParams)
        let updatedUser = try await userManager.updateUser(params: updatedParams)
        
        XCTAssertEqual(updatedUser.nickname, updatedUserNickname)
    }
    
    public func testGetUser() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId = UUID().uuidString
        let userNickname = UUID().uuidString
        
        let params = UserCreationParams(userId: userId, nickname: userNickname, profileURL: nil)
                
        let createdUser = try await userManager.createUser(params: params)
        let retrievedUser = try await userManager.getUser(userId: createdUser.userId)
        
        XCTAssertEqual(retrievedUser.nickname, userNickname)
    }
    
    public func testGetUsersWithNicknameFilter() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId1 = UUID().uuidString
        let userNickname1 = UUID().uuidString
        
        let userId2 = UUID().uuidString
        let userNickname2 = UUID().uuidString
        
        let params1 = UserCreationParams(userId: userId1, nickname: userNickname1, profileURL: nil)
        let params2 = UserCreationParams(userId: userId2, nickname: userNickname2, profileURL: nil)
        
        let _ = try await userManager.createUsers(params: [params1, params2])
        let users = try await userManager.getUsers(nicknameMatches: userNickname1)
        
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].nickname, userNickname1)
    }
    
    // Test that trying to create more than 10 users at once should fail
    public func testCreateUsersLimit() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let users = (0..<11).map { UserCreationParams(userId: "user_id_\(UUID().uuidString)\($0)", nickname: "nickname_\(UUID().uuidString)\($0)", profileURL: nil) }
                
        do {
            let _ = try await userManager.createUsers(params: users)
            XCTFail("Shouldn't successfully create more than 10 users at once")
        } catch {
            // Ideally, check for a specific error related to the limit
            XCTAssertEqual(error as! DataTaskError, .exceededUserCreationLimit)
        }
    }
    
    // Test race condition when simultaneously trying to update and fetch a user
    public func testUpdateUserRaceCondition() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)

        let userId = UUID().uuidString
        let initialUserNickname = UUID().uuidString
        let updatedUserNickname = UUID().uuidString
        
        let initialParams = UserCreationParams(userId: userId, nickname: initialUserNickname, profileURL: nil)
        let updatedParams = UserUpdateParams(userId: userId, nickname: updatedUserNickname, profileURL: nil)
        
        let expectation1 = self.expectation(description: "Wait for user update")
        let expectation2 = self.expectation(description: "Wait for user retrieval")
        
        let createdUser = try await userManager.createUser(params: initialParams)
            
        Task {
            let _ = try await userManager.updateUser(params: updatedParams)
            expectation1.fulfill()
        }
        
        Task {
            let user = try await userManager.getUser(userId: createdUser.userId)
            XCTAssertTrue(user.nickname == initialUserNickname || user.nickname == updatedUserNickname)
            expectation2.fulfill()
        }
        
       await fulfillment(of: [expectation1, expectation2], timeout: 10.0)
    }
    
    // Test for edge cases where the nickname to be matched is either empty or consists of spaces
    public func testGetUsersWithEmptyNickname() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)
        
        do {
            let _ = try await userManager.getUsers(nicknameMatches: "")
            XCTFail("Fetching users with empty nickname should not succeed")
        } catch {
            // Ideally, check for a specific error related to the invalid nickname
            XCTAssertEqual(error as! DataTaskError, DataTaskError.emptyStringRequest)
        }
    }
    
    public func testRateLimitCreateUser() async throws {
        let userManager = try XCTUnwrap(self.userManager())
        try await userManager.initApplication(applicationId: applicationId, apiToken: apiToken)
        
        // Concurrently create 11 users
        var results: [SBUser?] = []
        await withTaskGroup(of: SBUser?.self) { group in
            for _ in 0..<11 {
                group.addTask {
                    let params = UserCreationParams(userId: UUID().uuidString, nickname: UUID().uuidString, profileURL: nil)
                    let user = try? await userManager.createUser(params: params)
                    return user
                }
            }
            
            for await successfulOrFailedUser in group {
                results.append(successfulOrFailedUser)
            }
        }
        // Assess the results
        let successResults = results.filter { $0 != nil }
        let rateLimitResults = results.filter { $0 == nil }
        
        XCTAssertEqual(successResults.count, 10)
        XCTAssertEqual(rateLimitResults.count, 1)
    }
}
