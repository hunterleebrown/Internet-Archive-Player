//
//  HomeView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct HomeView: View {
    @State var showPlayer = false
    var body: some View {
        VStack(alignment:.leading, spacing: 0) {

            if (showPlayer) {
                Playlist()
            } else {
                Tabs(showPlayer: $showPlayer)
            }
            Player(showPlayer: $showPlayer)
                .frame(height: 100)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
