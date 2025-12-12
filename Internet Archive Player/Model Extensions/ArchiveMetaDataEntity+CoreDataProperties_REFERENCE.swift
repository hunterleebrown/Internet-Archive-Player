//
//  ArchiveMetaDataEntity+CoreDataProperties.swift
//  Internet Archive Player
//
//  This is a reference file showing what properties the Core Data entity should have.
//  You don't need to create this file if you use "Class Definition" codegen in Xcode.
//  This is just for reference when creating the entity in your .xcdatamodeld file.
//

import Foundation
import CoreData

/*
 TO CREATE IN XCODE'S DATA MODEL EDITOR:
 
 1. Open InternetArchivePlayer.xcdatamodeld
 2. Add New Entity named: ArchiveMetaDataEntity
 3. Add these attributes:
 
    - identifier: String (NOT optional, indexed)
    - title: String? (optional)
    - archiveTitle: String? (optional)
    - mediatype: String? (optional)
    - creator: String? (optional)
    - publisher: String? (optional)
    - desc: String? (optional)
    - iconUrlString: String? (optional)
    - dateAdded: Date? (optional)
 
 4. In Data Model Inspector:
    - Module: Current Product Module (or blank)
    - Codegen: Class Definition (recommended) or Manual/None
 
 5. Build the project
 
 The generated class will look like this:

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
    // identifier property serves as the unique ID
}
*/
