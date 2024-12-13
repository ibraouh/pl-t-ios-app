//
//  SearchRecipeView.swift
//  Plât
//
//  Created by Abe Raouh on 10/18/24.
//

import SwiftUI
import UIKit
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SearchRecipeView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var selectedRecipe: Recipe?
    @State private var showNoResults = false
    @State private var selectedRegion: String?
    
    @State private var activeFilter: String? = nil
    @State private var foodTypes = ["Beef", "Breakfast", "Chicken", "Dessert", "Goat", "Lamb", "Miscellaneous", "Pasta", "Pork", "Seafood", "Side", "Starter", "Vegan", "Vegetarian"]


    // Activate a filter
    func activateFilter(_ type: String) {
            if activeFilter == type {
                activeFilter = nil
            } else {
                activeFilter = type
            }
            fetchRecipes(for: searchText)
        }
    
    let continents = [
            "American": ["American", "Canadian", "Mexican", "Jamaican"],
            "European": ["British", "Croatian", "Dutch", "French", "Greek", "Irish", "Italian", "Polish", "Portuguese", "Russian", "Spanish", "Ukrainian"],
            "Asian": ["Chinese", "Filipino", "Indian", "Japanese", "Thai", "Vietnamese"],
            "African": ["Egyptian", "Kenyan", "Moroccan", "Tunisian"],
            "Other": ["Australian", "More"]
        ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.darkGray).opacity(0.3),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.bottom)

                    // Results Content
                    if isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Spacer()
                    } else if showNoResults {
                        VStack {
                            Spacer()
                            Text("Sorry, we don't have that one yet...")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding(.bottom, 16)

                            HStack(spacing: 16) {
                                Button(action: {
                                    sendEmail(recipeName: searchText)
                                }) {
                                    VStack {
                                        Image(systemName: "exclamationmark.bubble")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                        Text("Suggest Recipe")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .frame(width: 120, height: 100)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(10)
                                }
                            }
                            Spacer()
                        }
                    } else if !recipes.isEmpty {
                        ScrollView {
                            LazyVStack {
                                // Apply filter to recipes
                                ForEach(filteredRecipes) { recipe in
                                    RecipeCardView(recipe: recipe)
                                        .onTapGesture {
                                            selectedRecipe = recipe
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    } else if searchText.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                List {
                                    ForEach(continents.keys.sorted(), id: \.self) { continent in
                                        Section(header: Text(continent)) {
                                            ForEach(continents[continent] ?? [], id: \.self) { region in
                                                NavigationLink(
                                                    destination: RegionRecipesView(region: region)
                                                ) {
                                                    Text(region)
                                                        .font(.subheadline)
                                                        .foregroundColor(.primary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .listStyle(InsetGroupedListStyle())
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(height: 550)
                            }
                        }
                    } else {
                        Spacer()
                    }
                }
            }
            .navigationTitle("Search Recipes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .onChange(of: searchText) { newValue in
                handleSearchChange(newValue)
            }
        }
    }
    
    private var filteredRecipes: [Recipe] {
        if let filter = activeFilter {
            return recipes.filter { $0.category == filter }
        }
        return recipes
    }


    var searchBar: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search recipes", text: $searchText, onEditingChanged: { editing in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSearching = editing
                        }
                    })

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.white))
                .cornerRadius(10)

                if isSearching {
                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isSearching = false
                            searchText = ""
                            recipes = []
                            showNoResults = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            
            if isSearching {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        // Active Filter
                        if let active = activeFilter {
                            Button(action: {
                                activateFilter(active)
                            }) {
                                HStack {
                                    Text(active)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Image(systemName: "xmark")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.8))
                                .cornerRadius(20)
                            }
                            .frame(height: 40)
                        }

                        // Inactive Filters
                        ForEach(foodTypes, id: \.self) { type in
                            if activeFilter != type {
                                Button(action: {
                                    activateFilter(type)
                                }) {
                                    Text(type)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(20)
                                }
                                .frame(height: 40)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
        func sendEmail(recipeName: String) {
            print("Hello")
            let recipient = "abe@raouh.com"
            let subject = "Recipe Suggestion"
            let body = "Hi,\n\nI would like to suggest the following recipe: \(recipeName)"
            let email = "mailto:\(recipient)?subject=\(subject)&body=\(body)"
            
            if let emailURL = URL(string: email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                if UIApplication.shared.canOpenURL(emailURL) {
                    UIApplication.shared.open(emailURL, options: [:], completionHandler: nil)
                } else {
                    print("Unable to open email client.")
                }
            }
        }

        func handleSearchChange(_ query: String) {
            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedQuery.isEmpty {
                recipes = []
                showNoResults = false
                activeFilter = nil
            } else {
                fetchRecipes(for: trimmedQuery)
            }
        }

    struct RecipeResponse: Codable {
        let meals: [Recipe]?
    }
    
    // Fetch Recipes from the API
    private func fetchRecipes(for query: String) {
        let formattedQuery = query.replacingOccurrences(of: " ", with: "+")
        let urlString = "https://www.themealdb.com/api/json/v1/1/search.php?s=\(formattedQuery)"
        guard let url = URL(string: urlString) else { return }

        isLoading = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let decodedResponse = try? JSONDecoder().decode(RecipeResponse.self, from: data) {
                    DispatchQueue.main.async {
                        recipes = decodedResponse.meals ?? []
                        isLoading = false
                        showNoResults = recipes.isEmpty
                    }
                }
            } catch {
                print("Error fetching recipes: \(error)")
                DispatchQueue.main.async {
                    recipes = []
                    isLoading = false
                    showNoResults = true
                }
            }
        }
    }
}

