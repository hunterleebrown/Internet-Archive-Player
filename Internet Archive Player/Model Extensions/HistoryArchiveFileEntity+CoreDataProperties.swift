//
//  HistoryArchiveFileEntity+CoreDataProperties.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/16/24.
//

import Foundation
import CoreData

extension HistoryArchiveFileEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HistoryArchiveFileEntity> {
        return NSFetchRequest<HistoryArchiveFileEntity>(entityName: "HistoryArchiveFileEntity")
    }

    // Archive file properties
    @NSManaged public var identifier: String?
    @NSManaged public var name: String?
    @NSManaged public var title: String?
    @NSManaged public var artist: String?
    @NSManaged public var creator: String?
    @NSManaged public var archiveTitle: String?
    @NSManaged public var track: String?
    @NSManaged public var size: String?
    @NSManaged public var format: String?
    @NSManaged public var length: String?
    @NSManaged public var url: URL?
    
    // History-specific properties
    @NSManaged public var playedAt: Date?
    @NSManaged public var playCount: Int64

}

extension HistoryArchiveFileEntity: Identifiable {

}
