//
//  ServerMonitor.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import Foundation

/// Represents the real-time health of a server
enum ServerStatus: Sendable {
    case checking
    case online(latency: TimeInterval)
    case offline(error: NetworkError)
}

final class ServerMonitor: Sendable {
    static let shared = ServerMonitor()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0 // Very aggressive timeout for pings
        // Force the network to ignore cache so we get accurate, real-time latency
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.session = URLSession(configuration: config)
    }
    
    /// Starts a continuous ping cycle yielding status updates to the UI.
    func startPingStream(hostURL: String, interval: TimeInterval = 10.0) -> AsyncStream<ServerStatus> {
        return AsyncStream { continuation in
            let task = Task {
                guard let url = URL(string: hostURL) else {
                    continuation.yield(.offline(error: .invalidURL))
                    continuation.finish()
                    return
                }

                // Keep looping until the view listening to this stream cancels the task
                while !Task.isCancelled {
                    continuation.yield(.checking)
                    
                    var request = URLRequest(url: url)
                    // HEAD requests retrieve headers only—saving bandwidth and server load
                    request.httpMethod = "HEAD"
                    
                    let startTime = Date()
                    
                    do {
                        let (_, response) = try await session.data(for: request)
                        
                        if let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode {
                            // Calculate the exact time the round-trip took
                            let latency = Date().timeIntervalSince(startTime)
                            continuation.yield(.online(latency: latency))
                        } else {
                            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                            continuation.yield(.offline(error: .serverError(statusCode: statusCode)))
                        }
                    } catch {
                        continuation.yield(.offline(error: .timeout))
                    }
                    
                    // Pause the loop for the duration of the interval
                    do {
                        // Task.sleep takes nanoseconds, so we convert the TimeInterval (seconds)
                        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    } catch {
                        // If the task is cancelled while sleeping, exit the loop cleanly
                        break
                    }
                }
                
                // If the loop breaks, finish the stream
                continuation.finish()
            }
            
            // If the SwiftUI view disappears and stops listening, cancel the background ping task
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
