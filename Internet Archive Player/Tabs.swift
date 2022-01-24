//
//  ContentView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct Tabs: View {
    @Binding var showPlayer : Bool

    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
        }
        .accentColor(.fairyCream)
        .tabStyle()
        .modifier(BackgroundColorModifier(backgroundColor: .droopy))
    }
}

extension View {
    func tabStyle() -> some View {

        onAppear {
            UITabBar.appearance().backgroundColor = IAColors.droppy

            let offColor = UIColor.lightGray
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = offColor

            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: offColor
            ]

            let appearance = UITabBarAppearance()
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance

        }
    }
}


struct Tabs_Previews: PreviewProvider {
    static var previews: some View {
        Tabs(showPlayer: .constant(false))
    }
}
