//
//  BiometricService.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/27/26.
//

import Foundation
import LocalAuthentication

@Observable
@MainActor
final class BiometricService {
    var isUnlocked: Bool = false
    var authenticationError: String?
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Check if the device has a passcode or biometrics enabled
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock SysPocket to securely access your servers."
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                Task { @MainActor in
                    if success {
                        self.isUnlocked = true
                        self.authenticationError = nil
                    } else {
                        self.authenticationError = authError?.localizedDescription ?? "Authentication failed."
                    }
                }
            }
        } else {
            self.authenticationError = "Device security is not configured. Please set a passcode in Settings."
        }
    }
    
    func lock() {
        isUnlocked = false
    }
}
