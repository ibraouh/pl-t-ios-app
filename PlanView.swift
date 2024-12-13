//
//  PlanView.swift
//  Plât
//
//  Created by Abe Raouh on 10/18/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PlanView: View {
    @State private var plannedRecipes: [Recipe] = []
    @State private var scheduledRecipes: [(date: Date, recipe: Recipe)] = [] // Holds date-recipe pairs
    @State private var selectedRecipe: Recipe?
    @State private var selectedDate: Date? = nil
    @State private var showDatePicker = false


    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemIndigo).opacity(0.3),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            
            
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Unscheduled")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack() {
                                    ForEach(plannedRecipes, id: \.idMeal) { recipe in
                                        PlanRecipeCardView(
                                            recipe: recipe,
                                            scheduledDate: nil, // Pass nil for unscheduled recipes.
                                            onSetDate: {
                                                selectedRecipe = recipe
                                                showDatePicker.toggle()
                                            }
                                        )
                                        .onTapGesture {
                                            selectedRecipe = recipe
                                        }
                                        .padding(.leading)
                                    }
                                }
                                .padding(.trailing)
                            }
                        }

                        Divider()
                            .padding(.horizontal, 16)

                        // Scheduled Recipes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scheduled for This Week")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(scheduledRecipes.sorted(by: { $0.date > $1.date }), id: \.recipe.idMeal) { item in
                                PlanRecipeCardView(
                                        recipe: item.recipe,
                                        scheduledDate: item.date,
                                        onSetDate: {
                                            selectedRecipe = item.recipe
                                            showDatePicker.toggle()
                                        },
                                        onMoveToUnscheduled: {
                                            moveToUnscheduled(recipe: item.recipe)
                                        }
                                    )
                                .onTapGesture {
                                    selectedRecipe = item.recipe
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom)
                }
                .navigationTitle("Week's Plan")
                .onAppear {
                    fetchPlannedRecipes()
                    fetchScheduledRecipes()
                }
                .sheet(isPresented: $showDatePicker) {
                    DatePicker(
                        "Select a date",
                        selection: Binding(
                            get: { selectedDate ?? Date() },
                            set: { selectedDate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    
                    Button("Assign Date") {
                        if let recipe = selectedRecipe, let date = selectedDate {
                            assignRecipeToDate(recipe: recipe, date: date)
                        }
                        showDatePicker = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .sheet(item: $selectedRecipe) { recipe in RecipeDetailView(recipe: recipe)}
            }
        }
    }

    // Fetch unplanned recipes
    private func fetchPlannedRecipes() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)

        userDocRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching unplanned recipes: \(error)")
                return
            }

            if let snapshot = snapshot, let data = snapshot.data(),
               let recipeIDs = data["planned_unscheduled"] as? [String] {
                fetchRecipes(for: recipeIDs) { fetchedRecipes in
                    self.plannedRecipes = fetchedRecipes
                }
            }
        }
    }

    // Fetch scheduled recipes
    private func fetchScheduledRecipes() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)

        userDocRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching scheduled recipes: \(error)")
                return
            }

            if let snapshot = snapshot, let data = snapshot.data(),
               let plannedData = data["planned_scheduled"] as? [String: String] {
                fetchRecipes(for: Array(plannedData.values)) { fetchedRecipes in
                    self.scheduledRecipes = fetchedRecipes.compactMap { recipe in
                        if let dateStr = plannedData.first(where: { $1 == recipe.idMeal })?.key,
                           let date = ISO8601DateFormatter().date(from: dateStr) {
                            return (date: date, recipe: recipe)
                        }
                        return nil
                    }
                }
            }
        }
    }



    private func assignRecipeToDate(recipe: Recipe, date: Date) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)

        let dateStr = ISO8601DateFormatter().string(from: date) // Format the date as a string.

        userDocRef.updateData([
            "planned_unscheduled": FieldValue.arrayRemove([recipe.idMeal]), // Remove from unscheduled.
            "planned_scheduled.\(dateStr)": recipe.idMeal // Add to scheduled under the date.
        ]) { error in
            if let error = error {
                print("Error assigning recipe to date: \(error)")
            } else {
                print("Recipe successfully assigned to date \(dateStr).")
                // Refresh data after the update.
                fetchPlannedRecipes()
                fetchScheduledRecipes()
            }
        }
    }



    private func moveToUnscheduled(recipe: Recipe) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userID)

        // Find the date the recipe is scheduled under.
        if let scheduledDate = scheduledRecipes.first(where: { $0.recipe.idMeal == recipe.idMeal })?.date {
            let dateStr = ISO8601DateFormatter().string(from: scheduledDate) // Format the date as a string.

            userDocRef.updateData([
                "planned_scheduled.\(dateStr)": FieldValue.delete(), // Remove from scheduled.
                "planned_unscheduled": FieldValue.arrayUnion([recipe.idMeal]) // Add back to unscheduled.
            ]) { error in
                if let error = error {
                    print("Error moving recipe to unscheduled: \(error)")
                } else {
                    print("Recipe successfully moved back to unscheduled.")
                    // Refresh data after the update.
                    fetchPlannedRecipes()
                    fetchScheduledRecipes()
                }
            }
        } else {
            print("Recipe not found in scheduled recipes.")
        }
    }



    // Fetch recipes by their IDs
    private func fetchRecipes(for recipeIDs: [String], completion: @escaping ([Recipe]) -> Void) {
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
                completion(fetchedRecipes)
            }
        }
    }
    
    private func relativeDateString(for date: Date) -> String {
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
        }
}

