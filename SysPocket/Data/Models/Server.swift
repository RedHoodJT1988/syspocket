//
//  Server.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import Foundation
import SwiftData

@Model
final class Server {
    @Attribute(.unique) var id: UUID
    var name: String
    var hostURL: String
    var creationDate: Date
    
    // A server can have many webhooks.
    // .cascade means if the server is deleted, its webhooks are deleted too
    @Relationship(deleteRule: .cascade, inverse: \Webhook.server)
    var webhooks: [Webhook] = []
    
    init(name: String, hostURL: String) {
        self.id = UUID()
        self.name = name
        self.hostURL = hostURL
        self.creationDate = Date()
    }
}
