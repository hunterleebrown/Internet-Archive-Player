//
//  BookReaderPreviewHelper.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//
//  Helper for testing and debugging the Book Reader

import Foundation
import SwiftUI
import iaAPI

#if DEBUG

// MARK: - URL Testing

/// Test helper to validate URL generation
struct BookReaderURLTester {
    let archive: Archive
    let zipFileName: String
    
    init(archive: Archive, zipFileName: String) {
        self.archive = archive
        self.zipFileName = zipFileName
    }
    
    func testURLGeneration() {
        print("Testing Book Reader URL Generation")
        print("===================================")
        
        guard let host = archive.d1 else {
            print("❌ No host (d1) found")
            return
        }
        print("✅ Host: \(host)")
        
        guard let dir = archive.dir else {
            print("❌ No directory found")
            return
        }
        print("✅ Directory: \(dir)")
        
        guard let identifier = archive.metadata?.identifier else {
            print("❌ No identifier found")
            return
        }
        print("✅ Identifier: \(identifier)")
        
        print("✅ Zip file: \(zipFileName)")
        
        var baseName = zipFileName
        if baseName.hasSuffix(".zip") {
            baseName = String(baseName.dropLast(4))
        }
        print("✅ Base name: \(baseName)")
        
        // Generate sample URLs
        for page in [1, 2, 10, 100] {
            let paddedPage = String(format: "%04d", page)
            
            var components = URLComponents()
            components.scheme = "https"
            components.host = host
            components.path = "/BookReader/BookReaderImages.php"
            
            let zipPath = "\(dir)/\(zipFileName)"
            let filePath = "\(baseName)/\(baseName)_\(paddedPage).jp2"
            
            components.queryItems = [
                URLQueryItem(name: "zip", value: zipPath),
                URLQueryItem(name: "file", value: filePath),
                URLQueryItem(name: "id", value: identifier),
                URLQueryItem(name: "rotate", value: "0")
            ]
            
            if let url = components.url {
                print("\nPage \(page):")
                print(url.absoluteString)
            } else {
                print("❌ Failed to generate URL for page \(page)")
            }
        }
        
        print("\n===================================")
    }
}

// MARK: - Usage Example

/*
 To test URL generation in your app:
 
 ```swift
 if let archive = viewModel.archive,
    let zipFile = viewModel.getBookReaderZipFile() {
     let tester = BookReaderURLTester(archive: archive, zipFileName: zipFile)
     tester.testURLGeneration()
 }
 ```
 
 To test with real Archive.org data:
 
 1. Find a book on archive.org (e.g., "goodytwoshoes00newyiala")
 2. Load the archive in DetailViewModel
 3. Check that textFiles contains a .singlePageProcessedJP2Zip file
 4. Navigate to BookReaderView
 
 Example books to test with:
 - goodytwoshoes00newyiala (The history of little Goody Two-Shoes)
 - adventuresofoli00dick (Oliver Twist)
 - alicesadventures19033gut (Alice's Adventures in Wonderland)
 - prideandprejudic01303gut (Pride and Prejudice)
 */

#endif

