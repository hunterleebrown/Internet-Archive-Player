//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct FavoritesView: View {
    var body: some View {
        VStack {
            Text("This is Favorites")
        }
        .modifier(IATabViewModifier(backgroundColor: Color.gray))
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
