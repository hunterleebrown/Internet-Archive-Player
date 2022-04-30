//
//  ArchiveFile+ArchiveFileEntity.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 4/29/22.
//

import Foundation
import CoreData
import iaAPI

extension ArchiveFile {

    func archiveFileEntity() -> ArchiveFileEntity {
        let archiveFileEntity = ArchiveFileEntity(context: PersistenceController.shared.container.viewContext)
        archiveFileEntity.id = self.id
        archiveFileEntity.identifier = self.identifier
        archiveFileEntity.artist = self.artist
        archiveFileEntity.creator = self.creator?.joined(separator: ",")
        archiveFileEntity.archiveTitle = self.archiveTitle
        archiveFileEntity.name = self.name
        archiveFileEntity.title = self.title
        archiveFileEntity.track = self.track
        archiveFileEntity.size = self.size
        archiveFileEntity.format = self.format?.rawValue
        archiveFileEntity.length = self.length
        archiveFileEntity.url = self.url
        return archiveFileEntity
    }

}

extension ArchiveFileEntity {
    public var displayLength: String? {

        if let l = length {
            return IAStringUtils.timeFormatter(timeString: l)
        }
        return nil
    }

    public var calculatedSize: String? {

        if let s = size {
            if let rawSize = Int(s) {
                return IAStringUtils.sizeString(size: rawSize)
            }
        }
        return nil
    }

    public var iconUrl: URL? {
        if let ident = identifier {
            let itemImageUrl = "https://archive.org/services/img/\(ident)"
            return URL(string: itemImageUrl)
        }

        return nil
    }

    public var displayTitle: String {
        return title ?? name ?? ""
    }
}

extension ArchiveFileEntity {
  static var playlistFetchRequest: NSFetchRequest<ArchiveFileEntity> {
    let request: NSFetchRequest<ArchiveFileEntity> = ArchiveFileEntity.fetchRequest()
//    request.predicate = NSPredicate(format: "dueDate < %@", Date.nextWeek() as CVarArg)
    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

    return request
  }
}