struct PlanRecipeCardView: View {
    let recipe: Recipe
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isSaved = false
    @State private var isPlanned = false
    let scheduledDate: Date?
    var onSetDate: (() -> Void)?
    var onMoveToUnscheduled: (() -> Void)?
    
    
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
                }

                // Recipe Title and Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 200, alignment: .topLeading)
                    
                    
                    if let category = recipe.category, let area = recipe.area, area != "Unknown" {
                        Text("\(area), \(category)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else if let category = recipe.category {
                        Text("Category: \(category)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else if let area = recipe.area, area != "Unknown" {
                        Text("Cuisine: \(area)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
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
                                Label("Video", systemImage: "play.rectangle")
                                    .font(.subheadline)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    HStack(alignment: .center) { // Ensures vertical alignment
                        if let scheduledDate = scheduledDate {
                            Button(action: { onSetDate?() }) {
                                HStack {
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.white)
                                    Text(relativeDateString(for: scheduledDate))
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(20)
                            }
                        } else {
                            // Set Date Button
                            Button(action: { onSetDate?() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.white)
                                    
                                    Text("Set Date")
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(20)
                            }
                            
                            Spacer().frame(width: 14) // Space between buttons
                            
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
                        }
                        
                        if onMoveToUnscheduled != nil {
                            Spacer().frame(width: 14)
                            Button(action: {
                                onMoveToUnscheduled?()
                            }) {
                                Image(systemName: "arrow.uturn.backward")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 15)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(maxHeight: 30) // Ensures consistent alignment for taller elements
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
    
    private func relativeDateString(for date: Date) -> String {
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
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
                
                // Check if recipe is planned (unscheduled)
                var isPlannedInUnscheduled = false
                if let plannedRecipes = data?["planned_unscheduled"] as? [String] {
                    isPlannedInUnscheduled = plannedRecipes.contains(recipe.idMeal)
                }
                
                // Check if recipe is planned (scheduled)
                var isPlannedInScheduled = false
                if let plannedScheduled = data?["planned_scheduled"] as? [String: String] {
                    isPlannedInScheduled = plannedScheduled.values.contains(recipe.idMeal)
                }
                
                // Set isPlanned based on either unscheduled or scheduled
                isPlanned = isPlannedInUnscheduled || isPlannedInScheduled
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

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        return self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
    }
}
