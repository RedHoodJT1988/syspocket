//
//  Webhook.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import Foundation
import SwiftData

@Model
final class Webhook {
    @Attribute(.unique) var id: UUID
    var name: String
    var endpoint: String
    var httpMethod: String
    
    // If true, the NetworkService will know to fetch the token from the Keychain
    var requiresAuth: Bool
    var creationDate: Date
    
    // The parent server this webhook belongs to
    var server: Server?
    
    init(name: String, endpoint: String, httpMethod: String = "POST", requiresAuth: Bool = false) {
        self.id = UUID()
        self.name = name
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.requiresAuth = requiresAuth
        self.creationDate = Date()
    }
}
