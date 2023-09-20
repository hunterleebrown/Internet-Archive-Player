//
//  View+Extensions.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/18/23.
//

import Foundation
import SwiftUI

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position)
        return self.offset(x: 0, y: offset * 10)
    }
}
