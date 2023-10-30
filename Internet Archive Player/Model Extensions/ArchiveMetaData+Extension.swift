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


    func formatDateString() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // the date format from the API
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX

        guard let aDate = self.date else { return nil }
        if let date = dateFormatter.date(from: aDate) {
            dateFormatter.dateFormat = "MMMM dd, yyyy" // format you want
            return dateFormatter.string(from: date)
        } else {
            return self.date
        }
    }
}
