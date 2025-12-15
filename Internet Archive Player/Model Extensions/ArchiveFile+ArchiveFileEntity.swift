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
        case .h264, .h264HD, .mp4HiRes, .mpg512kb, .h264IA:
            return true
        default:
            return false
        }
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

    public var displayArtist: String {
        return artist ?? creator ?? ""
    }

    public func download(delegate: FileViewDownloadDelegate) {
        let downloader = Downloader(self, delegate: delegate)
        do {
            try downloader.downloadFile()
        } catch let error {
            print(error.localizedDescription)
        }
    }

    public var onlineUrl: URL?  {
        guard let identifier = identifier, let fileName = name else { return nil }
        return URL(string: "https://archive.org/download")?.appendingPathComponent(identifier).appendingPathComponent(fileName)
    }

    public func isLocalFile() -> Bool {
        guard let url = self.url, url.absoluteString.contains("file:///") else { return false }
        return true
    }

    public func doesLocalFileExist() -> Bool {
        guard isLocalFile(), let url = self.workingUrl else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    public var workingUrl: URL? {
        guard isLocalFile(), let identifier = identifier, let lastPathComponent = url?.lastPathComponent else  { return onlineUrl }
        return Downloader.directory().appendingPathComponent(identifier).appendingPathComponent(lastPathComponent)
    }

    public var isAudio: Bool {
        return format == "VBR MP3"
    }

    public var isVideo: Bool {
        return !isAudio
    }

    /// Generates a shareable URL for this archive file using the app's custom URL scheme
    public var shareURL: URL? {
        var components = URLComponents()
        components.scheme = "iaplayer"
        components.host = "add"
        
        var queryItems: [URLQueryItem] = []
        
        // Add all available fields as query parameters
        if let identifier = identifier {
            queryItems.append(URLQueryItem(name: "identifier", value: identifier))
        }
        if let name = name {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        if let title = title {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }
        if let artist = artist {
            queryItems.append(URLQueryItem(name: "artist", value: artist))
        }
        if let creator = creator {
            queryItems.append(URLQueryItem(name: "creator", value: creator))
        }
        if let archiveTitle = archiveTitle {
            queryItems.append(URLQueryItem(name: "archiveTitle", value: archiveTitle))
        }
        if let track = track {
            queryItems.append(URLQueryItem(name: "track", value: track))
        }
        if let size = size {
            queryItems.append(URLQueryItem(name: "size", value: size))
        }
        if let format = format {
            queryItems.append(URLQueryItem(name: "format", value: format))
        }
        if let length = length {
            queryItems.append(URLQueryItem(name: "length", value: length))
        }
        
        // Add source
        queryItems.append(URLQueryItem(name: "source", value: "shared"))
        
        components.queryItems = queryItems
        
        return components.url
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

