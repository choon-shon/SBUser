//
//  UserStorageBaseTests.swift
//  SendbirdUserManager
//
//  Created by Sendbird
//

import Foundation
import XCTest

/// Unit Testing을 위해 제공되는 base test suite입니다.
/// 사용을 위해서는 해당 클래스를 상속받고,
/// `open func userStorage() -> SBUserStorage?`를 override한뒤, 본인이 구현한 SBUserStorage의 인스턴스를 반환하도록 합니다.
open class UserStorageBaseTests: XCTestCase {
    open func userStorage() -> SBUserStorage? { AssignmentUserStorage() }
    
    public func testSetUser() async throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let user = SBUser(userId: "1")
        await storage.upsertUser(user)
        
        let user1 = await storage.getUser(for: "1")
        XCTAssert(user1?.userId == "1")
        
        
        let users = await storage.getUsers()
        XCTAssert(users.first?.userId == "1")
    }
    
    
    public func testSetAndGetUser() async throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let user = SBUser(userId: "1")
        await storage.upsertUser(user)
        
        let retrievedUser = await storage.getUser(for: user.userId)
        XCTAssertEqual(user.nickname, retrievedUser?.nickname)
    }
    
    public func testGetAllUsers() async throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let users = [SBUser(userId: "1"), SBUser(userId: "2")]
        
        for user in users {
            await storage.upsertUser(user)
        }
        
        let retrievedUsers = await storage.getUsers()
        XCTAssertEqual(users.count, retrievedUsers.count)
    }
    
    public func testThreadSafety() throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let user = SBUser(userId: "1")
        
        let expectation = self.expectation(description: "Updating storage from multiple threads")
        expectation.expectedFulfillmentCount = 2
        
        let queue1 = DispatchQueue(label: "com.test.queue1")
        let queue2 = DispatchQueue(label: "com.test.queue2")
        
        queue1.async {
            for _ in 0..<1000 {
                Task { await storage.upsertUser(user) }
            }
            expectation.fulfill()
        }
        
        queue2.async {
            for _ in 0..<1000 {
                Task { _ = await storage.getUser(for: user.userId) }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    public func testConcurrentWrites() throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let expectation = self.expectation(description: "Concurrent writes")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            Task {
                let user = SBUser(userId: "\(i)")
                await storage.upsertUser(user)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    public func testConcurrentReads() async throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let user = SBUser(userId: "1")
        await storage.upsertUser(user)
        
        let expectation = self.expectation(description: "Concurrent reads")
        expectation.expectedFulfillmentCount = 10
        
        for _ in 0..<10 {
            Task {
                _ = await storage.getUser(for: user.userId)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10, enforceOrder: false)
    }
    
    public func testMixedReadsAndWrites() throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let expectation = self.expectation(description: "Mixed reads and writes")
        expectation.expectedFulfillmentCount = 20
        
        for i in 0..<10 {
            Task {
                let user = SBUser(userId: "\(i)")
                await storage.upsertUser(user)
                expectation.fulfill()
            }
            
            Task {
                _ = await storage.getUser(for: "\(i)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    public func testPerformanceOfSetUser() throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let user = SBUser(userId: "1")
        
        measure(metrics: [XCTClockMetric()]) {
            let expectation = expectation(description: "Measure upsertUser() performance")
            
            for i in 0..<1_000 {
                Task {
                    await storage.upsertUser(user)
                    if i == 999 {
                        expectation.fulfill()
                    }
                }
            }
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
    
    public func testPerformanceOfGetUser() async throws {
        let storage = try XCTUnwrap(self.userStorage())
        let user = SBUser(userId: "1")
        
        await storage.upsertUser(user)
        
        measure(metrics: [XCTClockMetric()]) {
            let expectation = expectation(description: "Measure getUser() performance")
            
            for i in 0..<1_000 {
                Task {
                    _ =  await storage.getUser(for: user.userId)
                    if i == 999 {
                        expectation.fulfill()
                    }
                }
            }
            wait(for: [expectation], timeout: 10)
        }
    }
    
    public func testPerformanceOfGetAllUsers() async throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        for i in 0..<1_000 {
            let user = SBUser(userId: "\(i)")
            await storage.upsertUser(user)
        }
        
        measure(metrics: [XCTClockMetric()]) {
            let expectation = self.expectation(description: "Async function completes")
            Task {
                _ = await storage.getUsers()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }

    
    public func testStress() async throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let user = SBUser(userId: "1")
        
        for _ in 0..<10_000 {
           await storage.upsertUser(user)
            _ = await storage.getUser(for: user.userId)
        }
    }
    
    public func testInterleavedSetAndGet() throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let expectation = self.expectation(description: "Interleaved set and get")
        expectation.expectedFulfillmentCount = 20
        
        for i in 0..<10 {
            let user = SBUser(userId: "\(i)")
            
            Task {
                await storage.upsertUser(user)
                expectation.fulfill()
            }
            
            Task {
                // Here we will wait for a brief moment to let the setUser operation potentially finish.
                // In real scenarios, this delay might not guarantee the order of operations, but for testing purposes it's useful.
                usleep(1000)
                
                let retrievedUser = await storage.getUser(for: "\(i)")
                XCTAssertEqual(user.userId, retrievedUser?.userId)
                XCTAssertEqual(user.nickname, retrievedUser?.nickname)
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    public func testBulkSetsAndSingleGet() throws {
        let storage = try XCTUnwrap(self.userStorage())
        
        let setExpectation = self.expectation(description: "Bulk sets")
        setExpectation.expectedFulfillmentCount = 10
        
        let users: [SBUser] = (0..<10).map { SBUser(userId: "\($0)") }
        
        for user in users {
            Task {
                await storage.upsertUser(user)
                setExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        
        // Now that all set operations have been fulfilled, we retrieve them on a different thread
        Task {
            let retrievedUsers = await storage.getUsers()
            
            XCTAssertEqual(users.count, retrievedUsers.count)
            
            for user in users {
                XCTAssertTrue(retrievedUsers.contains(where: { $0.userId == user.userId && $0.nickname == user.nickname }) )
            }
        }
    }
}
