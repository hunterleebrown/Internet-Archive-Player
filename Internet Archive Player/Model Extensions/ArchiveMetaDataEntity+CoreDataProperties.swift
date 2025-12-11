//
//  ArchiveMetaDataEntity+CoreDataProperties.swift
//  Internet Archive Player
//
//  Manual Core Data properties definition
//

import Foundation
import CoreData

extension ArchiveMetaDataEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArchiveMetaDataEntity> {
        return NSFetchRequest<ArchiveMetaDataEntity>(entityName: "ArchiveMetaDataEntity")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var title: String?
    @NSManaged public var archiveTitle: String?
    @NSManaged public var mediatype: String?
    @NSManaged public var creator: String?
    @NSManaged public var publisher: String?
    @NSManaged public var desc: String?
    @NSManaged public var iconUrlString: String?
    @NSManaged public var dateAdded: Date?

}

extension ArchiveMetaDataEntity : Identifiable {

}
