//
//  AddServerView.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import SwiftUI
import SwiftData

struct AddServerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var hostURL: String = "https://"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Server Details")) {
                    TextField("Server Name (e.g. Production API)", text: $name)
                    TextField("Host URL", text: $hostURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveServer()
                    }
                    .disabled(name.isEmpty || hostURL.isEmpty)
                }
            }
        }
    }
    
    private func saveServer() {
        let newServer = Server(name: name, hostURL: hostURL)
        modelContext.insert(newServer)
        dismiss()
    }
}
