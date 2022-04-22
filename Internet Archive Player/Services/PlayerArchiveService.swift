//
//  PlayerArchiveService.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 4/22/22.
//

import Foundation
import iaAPI


class PlayerArchiveService: ArchiveService {
    override init(_ serviceType: ArchiveServiceType = .live) {
        super.init(.mock)
    }
}
