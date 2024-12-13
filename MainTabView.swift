//
//  MainTabView.swift
//  Plât
//
//  Created by Abe Raouh on 10/18/24.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            RecipeFeedView()
                .tabItem {
                    Label("Recipes", systemImage: "tray.full")
                }
            
            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
            
            SearchRecipeView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
