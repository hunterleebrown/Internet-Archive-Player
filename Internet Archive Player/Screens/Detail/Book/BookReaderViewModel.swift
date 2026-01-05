//
//  BookReaderViewModel.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//

import Foundation
import SwiftUI
import Combine
import iaAPI

@MainActor
final class BookReaderViewModel: ObservableObject {
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 500
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private(set) var archive: Archive?
    private(set) var zipFile: String?
    private(set) var baseFileName: String?
    private(set) var directoryName: String?
    
    init(archive: Archive, zipFileName: String) {
        print("⚙️ [BookReaderVM] init() called")
        print("⚙️ [BookReaderVM] Archive identifier: \(archive.metadata?.identifier ?? "nil")")
        print("⚙️ [BookReaderVM] Zip file name: \(zipFileName)")
        
        self.archive = archive
        self.zipFile = zipFileName
        
        // Extract directory name (without .zip extension, but keep _jp2)
        var dirName = zipFileName
        if dirName.hasSuffix(".zip") {
            dirName = String(dirName.dropLast(4))
        }
        self.directoryName = dirName
        
        // Extract base file name (without .zip and _jp2 extensions)
        var baseName = dirName
        if baseName.hasSuffix("_jp2") {
            baseName = String(baseName.dropLast(4))
        }
        self.baseFileName = baseName
        
        print("⚙️ [BookReaderVM] Directory name (with _jp2): \(dirName)")
        print("⚙️ [BookReaderVM] Base file name (without _jp2): \(baseName)")
        print("⚙️ [BookReaderVM] Total pages set to: \(self.totalPages)")
    }
    
    /// Generate URL for a specific page
    func urlForPage(_ pageNumber: Int) -> URL? {
        guard let archive = archive,
              let host = archive.d1,
              let dir = archive.dir,
              let zipFile = zipFile,
              let directoryName = directoryName,
              let baseFileName = baseFileName,
              let identifier = archive.metadata?.identifier else {
            return nil
        }
        
        let paddedPage = String(format: "%04d", pageNumber)
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/BookReader/BookReaderImages.php"
        
        // Build zip path: dir/zipFileName
        let zipPath = "\(dir)/\(zipFile)"
        
        // Build file path: directoryName/baseFileName_XXXX.jp2
        // Directory keeps _jp2, but filename uses base without _jp2
        let filePath = "\(directoryName)/\(baseFileName)_\(paddedPage).jp2"
        
        components.queryItems = [
            URLQueryItem(name: "zip", value: zipPath),
            URLQueryItem(name: "file", value: filePath),
            URLQueryItem(name: "id", value: identifier),
            URLQueryItem(name: "rotate", value: "0")
        ]
        
        return components.url
    }
    
    /// Navigate to next page
    func nextPage() {
        guard currentPage < totalPages else { return }
        currentPage += 1
    }
    
    /// Navigate to previous page
    func previousPage() {
        guard currentPage > 1 else { return }
        currentPage -= 1
    }
    
    /// Jump to a specific page
    func goToPage(_ page: Int) {
        guard page > 0 && page <= totalPages else { return }
        currentPage = page
    }
    
    /// Check if we can go to next page
    var canGoNext: Bool {
        currentPage < totalPages
    }
    
    /// Check if we can go to previous page
    var canGoPrevious: Bool {
        currentPage > 1
    }
}
