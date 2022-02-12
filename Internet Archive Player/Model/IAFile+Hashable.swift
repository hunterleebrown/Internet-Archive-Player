//
//  IAFile+Hashable.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/12/22.
//

import Foundation
import iaAPI

extension IAFile: Hashable {
    public static func == (lhs: IAFile, rhs: IAFile) -> Bool {
        return lhs.name == rhs.name &&
        lhs.title == rhs.title &&
        lhs.format == rhs.format &&
        lhs.track == rhs.track
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(track)
        hasher.combine(name)
        hasher.combine(format)
    }
}