// RegionRecipesView for displaying recipes by region
struct RegionRecipesView: View {
    let region: String
    @State private var recipes: [RegionMeal] = []
    @State private var isLoading = true
    @State private var showNoResults = false
    @State private var selectedRecipe: Recipe?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading \(region) recipes...")
                    .padding()
            } else if showNoResults {
                Text("No recipes found for \(region).")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(recipes) { recipe in
                            RegionMealCardView(recipe: recipe)
                                .onTapGesture {
                                    fetchMealDetails(for: recipe.idMeal)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("\(region) Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
        .onAppear(perform: fetchRegionRecipes)
    }

    private func fetchRegionRecipes() {
        guard let encodedRegion = region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.themealdb.com/api/json/v1/1/filter.php?a=\(encodedRegion)") else {
            print("Invalid URL for region: \(region)")
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let decodedResponse = try? JSONDecoder().decode(RegionMealResponse.self, from: data) {
                    DispatchQueue.main.async {
                        recipes = decodedResponse.meals ?? []
                        isLoading = false
                        showNoResults = recipes.isEmpty
                    }
                } else {
                    DispatchQueue.main.async {
                        recipes = []
                        isLoading = false
                        showNoResults = true
                    }
                }
            } catch {
                print("Error fetching region recipes: \(error)")
                DispatchQueue.main.async {
                    recipes = []
                    isLoading = false
                    showNoResults = true
                }
            }
        }
    }
    
    private func fetchMealDetails(for mealID: String) {
        guard let url = URL(string: "https://www.themealdb.com/api/json/v1/1/lookup.php?i=\(mealID)") else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let decodedResponse = try? JSONDecoder().decode(RecipeResponse.self, from: data),
                   let meal = decodedResponse.meals.first {
                    DispatchQueue.main.async {
                        selectedRecipe = meal
                    }
                }
            } catch {
                print("Error fetching meal details: \(error)")
            }
        }
    }

}

struct RegionMeal: Identifiable, Codable {
    let idMeal: String
    let strMeal: String
    let strMealThumb: String

    var id: String { idMeal }
}

struct RegionMealResponse: Codable {
    let meals: [RegionMeal]?
}

struct RegionMealCardView: View {
    let recipe: RegionMeal
    @State private var isSaved = false
    @State private var isPlanned = false
    @State private var isShared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack {
                    // Meal Thumbnail
                    AsyncImage(url: URL(string: recipe.strMealThumb)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 100, height: 100)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Meal Name
                    Text(recipe.strMeal)
                        .font(.headline)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    Spacer()
                    
                    HStack {
                        // Save Button
                        Button(action: {
                            toggleSave()
                        }) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
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
                                .frame(width: 22, height: 22)
                                .foregroundColor(isPlanned ? .green : .gray) 
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 8)
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
