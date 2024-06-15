//
//  AssignmentNetworkClient.swift
//
//
//  Created by Choon Shon on 6/15/24.
//

import Foundation

actor AssignmentNetworkClient: SBNetworkClient {
    private var latestScheduledTime: Date = .init()

    private let urlSession: URLSession
    
    init(urlSession: URLSession = .init(configuration: .default)) {
        self.urlSession = urlSession
        urlSession.configuration.urlCache = .init()
    }
    
    /// Empties all cookies & caches.
    func reset() async {
        await urlSession.reset()
    }
    
    func request<R: HTTPSendbirdAPIRequest>(
        request: R
    ) async throws -> R.Response {
        print("🌐 Attemping... \(Date()) [\(request)]")

        await delayRequestIfNeeded(request)
        try Task.checkCancellation()

        print("🌐 Sending... [\(request.identifier)]")
        
        let urlRequest = try request.makeURLRequest()
        let (data, response)  = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            let error = ServerResponseError(data)
            print("🌐 Failed. [\(request.identifier)]  \(httpResponse) \(error)")
            throw ServerResponseError(data)
        }
        print("🌐 Succeeded. [\(request.identifier)]\n")
        
        return try JSONDecoder().decode(R.Response.self, from: data)
    }
    
    private func delayRequestIfNeeded<R: HTTPSendbirdAPIRequest>(
        _ request: R
    ) async {
        let rate = TimeInterval(GlobalPreference.dataTaskRateInSeconds)
        let secsSinceLatest = Date().timeIntervalSince(latestScheduledTime)
        let shorterThanRate = secsSinceLatest < rate
        guard shorterThanRate else {
            self.latestScheduledTime = .init()
            return
        }
        
        latestScheduledTime.addTimeInterval(TimeInterval(rate))
        print("🌐 Delayed until \(latestScheduledTime). [\(request.identifier)] ")
        try? await Task.sleep(until: latestScheduledTime)
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(until dueDate: Date) async throws {
        let timeOffset = dueDate.timeIntervalSinceNow
        try await Task.sleep(nanoseconds: UInt64(timeOffset * 1_000_000_000))
    }
}


