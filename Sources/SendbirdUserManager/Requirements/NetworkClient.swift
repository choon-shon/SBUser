//
//  NetworkClient.swift
//  
//
//  Created by Sendbird
//

import Foundation

public protocol SBNetworkClient {
    /// 리퀘스트를 요청하고 리퀘스트에 대한 응답을 받아서 전달합니다
    func request<R: HTTPSendbirdAPIRequest>(
        request: R
    ) async throws -> R.Response
    
    /// Removes all cookies & caches.
    func reset() async
}
