//
//  ServerDetailView.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import SwiftUI
import SwiftData

struct ServerDetailView: View {
    let server: Server
    
    @State private var status: ServerStatus = .checking
    @State private var showingAddWebhook = false
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    statusIcon
                    
                    VStack(spacing: 4) {
                        Text(statusText)
                            .font(.title2.bold())
                        
                        Text(server.hostURL)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            Section(header: Text("Webhooks")) {
                if server.webhooks.isEmpty {
                    Text("No webhooks configured.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(server.webhooks) { webhook in
                        Text(webhook.name)
                    }
                }
            }
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddWebhook = true }) {
                    Label("Add Webhook", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddWebhook) {
            AddWebhookView(server: server)
        }
        .task(id: server.id) {
            // Start the stream
            let stream = ServerMonitor.shared.startPingStream(hostURL: server.hostURL, interval: 5.0)
            
            // Await new values as they are yielded by the network layer
            for await newStatus in stream {
                // Animate the UI transition between online/offline states
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.status = newStatus
                }
            }
        }
    }
    
    private func deleteWebhooks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                server.webhooks.remove(at: index)
            }
        }
    }
    
    // MARK: - UI Helpers

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 80, height: 80)
            
            Image(systemName: statusImageName)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .checking: return .orange
        case .online: return .green
        case .offline: return .red
        }
    }
    
    private var statusImageName: String {
        switch status {
        case .checking: return "arrow.triangle.2.circlepath"
        case .online: return "server.rack"
        case .offline: return "exclamationmark.triangle"
        }
    }
    
    private var statusText: String {
        switch status {
        case .checking:
            return "Checking health..."
        case.online(let latency):
            let ms = Int(latency * 1000)
            return "Online • \(ms)ms"
        case .offline(let error):
            return error.localizedDescription
        }
    }
}

