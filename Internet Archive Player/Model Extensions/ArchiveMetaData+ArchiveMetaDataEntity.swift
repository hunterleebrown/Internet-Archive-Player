//
//  ArchiveMetaData+ArchiveMetaDataEntity.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/11/24.
//

import Foundation
import CoreData
import iaAPI

extension ArchiveMetaData {
    
    func archiveMetaDataEntity() -> ArchiveMetaDataEntity? {
        // Ensure we have a required identifier
        guard let identifier = self.identifier else {
            print("Cannot create ArchiveMetaDataEntity without identifier")
            return nil
        }
        
        let entity = ArchiveMetaDataEntity(context: PersistenceController.shared.container.viewContext)
        entity.identifier = identifier
        entity.title = self.archiveTitle
        entity.archiveTitle = self.archiveTitle
        entity.mediatype = self.mediatype.rawValue
        entity.creator = self.creator?.joined(separator: ", ")
        entity.publisher = self.publisher?.joined(separator: ", ")
        entity.desc = self.description.joined(separator: "\n")
        entity.iconUrlString = self.iconUrl.absoluteString
        entity.dateAdded = Date()
        return entity
    }
}

extension ArchiveMetaDataEntity {
    
    public var iconUrl: URL? {
        if let urlString = iconUrlString {
            return URL(string: urlString)
        }
        return nil
    }
    
    public var displayTitle: String {
        return archiveTitle ?? title ?? "Unknown"
    }
    
    public var displayCreator: String? {
        return creator
    }
    
    public var displayPublisher: String? {
        return publisher
    }
    
    public var creatorArray: [String]? {
        guard let creator = creator else { return nil }
        return creator.components(separatedBy: ", ")
    }
    
    public var publisherArray: [String]? {
        guard let publisher = publisher else { return nil }
        return publisher.components(separatedBy: ", ")
    }
}

extension ArchiveMetaDataEntity {
    static var archiveMetaDataFetchRequest: NSFetchRequest<ArchiveMetaDataEntity> {
        let request: NSFetchRequest<ArchiveMetaDataEntity> = ArchiveMetaDataEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        return request
    }
}
