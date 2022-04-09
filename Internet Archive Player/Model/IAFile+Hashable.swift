//
//  IAFile+Hashable.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/12/22.
//

import Foundation
import iaAPI

extension ArchiveFile: Hashable {
    public static func == (lhs: ArchiveFile, rhs: ArchiveFile) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(track)
        hasher.combine(name)
        hasher.combine(format)
    }
}
