//
//  WebhookClient.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import Foundation

actor WebhookClient {
    static let shared = WebhookClient()
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        self.session = URLSession(configuration: config)
    }
    
    func trigger(fullURL: String, method: String, serverID: UUID, requiresAuth: Bool) async throws -> Int {
        guard let url = URL(string: fullURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if requiresAuth {
            do {
                // FIXED: Now we await the actor boundary crossing using the shared instance
                let token = try await KeychainManager.shared.getToken(forKey: serverID.uuidString)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } catch {
                throw NetworkError.noAuthTokenFound
            }
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(statusCode: 0)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return httpResponse.statusCode
        case 401, 403:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
