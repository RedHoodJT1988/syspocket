//
//  NetworkError.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(statusCode: Int)
    case timeout
    case noAuthTokenFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The constructed URL is invalid."
        case .unauthorized:
            return "Unauthorized. Check your API token."
        case .serverError(let code):
            return "Server returned an error: \(code)"
        case .timeout:
            return "The request timed out."
        case .noAuthTokenFound:
            return "Authentication required but no token found in the Keychain."
        }
    }
}
