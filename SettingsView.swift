//
//  SettingsView.swift
//  Plât
//
//  Created by Abe Raouh on 10/18/24.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct SettingsView: View {
    @StateObject private var authViewModel = AuthViewModel() // Assuming AuthViewModel is available

    var body: some View {
        NavigationView {
            VStack {
                // Profile Information Section
                List {
                    Section {
                        NavigationLink(destination: AccountSettingsView(authViewModel: authViewModel)) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: authViewModel.userData["avatarColor"] as? String ?? "#E0E0E0"))
                                        .frame(width: 50, height: 50)
                                    
                                    Text(authViewModel.userData["avatarEmoji"] as? String ?? "🍰")
                                        .font(.largeTitle)
                                }
                                .padding(.trailing, 10)
                                
                                VStack(alignment: .leading) {
                                    Text(authViewModel.userData["fname"] as? String ?? "No User name in DB")
                                        .font(.headline)
                                    Text(authViewModel.userData["email"] as? String ?? "No Email in DB")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }

                    
                    Section(header: Text("Recipes")) {
                        NavigationLink(destination: SavedRecipesView() ) {
                            Text("Saved Recipes")
                        }

                        NavigationLink(destination: PlannedRecipesView()) {
                            Text("Planned for this Week")
                        }
                    }
                    
                    Section(header: Text("Information")) {
                        NavigationLink(destination: AboutView()) {
                            Text("About")
                        }
                        NavigationLink(destination: ContactUsView()) {
                            Text("Contact Us")
                        }
                    }
                    
                    Section {
                        // Sign Out Button
                        Button(action: {
                            authViewModel.signOut { error in
                                if let error = error {
                                    print("Error signing out: \(error.localizedDescription)")
                                } else {
                                    print("Successfully signed out")
                                }
                            }
                        }) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = hex.hasPrefix("#") ? 1 : 0
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

extension Color {
    func toHexString() -> String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}


struct AccountSettingsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var firstName: String
    @State private var avatarEmoji: String
    @State private var avatarColor: Color

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        _firstName = State(initialValue: authViewModel.userData["fname"] as? String ?? "No User name in DB")
        _avatarEmoji = State(initialValue: authViewModel.userData["avatarEmoji"] as? String ?? "🍰")
        _avatarColor = State(initialValue: Color(hex: authViewModel.userData["avatarColor"] as? String ?? "#E0E0E0"))
    }

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("First Name", text: $firstName)
            }
            
            Section(header: Text("Avatar Customization")) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(avatarColor)
                            .frame(width: 50, height: 50)
                        
                        TextField("Emoji", text: $avatarEmoji)
                            .multilineTextAlignment(.center)
                            .font(.largeTitle)
                    }
                    .padding()
                    
                    ColorPicker("Pick Background Color", selection: $avatarColor)
                }
            }
            
            Button(action: {
                // Save changes to Firestore
                let colorHex = avatarColor.toHexString()
                authViewModel.updateAvatar(emoji: avatarEmoji, color: colorHex)
                if let uid = authViewModel.user?.uid {
                    authViewModel.db.collection("users").document(uid).updateData(["fname": firstName])
                }
            }) {
                Text("Save Changes")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Welcome Message
                Text("Welcome to Plât!")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("""
Plât is your ultimate hub for discovering, saving, and sharing delicious recipes from around the world. Whether you're a seasoned chef or just starting in the kitchen, Plât is designed to inspire your culinary journey.
""")
                    .font(.body)
                    .foregroundColor(.secondary)

                // Key Features
                Text("Key Features")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                VStack(alignment: .leading, spacing: 8) {
                    AboutFeatureRow(title: "Discover Recipes", description: "Browse through a curated feed of recipes, or search for specific dishes by name, category, or region.")
                    AboutFeatureRow(title: "Save Your Favorites", description: "Bookmark recipes you love for quick and easy access anytime.")
                    AboutFeatureRow(title: "Plan Your Week", description: "Organize your weekly meals by scheduling recipes and building a personalized plan.")
                    AboutFeatureRow(title: "Generate Shopping list", description: "Generate a list of groceries organized by grocery store isle using Open AI's GPT model.")
                    AboutFeatureRow(title: "Share Recipes", description: "Share your favorite recipes with friends and family through social media or direct links.")
                    AboutFeatureRow(title: "Customizable Profile", description: "Personalize your avatar and make the app uniquely yours.")
                    AboutFeatureRow(title: "Explore Cuisine by Region", description: "Discover regional and cultural recipes with just a few taps.")
                }

                // Mission
                Text("Our Mission")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                Text("""
Plât is built with a passion for connecting people through food. Our goal is to make cooking fun, accessible, and community-driven. Whether you're experimenting with a new dish or perfecting a classic, Plât is here to help.
""")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Built With
                Text("Built With")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                VStack(alignment: .leading, spacing: 8) {
                    Text("• **Technology Stack**: Swift, Firebase, and SDWebImage for a smooth and intuitive experience.")
                    Text("• **Powered By**: MealDB API for an extensive recipe database, plus a user made database (feature to come in V2)")
                }
                .font(.body)
                .foregroundColor(.secondary)

                // Version
                Text("Version")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                Text("• **Plât Version**: 1.0.0\n• **Last Updated**: 11/30/2024")
                    .font(.body)
                    .foregroundColor(.secondary)

                // Support
                Text("Support")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                Text("""
If you have any questions, feedback, or ideas, we'd love to hear from you!
📧 **Contact Us**: abe+plat@raouh.com
🌐 **Website**: www.raouh.com
""")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("About Plât")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutFeatureRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("• \(title)")
                .font(.headline)
                .foregroundColor(.primary)
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}


