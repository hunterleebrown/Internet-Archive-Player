//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        VStack {
            Text("This is Search")
        }.modifier(BackgroundColorModifier(backgroundColor: Color.gray))

    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
