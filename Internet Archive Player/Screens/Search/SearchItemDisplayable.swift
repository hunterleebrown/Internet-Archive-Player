//
//  SearchItemDisplayable.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/11/24.
//

import Foundation
import iaAPI

/// Protocol that provides the properties needed to display an item in SearchItemView
protocol SearchItemDisplayable {
    /// URL for the item's icon/thumbnail image
    var displayIconUrl: URL? { get }

    /// The title of the archive item
    var archiveTitle: String? { get }
    
    /// The media type as a string (e.g., "audio", "movies", "etree")
    var mediatypeDisplay: ArchiveMediaType? { get }

    /// Array of publisher names
    var publisherDisplay: [String]? { get }

    /// Array of creator names
    var creatorDisplay: [String]? { get }
}

extension ArchiveMetaData: SearchItemDisplayable {
    var displayIconUrl: URL? {
        return self.iconUrl
    }
    
    var publisherDisplay: [String]? {
        self.publisher
    }
    
    var creatorDisplay: [String]? {
        self.creator
    }
        
    var mediatypeDisplay: iaAPI.ArchiveMediaType? {
        self.mediatype
    }
    
}

extension ArchiveMetaDataEntity: SearchItemDisplayable {
    var displayIconUrl: URL? {
        guard let iconUrlString else { return nil }
        return URL(string: iconUrlString)!
    }
    
    var publisherDisplay: [String]? {
        self.publisher?.components(separatedBy: ",")
    }
    
    var creatorDisplay: [String]? {
        self.creator?.components(separatedBy: ",")
    }
    
    var mediatypeDisplay: iaAPI.ArchiveMediaType? {
        guard let mt = self.mediatype else { return nil }
        return iaAPI.ArchiveMediaType(rawValue: mt)
    }

}
