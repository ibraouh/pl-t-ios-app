//
//  LoginView.swift
//  Plât
//
//  Created by Abe Raouh on 10/18/24.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var fname = ""
    @State private var isSignUp = false
    
    
    var body: some View {
        VStack {
            Text("Plât 🍰")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("Cooking together, one recipe at a time.")
            Text(isSignUp ? "Please sign up below" : "Please login below")
                .foregroundColor(.secondary)
                .padding(.bottom)
            VStack(spacing: 12) {
                if isSignUp {
                    TextField("First Name", text: $fname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Button(action: {
                if isSignUp {
                    authViewModel.signUp(email: email, password: password, fname: fname)
                } else {
                    authViewModel.signIn(email: email, password: password)
                }
            }) {
                Text(isSignUp ? "Sign Up" : "Log In")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.pink, Color.orange]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
            }
            .padding()
            
            Button(action: {
                isSignUp.toggle()
            }) {
                Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}
