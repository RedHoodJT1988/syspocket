//
//  DashboardView.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Server.creationDate, order: .reverse) private var servers: [Server]
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var store
    
    @State private var selectedServer: Server?
    @State private var showingAddSheet = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationSplitView {
            // Check if the database is empty before rendering the list
            Group {
                if servers.isEmpty {
                    ContentUnavailableView(
                        "No Servers Found",
                        systemImage: "network.slash",
                        description: Text("Tap the + icon at the top right to add a server and begin monitoring.")
                    )
                } else {
                    List(selection: $selectedServer) {
                        ForEach(servers) { server in
                            NavigationLink(value: server) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(server.name)
                                        .font(.headline)
                                    Text(server.hostURL)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteServers)
                    }
                }
            }
            .navigationTitle("SysPocket")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        // Enforce the 1-server limit for free users
                        if !store.isPremium && servers.count >= 1 {
                            showingPaywall = true
                        } else {
                            showingAddSheet = true
                        }
                    }) {
                        Label("Add Server", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddServerView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        } detail: {
            if let server = selectedServer {
                ServerDetailView(server: server)
            } else {
                ContentUnavailableView(
                    "No Server Selected",
                    systemImage: "server.rack",
                    description: Text("Select a server from the sidebar or add a new one to begin monitoring.")
                )
            }
        }
    }

    private func deleteServers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(servers[index])
            }
        }
    }
}
