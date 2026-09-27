//
//  LockScreenView.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/27/26.
//

import SwiftUI

struct LockScreenView: View {
    var biometricService: BiometricService
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("SysPocket is Locked")
                .font(.title2.bold())
            
            if let error = biometricService.authenticationError {
                Text(error)
                    .font(.callout)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                biometricService.authenticate()
            }) {
                Text("Unlock")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            biometricService.authenticate()
        }
    }
}
