//
//  ContentView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct Tabs: View {

    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
        }
        .tint(.fairyCream)
        .tabStyle()
        .modifier(BackgroundColorModifier(backgroundColor: .droopy))
    }
}

extension View {
    func tabStyle() -> some View {

        onAppear {

            let offColor = UIColor.lightGray
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = offColor

            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: offColor
            ]

            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = IAColors.fairyRed

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance


        }
    }
}


struct Tabs_Previews: PreviewProvider {
    static var previews: some View {
        Tabs()
    }
}
