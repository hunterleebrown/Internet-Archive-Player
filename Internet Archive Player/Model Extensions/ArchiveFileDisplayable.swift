//
//  ArchiveFileDisplayable.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/16/24.
//

import Foundation
import iaAPI

/// A protocol for entities that represent Internet Archive files with common display properties
protocol ArchiveFileDisplayable: Identifiable {
    var identifier: String? { get }
    var name: String? { get }
    var title: String? { get }
    var artist: String? { get }
    var creator: String? { get }
    var archiveTitle: String? { get }
    var track: String? { get }
    var size: String? { get }
    var format: String? { get }
    var length: String? { get }
    var url: URL? { get }
}

extension ArchiveFileDisplayable {
    
    /// Stable identifier for use in ForEach and collections
    /// Combines identifier and name, falling back to online URL string or UUID
    var stableID: String {
        if let identifier = identifier, let name = name {
            return "\(identifier)/\(name)"
        }
        return onlineUrl?.absoluteString ?? UUID().uuidString
    }
    
    /// Returns a human-readable formatted length string
    var displayLength: String? {
        if let l = length {
            return IAStringUtils.timeFormatter(timeString: l)
        }
        return nil
    }
    
    /// Returns a human-readable formatted size string
    var calculatedSize: String? {
        if let s = size {
            if let rawSize = Int(s) {
                return IAStringUtils.sizeString(size: rawSize)
            }
        }
        return nil
    }
    
    /// Returns the icon/thumbnail URL for this archive item
    var iconUrl: URL? {
        if let ident = identifier {
            let itemImageUrl = "https://archive.org/services/img/\(ident)"
            return URL(string: itemImageUrl)
        }
        return nil
    }
    
    /// Returns the best available title for display
    var displayTitle: String {
        return title ?? name ?? ""
    }
    
    /// Returns the best available artist/creator for display
    var displayArtist: String {
        return artist ?? creator ?? ""
    }
    
    /// Returns the online URL for accessing this file
    var onlineUrl: URL? {
        guard let identifier = identifier, let fileName = name else { return nil }
        return URL(string: "https://archive.org/download")?.appendingPathComponent(identifier).appendingPathComponent(fileName)
    }
    
    /// Checks if this file is stored locally (starts with file:///)
    func isLocalFile() -> Bool {
        guard let url = self.url, url.absoluteString.contains("file:///") else { return false }
        return true
    }
    
    /// Checks if the local file actually exists on disk
    func doesLocalFileExist() -> Bool {
        guard isLocalFile(), let url = self.workingUrl else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Returns the working URL - either local file path or online URL
    var workingUrl: URL? {
        guard isLocalFile(), let identifier = identifier, let lastPathComponent = url?.lastPathComponent else { return onlineUrl }
        return Downloader.directory().appendingPathComponent(identifier).appendingPathComponent(lastPathComponent)
    }
    
    /// Checks if this file is an audio file
    var isAudio: Bool {
        return format == "VBR MP3"
    }
    
    /// Checks if this file is a video file
    var isVideo: Bool {
        return !isAudio
    }
    
    /// Generates a shareable URL for this archive file using the app's custom URL scheme
    var shareURL: URL? {
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
