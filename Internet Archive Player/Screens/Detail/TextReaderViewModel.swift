//
//  TextReaderViewModel.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//

import Foundation
import Combine
import iaAPI

@MainActor
final class TextReaderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var displayText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var fontSize: CGFloat = 16
    
    // MARK: - Private Properties
    private let archiveFile: ArchiveFile
    private var fileHandle: FileHandle?
    private var downloadTask: URLSessionDownloadTask?
    private var localFileURL: URL?
    
    // Chunk reading properties
    private let chunkSize: Int = 50_000 // 50KB chunks (approximately 25,000 characters of text)
    private var currentOffset: UInt64 = 0
    private var totalFileSize: UInt64 = 0
    private var hasReachedEnd: Bool = false
    
    // Font size constraints
    private let minFontSize: CGFloat = 12
    private let maxFontSize: CGFloat = 32
    private let defaultFontSize: CGFloat = 16
    
    // MARK: - Computed Properties
    var hasMoreContent: Bool {
        !hasReachedEnd && totalFileSize > 0
    }
    
    var bytesRead: UInt64 {
        currentOffset
    }
    
    var percentageRead: Int {
        guard totalFileSize > 0 else { return 0 }
        return Int((Double(currentOffset) / Double(totalFileSize)) * 100)
    }
    
    var bytesReadFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(currentOffset), countStyle: .file)
    }
    
    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalFileSize), countStyle: .file)
    }
    
    // MARK: - Initialization
    init(archiveFile: ArchiveFile) {
        self.archiveFile = archiveFile
        
        // Load saved font size preference
        if let savedFontSize = UserDefaults.standard.object(forKey: "textReaderFontSize") as? CGFloat {
            self.fontSize = savedFontSize
        }
    }
    
    deinit {
        // Capture values outside of actor isolation
        let handle = fileHandle
        let task = downloadTask
        let fileURL = localFileURL
        
        // Perform cleanup on a background thread
        Task.detached {
            // Close file handle
            if #available(iOS 13.0, *) {
                try? handle?.close()
            } else {
                handle?.closeFile()
            }
            
            // Cancel any ongoing download
            task?.cancel()
            
            // Optionally clean up the downloaded file
            if let fileURL = fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - Public Methods
    
    func loadInitialContent() {
        Task {
            await loadContent(isInitial: true)
        }
    }
    
    func loadMoreContent() {
        guard !isLoading && hasMoreContent else { return }
        
        Task {
            await loadContent(isInitial: false)
        }
    }
    
    func increaseFontSize() {
        if fontSize < maxFontSize {
            fontSize += 2
            saveFontSize()
        }
    }
    
    func decreaseFontSize() {
        if fontSize > minFontSize {
            fontSize -= 2
            saveFontSize()
        }
    }
    
    func resetFontSize() {
        fontSize = defaultFontSize
        saveFontSize()
    }
    
    // MARK: - Private Methods
    
    private func saveFontSize() {
        UserDefaults.standard.set(fontSize, forKey: "textReaderFontSize")
    }
    
    private func loadContent(isInitial: Bool) async {
        guard let url = archiveFile.url else {
            errorMessage = "No URL available for this file"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Download the file if we haven't already
            if localFileURL == nil {
                localFileURL = try await downloadFile(from: url)
            }
            
            guard let localURL = localFileURL else {
                throw TextReaderError.fileNotAvailable
            }
            
            // Open file handle if needed
            if fileHandle == nil {
                fileHandle = try FileHandle(forReadingFrom: localURL)
                
                // Get total file size
                if let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path),
                   let fileSize = attributes[.size] as? UInt64 {
                    totalFileSize = fileSize
                }
            }
            
            guard let handle = fileHandle else {
                throw TextReaderError.fileHandleError
            }
            
            // Seek to current offset
            if #available(iOS 13.4, *) {
                try handle.seek(toOffset: currentOffset)
            } else {
                handle.seek(toFileOffset: currentOffset)
            }
            
            // Read chunk
            let data: Data
            if #available(iOS 13.4, *) {
                data = try handle.read(upToCount: chunkSize) ?? Data()
            } else {
                data = handle.readData(ofLength: chunkSize)
            }
            
            if data.isEmpty {
                hasReachedEnd = true
            } else {
                // Convert to string and append
                if let textChunk = String(data: data, encoding: .utf8) {
                    if isInitial {
                        displayText = textChunk
                    } else {
                        displayText += textChunk
                    }
                    currentOffset += UInt64(data.count)
                } else {
                    // Try other encodings if UTF-8 fails
                    if let textChunk = String(data: data, encoding: .ascii) {
                        if isInitial {
                            displayText = textChunk
                        } else {
                            displayText += textChunk
                        }
                        currentOffset += UInt64(data.count)
                    } else {
                        throw TextReaderError.encodingError
                    }
                }
                
                // Check if we've reached the end
                if currentOffset >= totalFileSize {
                    hasReachedEnd = true
                }
            }
            
        } catch {
            errorMessage = "Failed to load text: \(error.localizedDescription)"
            print("Error loading text content: \(error)")
        }
        
        isLoading = false
    }
    
    private func downloadFile(from url: URL) async throws -> URL {
        let (localURL, response) = try await URLSession.shared.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TextReaderError.downloadFailed
        }
        
        // Move to a permanent location
        let documentsPath = FileManager.default.temporaryDirectory
        let destinationURL = documentsPath.appendingPathComponent(archiveFile.name ?? "text_file.txt")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)
        
        try FileManager.default.moveItem(at: localURL, to: destinationURL)
        
        return destinationURL
    }
}

// MARK: - Error Types
enum TextReaderError: LocalizedError {
    case fileNotAvailable
    case fileHandleError
    case encodingError
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotAvailable:
            return "The text file is not available"
        case .fileHandleError:
            return "Could not open the text file"
        case .encodingError:
            return "The text encoding is not supported"
        case .downloadFailed:
            return "Failed to download the text file"
        }
    }
}
