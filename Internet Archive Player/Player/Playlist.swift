//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/22/22.
//

import SwiftUI

struct Playlist: View {
    @State private var seek = 1.0

    var body: some View {
        VStack(alignment:.leading, spacing: 0){
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .foregroundColor(.fairyCream)
            Spacer()
            Slider(value: $seek,
                   in: 0...100)
                .accentColor(.fairyCream)
            HStack{
                Text("0:00:00")
                    .font(.system(size:9.0))
                    .foregroundColor(.fairyCream)
                Spacer()
                Text("0.00.00")
                    .font(.system(size:9.0))
                    .foregroundColor(.fairyCream)

            }
            .frame(height:30)
        }
        .padding(10)
        .modifier(BackgroundColorModifier(backgroundColor: .droopy))
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        Playlist()
    }
}
