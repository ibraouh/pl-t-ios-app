//
//  RecipeFeedView.swift
//  Plât
//
//  Created by Abe Raouh on 10/18/24.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Recipe: Identifiable, Codable {
    let idMeal: String
    let strMeal: String
    let strCategory: String?
    let strArea: String?
    let strInstructions: String
    let strMealThumb: String
    let strTags: String?
    let strYoutube: String?
    let strSource: String?
    
    // Ingrediets and Measure properties
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strIngredient9: String?
    let strIngredient10: String?
    let strIngredient11: String?
    let strIngredient12: String?
    let strIngredient13: String?
    let strIngredient14: String?
    let strIngredient15: String?
    let strIngredient16: String?
    let strIngredient17: String?
    let strIngredient18: String?
    let strIngredient19: String?
    let strIngredient20: String?
    
    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    let strMeasure6: String?
    let strMeasure7: String?
    let strMeasure8: String?
    let strMeasure9: String?
    let strMeasure10: String?
    let strMeasure11: String?
    let strMeasure12: String?
    let strMeasure13: String?
    let strMeasure14: String?
    let strMeasure15: String?
    let strMeasure16: String?
    let strMeasure17: String?
    let strMeasure18: String?
    let strMeasure19: String?
    let strMeasure20: String?
    
    // Map API keys to user-friendly properties
    var id: String { idMeal } // Conform to `Identifiable`
    var name: String { strMeal }
    var category: String? { strCategory }
    var area: String? { strArea }
    var instructions: String { strInstructions }
    var thumbnail: String { strMealThumb }
    var tags: String? { strTags }
    var yt: String? { strYoutube }
    var link: String? { strSource }
    
    var ingredients: [(quantity: String, ingredient: String)] {
            var result: [(String, String)] = []
            for i in 1...20 {
                // Use reflection to dynamically access the properties
                let ingredientKey = Mirror(reflecting: self).children.first { $0.label == "strIngredient\(i)" }?.value as? String
                let measureKey = Mirror(reflecting: self).children.first { $0.label == "strMeasure\(i)" }?.value as? String

                // Append only if both ingredient and measure are non-empty
                if let ingredient = ingredientKey, !ingredient.isEmpty,
                   let measure = measureKey, !measure.isEmpty {
                    result.append((measure, ingredient))
                }
            }
            return result
        }
}
    

class RecipeFeedViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    private var hasFetchedRecipes = false
    
    func fetchRecipes() async {
        guard !hasFetchedRecipes else { return }
        hasFetchedRecipes = true
        
        var fetchedRecipes: [Recipe] = []
        let url = URL(string: "https://www.themealdb.com/api/json/v1/1/random.php")!
        
        for _ in 1...20 {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let decodedResponse = try? JSONDecoder().decode(RecipeResponse.self, from: data),
                   let meal = decodedResponse.meals.first {
                    fetchedRecipes.append(meal)
                }
            } catch {
                print("Error fetching recipe: \(error)")
            }
        }
        
        // Update the published recipes list on the main thread
        DispatchQueue.main.async {
            self.recipes = fetchedRecipes
        }
    }
    func refreshRecipes() async {
        hasFetchedRecipes = false
        await fetchRecipes()
    }
}

struct RecipeResponse: Codable {
    let meals: [Recipe]
}

struct RecipeFeedView: View {
    @StateObject private var viewModel = RecipeFeedViewModel()
    @State private var isLoading = true
    @State private var selectedRecipe: Recipe?
    @State private var randomGifNumber = Int.random(in: 1...7)
        
