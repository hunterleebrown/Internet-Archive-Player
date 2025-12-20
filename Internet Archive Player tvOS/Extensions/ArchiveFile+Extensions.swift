//
//  ArchiveFile+Extensions.swift
//  Internet Archive Player tvOS
//
//  Created by Hunter Lee Brown on 10/28/23.
//

import Foundation
import iaAPI

extension ArchiveFile {

    public var isVideo: Bool {
        switch self.format {
        case .h264, .h264HD, .mp4HiRes, .mpg512kb, .h264IA, .mpeg4:
            return true
        default:
            return false
        }
    }
}

