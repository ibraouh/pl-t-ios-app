//
//  AuthViewModel.swift
//  Plât
//
//  Created by Abe Raouh on 10/18/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: FirebaseAuth.User?
    @Published var errorMessage: String?
    @Published var userData: [String: Any] = [:]
    private var listener: ListenerRegistration?
    
    let db = Firestore.firestore()
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            self?.user = user
            if let user = user {
                self?.loadUserData(uid: user.uid)
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = result?.user {
                self.loadUserData(uid: user.uid)
            }
        }
    }
    
    func signUp(email: String, password: String, fname: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let user = result?.user {
                self.saveUserToFirestore(uid: user.uid, fname: fname, email: email)
            }
        }
    }
    
    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            userData = [:]
            completion(nil)
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    private func saveUserToFirestore(uid: String, fname: String, email: String) {
        let defaultAvatarEmoji = "🍰"
        let defaultAvatarColor = "#E0E0E0" // Hex string for default color
        
        let userData: [String: Any] = [
            "uid": uid,
            "fname": fname,
            "email": email,
            "avatarEmoji": defaultAvatarEmoji,
            "avatarColor": defaultAvatarColor,
            "createdAt": Timestamp()
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                print("User data saved successfully!")
                self.userData = userData
            }
        }
    }
    
    private func loadUserData(uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error loading user data: \(error.localizedDescription)")
            } else if let snapshot = snapshot, let data = snapshot.data() {
                DispatchQueue.main.async {
                    self.userData = data
                }
            }
        }
    }
    
    func updateAvatar(emoji: String, color: String) {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).updateData([
            "avatarEmoji": emoji,
            "avatarColor": color
        ]) { error in
            if let error = error {
                print("Error updating avatar: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.userData["avatarEmoji"] = emoji
                    self.userData["avatarColor"] = color
                }
            }
        }
    }
}