    var body: some View {
            NavigationView {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemTeal).opacity(0.3),
                            Color(.systemBackground)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    if viewModel.recipes.isEmpty {
                        VStack {
                            Spacer()
                            AnimatedImage(url: URL(string: "https://i.imgur.com/xubCvvV.gif"), placeholderImage: .init(systemName: "photo"))
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                            Text("Loading Recipes...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 3) {
                                ForEach(viewModel.recipes) { recipe in
                                    RecipeCardView(recipe: recipe)
                                        .onTapGesture {
                                            selectedRecipe = recipe
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                        .refreshable {
                            await viewModel.refreshRecipes()
                        }
                    }
                }
                .navigationTitle("Food Feed 🥦")
                .onAppear {
                    Task {
                        isLoading = true
                        await viewModel.fetchRecipes()
                        isLoading = false
                    }
                }
                .sheet(item: $selectedRecipe) { recipe in RecipeDetailView(recipe: recipe)}
            }
        }
    }

struct RecipeCardView: View {
    let recipe: Recipe
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isSaved = false
    @State private var isPlanned = false

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack {
                    // Recipe Thumbnail
                    AsyncImage(url: URL(string: recipe.thumbnail)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .cornerRadius(8)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                    
                    // Save and Plan Buttons
                    HStack {
                        // Save Button
                        Button(action: {
                            toggleSave()
                        }) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundColor(isSaved ? .blue : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer().frame(width: 20)

                        // Plan Button
                        Button(action: {
                            togglePlan()
                        }) {
                            Image(systemName: isPlanned ? "calendar.badge.minus" : "calendar.badge.plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(isPlanned ? .green : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer().frame(width: 18)
                        
                        // Share Button
                        ShareLink(item: generateShareableContent(for: recipe)) {
                            Image(systemName: "paperplane")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 8)

                }

                // Recipe Title and Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    
                    if let category = recipe.category {
                        Text("Category: \(category)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let area = recipe.area, area != "Unknown" {
                        Text("Cuisine: \(area)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                    }
                    
                    HStack {
                        if let link = recipe.link {
                            Button(action: {
                                if let url = URL(string: link) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Label("Link", systemImage: "link")
                                    .font(.subheadline)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer().frame(width: 20)
                        }
                        
                        if let yt = recipe.yt {
                            Button(action: {
                                if let url = URL(string: yt) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Label("YouTube", systemImage: "play.rectangle")
                                    .font(.subheadline)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear(perform: checkSavedAndPlannedStatus)
    }
    
    private func generateShareableContent(for recipe: Recipe) -> String {
        var shareText = "Check out this recipe I found on Plât: \(recipe.name)\n"
        if let link = recipe.link {
            shareText += "\(link)"
        }
        return shareText
    }
    
    private func checkSavedAndPlannedStatus() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)
        
        userDocRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                let data = snapshot.data()
                
                // Check if recipe is saved
                if let savedRecipes = data?["savedRecipes"] as? [String] {
                    isSaved = savedRecipes.contains(recipe.idMeal)
                }
                
                // Check if recipe is planned
                if let plannedRecipes = data?["planned_unscheduled"] as? [String] {
                    isPlanned = plannedRecipes.contains(recipe.idMeal)
                }
            }
        }
    }
    
    private func toggleSave() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)
        
        if isSaved {
            // Remove from saved
            userDocRef.updateData([
                "savedRecipes": FieldValue.arrayRemove([recipe.idMeal])
            ]) { error in
                if let error = error {
                    print("Error removing saved recipe: \(error)")
                } else {
                    isSaved = false
                }
            }
        } else {
            // Add to saved
            userDocRef.updateData([
                "savedRecipes": FieldValue.arrayUnion([recipe.idMeal])
            ]) { error in
                if let error = error {
                    print("Error saving recipe: \(error)")
                } else {
                    isSaved = true
                }
            }
        }
    }
        
    private func togglePlan() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)
        
        if isPlanned {
            // Remove from planned_unscheduled
            userDocRef.updateData([
                "planned_unscheduled": FieldValue.arrayRemove([recipe.idMeal])
            ]) { error in
                if let error = error {
                    print("Error removing planned recipe: \(error)")
                } else {
                    isPlanned = false
                }
            }
        } else {
            // Add to planned_unscheduled
            userDocRef.updateData([
                "planned_unscheduled": FieldValue.arrayUnion([recipe.idMeal])
            ]) { error in
                if let error = error {
                    print("Error planning recipe: \(error)")
                } else {
                    isPlanned = true
                }
            }
        }
    }
}


struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var showInstructions = false
    @State private var showIngredients = true
    @State private var isSaved = false
    @State private var isPlanned = false
    
    var body: some View {
        VStack {
            // Drag Indicator
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe Title
                    Text(recipe.name)
                        .font(.title)
                        .bold()
                        .padding(.horizontal)
                    
                    // Recipe Thumbnail
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: URL(string: recipe.thumbnail)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                        
                        HStack(spacing: 16) {
                            // Save Button
                            Button(action: { toggleSave() }) {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(isSaved ? .blue : .gray)
                                    .padding(10)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            
                            // Plan Button
                            Button(action: { togglePlan() }) {
                                Image(systemName: isPlanned ? "calendar" : "calendar")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(isPlanned ? .blue : .gray)
                                    .frame(width: 28, height: 28)
                                    .padding(10)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                        .padding(12)
                    }
                    
                    
                    // Recipe Links
                    HStack {
                        if let link = recipe.link {
                            Button(action: {
                                if let url = URL(string: link) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Label("Recipe Link", systemImage: "link")
                                    .font(.subheadline)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        if let yt = recipe.yt {
                            Button(action: {
                                if let url = URL(string: yt) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Label("YouTube", systemImage: "play.rectangle")
                                    .font(.subheadline)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    

                    VStack(alignment: .leading) {
                        Button(action: {
                            showIngredients.toggle()
                        }) {
                            HStack {
                                Text("Ingredients")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: showIngredients ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.blue)
                            }
                            .padding(.top)
                            .padding(.bottom, 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if showIngredients {
                            VStack(spacing: 0) {
                                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { (index, ingredient) in
                                    let (quantity, item) = ingredient
                                    HStack {
                                        Text(quantity)
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 8) // Add padding for better row height
                                            .padding(.leading, 15)
                                        Text(item)
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 8)
                                            .padding(.leading, 5)
                                    }
                                    .background(index % 2 == 0 ? Color(.systemGray6) : Color(.systemBackground)) // Alternating row colors
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recipe Instructions
                    VStack(alignment: .leading) {
                        Button(action: {
                            showInstructions.toggle()
                        }) {
                            HStack {
                                Text("Instructions")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: showInstructions ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.blue)
                            }
                            .padding(.top)
                            .padding(.bottom, 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if showInstructions {
                            Text(recipe.instructions)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top)
        .background(Color(.systemBackground))
        .onAppear(perform: checkSavedAndPlannedStatus)
    }
    
    private func checkSavedAndPlannedStatus() {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            let userDocRef = db.collection("users").document(userID)
            
            userDocRef.getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user document: \(error)")
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    let data = snapshot.data()
                    
                    if let savedRecipes = data?["savedRecipes"] as? [String] {
                        isSaved = savedRecipes.contains(recipe.idMeal)
                    }
                    
                    if let plannedRecipes = data?["planned_unscheduled"] as? [String] {
                        isPlanned = plannedRecipes.contains(recipe.idMeal)
                    }
                }
            }
        }
        
        private func toggleSave() {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            let userDocRef = db.collection("users").document(userID)
            
            if isSaved {
                userDocRef.updateData(["savedRecipes": FieldValue.arrayRemove([recipe.idMeal])]) { error in
                    if let error = error {
                        print("Error removing saved recipe: \(error)")
                    } else {
                        isSaved = false
                    }
                }
            } else {
                userDocRef.updateData(["savedRecipes": FieldValue.arrayUnion([recipe.idMeal])]) { error in
                    if let error = error {
                        print("Error saving recipe: \(error)")
                    } else {
                        isSaved = true
                    }
                }
            }
        }
        
        private func togglePlan() {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            let userDocRef = db.collection("users").document(userID)
            
            if isPlanned {
                userDocRef.updateData(["planned_unscheduled": FieldValue.arrayRemove([recipe.idMeal])]) { error in
                    if let error = error {
                        print("Error removing planned recipe: \(error)")
                    } else {
                        isPlanned = false
                    }
                }
            } else {
                userDocRef.updateData(["planned_unscheduled": FieldValue.arrayUnion([recipe.idMeal])]) { error in
                    if let error = error {
                        print("Error planning recipe: \(error)")
                    } else {
                        isPlanned = true
                    }
                }
            }
        }
    
}
