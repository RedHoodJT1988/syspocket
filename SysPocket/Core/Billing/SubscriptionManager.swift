//
//  SubscriptionManager.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/27/26.
//

import Foundation
import StoreKit
import SwiftUI

@Observable
@MainActor
final class SubscriptionManager {
    let productID = "com.yourname.syspocket.premium" // Update to match your .storekit file
    
    var isPremium = false
    var premiumProduct: Product?
    var hasLoaded = false
    
    private var updateListenerTask: Task<Void, Never>? = nil
    
    init() {
        // Start listening for transactions that happen outside the app (e.g., auto-renewals)
        updateListenerTask = listenForTransactions()
    }
    
    // NOTE: `deinit` was removed here. Because this object is held in @State at the
    // App root, it lives for the lifetime of the app and never deallocates,
    // making manual task cancellation unnecessary and avoiding Swift 6 isolation errors.
    
    func loadProducts() async {
        guard !hasLoaded else { return }
        do {
            let storeProducts = try await Product.products(for: [productID])
            self.premiumProduct = storeProducts.first
            await checkActiveSubscription()
            self.hasLoaded = true
        } catch {
            print("Failed to load StoreKit products: \(error)")
        }
    }
    
    func purchase() async throws {
        guard let product = premiumProduct else { return }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check if the transaction is cryptographically signed by Apple
            let transaction = try checkVerified(verification)
            // Deliver the premium content
            self.isPremium = true
            // Tell StoreKit we have delivered the content
            await transaction.finish()
            
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func checkActiveSubscription() async {
        // Look through all active entitlements
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == self.productID {
                self.isPremium = true
                return
            }
        }
        self.isPremium = false
    }
    
    // Background listener for renewals or revokes
    private func listenForTransactions() -> Task<Void, Never> {
        // Task.detached runs completely off the MainActor
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    // This is now perfectly safe because checkVerified is nonisolated
                    let transaction = try self.checkVerified(result)
                    
                    // We must `await` checkActiveSubscription because it is on the MainActor
                    await self.checkActiveSubscription()
                    
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    // FIXED: Added `nonisolated` so the detached task can securely run this math check off the main thread.
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
