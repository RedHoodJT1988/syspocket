//
//  AddWebhookView.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import SwiftUI
import SwiftData

struct AddWebhookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Pass the parent server so SwiftData can link the relationship
    let server: Server
    
    @State private var name: String = ""
    @State private var endpoint: String = "/"
    @State private var method: String = "POST"
    @State private var requiresAuth: Bool = false
    @State private var token: String = ""
    
    let methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Webhook Details")) {
                    TextField("Name (e.g. Restart Nginx", text: $name)
                    TextField("Endpoint (e.g. /api/restart", text: $endpoint)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    Picker("HTTP Method", selection: $method) {
                        ForEach(methods, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("Security"), footer: Text("Tokens are encrypted and stored securely in the device Keychain.")) {
                    Toggle("Requires Bearer Token", isOn: $requiresAuth)
                    
                    if requiresAuth {
                        SecureField("API Token", text: $token)
                    }
                }
            }
            .navigationTitle("Add Webhook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWebhook() }
                        .disabled(name.isEmpty || endpoint.isEmpty || (requiresAuth && token.isEmpty))
                }
            }
        }
    }
    
    private func saveWebhook() {
        // Save to SwiftData
        let newWebhook = Webhook(name: name, endpoint: endpoint, httpMethod: method, requiresAuth: requiresAuth)
        server.webhooks.append(newWebhook) // SwiftData automatically persists relationships
        
        // Save token to Keychain securely if required
        if requiresAuth {
            Task {
                do {
                    try await KeychainManager.shared.save(token: token, forKey: server.id.uuidString)
                } catch {
                    print("Keychain error: \(error)")
                }
            }
        }
        
        dismiss()
    }
}

