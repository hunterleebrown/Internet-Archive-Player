//
//  ArchiveMetaData+Extension.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 7/3/23.
//

import Foundation
import iaAPI

extension ArchiveMetaData {
    var descriptionHtml: NSAttributedString? {
        return description.joined(separator: ",").html2AttributedString
    }
}
