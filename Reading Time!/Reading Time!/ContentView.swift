//
//  ContentView.swift
//  Reading Time!
//
//  Created by Hosin Sharifi on 26/12/24.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("lastAddedBook") private var lastAddedBook: Date?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationView {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }
            .tag(1)
            
            NavigationView {
                AccountView()
            }
            .tabItem {
                Label("Account", systemImage: "person.fill")
            }
            .tag(2)
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .onReceive(NotificationCenter.default.publisher(for: .bookAdded)) { _ in
            selectedTab = 1 // Switch to Library tab
            lastAddedBook = Date()
        }
    }
}

#Preview {
    ContentView()
}
