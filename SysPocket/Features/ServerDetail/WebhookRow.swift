//
//  WebhookRow.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import SwiftUI

struct WebhookRow: View {
    let webhook: Webhook
    let server: Server
    
    @State private var isExecuting: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(webhook.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(webhook.httpMethod)
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text(webhook.endpoint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // The Execution UI
            if isExecuting {
                ProgressView()
                    .padding(.trailing, 8)
            } else if showSuccess {
                Image(systemName: "cehckmark.circle.fill")
                    .foregroundColor(.green)
                    .imageScale(.large)
                    .transition(.scale)
            } else {
                Button(action: executeWebhook) {
                    Text("Trigger")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .alert("Webhook Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred.")
        }
    }
    
    private func executeWebhook() {
        // Construct the full URL safely
        guard let baseURL = URL(string: server.hostURL) else { return }
        let fullURL = baseURL.appendingPathComponent(webhook.endpoint).absoluteString
        
        isExecuting = true
        showSuccess = false
        
        Task {
            do {
                // Call our network engine
                let _ = try await WebhookClient.shared.trigger(
                    fullURL: fullURL,
                    method: webhook.httpMethod,
                    serverID: server.id,
                    requiresAuth: webhook.requiresAuth
                )
                
                // Show success animation
                withAnimation {
                    isExecuting = false
                    showSuccess = true
                }
                
                // Reset success mark after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation { showSuccess = false }
            } catch let error as NetworkError {
                isExecuting = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } catch {
                isExecuting = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
