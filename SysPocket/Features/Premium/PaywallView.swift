//
//  PaywallView.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/27/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var store
    
    @State private var isPurchasing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Image(systemName: "server.rack")
                    .font(.system(size: 80))
                    // FIXED: Changed .accent to .accentColor
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 8) {
                    Text("SysPocket Pro")
                        .font(.largeTitle.bold())
                    
                    Text("Unlock unlimited server connections and encrypted token storage.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", text: "Monitor unlimited servers")
                    FeatureRow(icon: "faceid", text: "Biometric App Lock")
                    FeatureRow(icon: "key.fill", text: "Secure Keychain Webhook Headers")
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer()
                
                if let product = store.premiumProduct {
                    Button(action: {
                        Task {
                            isPurchasing = true
                            try? await store.purchase()
                            isPurchasing = false
                            if store.isPremium { dismiss() }
                        }
                    }) {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Subscribe for \(product.displayPrice) / month")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                } else {
                    ProgressView("Loading products...")
                }
            }
            .padding(.top, 40)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                // FIXED: Changed .accent to .accentColor
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .fontWeight(.medium)
        }
    }
}
