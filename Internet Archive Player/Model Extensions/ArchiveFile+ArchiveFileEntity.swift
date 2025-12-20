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

    public var isVideo: Bool {
        switch self.format {
        case .h264, .h264HD, .mp4HiRes, .mpg512kb, .h264IA, .mpeg4, .mpeg2:
            return true
        default:
            return false
        }
    }

}

extension ArchiveFileEntity: ArchiveFileDisplayable {
    
    // All display properties now come from ArchiveFileDisplayable protocol
    
    public func download(delegate: FileViewDownloadDelegate) {
        let downloader = Downloader(self, delegate: delegate)
        do {
            try downloader.downloadFile()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension ArchiveFileEntity {
  static var archiveFileFetchRequest: NSFetchRequest<ArchiveFileEntity> {
    let request: NSFetchRequest<ArchiveFileEntity> = ArchiveFileEntity.fetchRequest()
//    request.predicate = NSPredicate(format: "dueDate < %@", Date.nextWeek() as CVarArg)
    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

    return request
  }
}

