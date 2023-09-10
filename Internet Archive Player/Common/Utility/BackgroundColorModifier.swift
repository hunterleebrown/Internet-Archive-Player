//
//  IATabView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct BackgroundColorModifier: ViewModifier {
    var backgroundColor: Color?
    func body(content: Content) -> some View{
        ZStack{
            backgroundColor?.ignoresSafeArea(.all, edges: .all)
            content
        }
//        .tint(.black)
    }
}