struct ContactUsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Support")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                Text("""
If you have any questions, feedback, or ideas, we'd love to hear from you!
📧 **Contact Us**: abe+plat@raouh.com
🌐 **Website**: www.raouh.com
""")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        
    }
}


struct SavedRecipesView: View {
    @State private var savedRecipes: [Recipe] = []
    @State private var selectedRecipe: Recipe?
    @State private var isLoading = true // Track loading state

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Recipes...")
                    .font(.title3)
                    .padding()
            } else if savedRecipes.isEmpty {
                Text("No Saved Recipes")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(savedRecipes) { recipe in
                            RecipeCardView(recipe: recipe)
                                .onTapGesture {
                                    selectedRecipe = recipe
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Recipes")
        .onAppear(perform: fetchSavedRecipes)
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }

    private func fetchSavedRecipes() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)

        userDocRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching saved recipes: \(error)")
                isLoading = false // Stop loading on error
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                let data = snapshot.data()
                if let recipeIDs = data?["savedRecipes"] as? [String] {
                    fetchRecipes(for: recipeIDs)
                } else {
                    isLoading = false // No saved recipes found
                }
            } else {
                isLoading = false // No snapshot found
            }
        }
    }

    private func fetchRecipes(for recipeIDs: [String]) {
        let baseURL = "https://www.themealdb.com/api/json/v1/1/lookup.php?i="
        var fetchedRecipes: [Recipe] = []

        Task {
            for recipeID in recipeIDs {
                if let url = URL(string: "\(baseURL)\(recipeID)") {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let decodedResponse = try? JSONDecoder().decode(RecipeResponse.self, from: data),
                           let recipe = decodedResponse.meals.first {
                            fetchedRecipes.append(recipe)
                        }
                    } catch {
                        print("Error fetching recipe \(recipeID): \(error)")
                    }
                }
            }

            DispatchQueue.main.async {
                savedRecipes = fetchedRecipes
                isLoading = false // Stop loading after recipes are fetched
            }
        }
    }
}


struct PlannedRecipesView: View {
    @State private var plannedRecipes: [Recipe] = []
    @State private var selectedRecipe: Recipe?
    @State private var isLoading = true // State to track loading status

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Recipes...")
                    .font(.title3)
                    .padding()
            } else if plannedRecipes.isEmpty {
                Text("No Planned Recipes")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(plannedRecipes) { recipe in
                            RecipeCardView(recipe: recipe)
                                .onTapGesture {
                                    selectedRecipe = recipe
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("Planned Recipes")
        .onAppear(perform: fetchPlannedRecipes)
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }

    private func fetchPlannedRecipes() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)

        userDocRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching planned recipes: \(error)")
                isLoading = false // Stop loading if there's an error
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                let data = snapshot.data()
                if let recipeIDs = data?["planned_unscheduled"] as? [String] {
                    fetchRecipes(for: recipeIDs)
                } else {
                    isLoading = false // No planned recipes found
                }
            } else {
                isLoading = false // No snapshot found
            }
        }
    }

    private func fetchRecipes(for recipeIDs: [String]) {
        let baseURL = "https://www.themealdb.com/api/json/v1/1/lookup.php?i="
        var fetchedRecipes: [Recipe] = []

        Task {
            for recipeID in recipeIDs {
                if let url = URL(string: "\(baseURL)\(recipeID)") {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let decodedResponse = try? JSONDecoder().decode(RecipeResponse.self, from: data),
                           let recipe = decodedResponse.meals.first {
                            fetchedRecipes.append(recipe)
                        }
                    } catch {
                        print("Error fetching recipe \(recipeID): \(error)")
                    }
                }
            }

            DispatchQueue.main.async {
                plannedRecipes = fetchedRecipes
                isLoading = false // Stop loading after fetching recipes
            }
        }
    }
}
