//
//  Downloader.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 5/10/22.
//

import Foundation
import Combine

enum DownloaderError: Error  {
    case fileAlreadyExits
    case errorDownloading
    case fileNotDownloaded
    case couldNotCreateDirectory
    case fileDoesNotExist
}

extension DownloaderError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fileAlreadyExits:
            return "File already is downloaded"
        case .errorDownloading:
            return "There was an error in downloading."
        case .fileNotDownloaded:
            return "Could not change file url. It's not downloaded yet."
        case .couldNotCreateDirectory:
            return "Could not create directory."
        case .fileDoesNotExist:
            return "File at local path does not exist."
        }
    }
}

class Downloader: NSObject {

    static var downloadedSubject = PassthroughSubject<(ArchiveFileEntity), Never>()

    private lazy var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumIntegerDigits = 1
        formatter.maximumIntegerDigits = 3
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    public static var mainDirectory: String = "iaPlayer"

    public static func directory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(Downloader.mainDirectory)
    }

    public static func removeFile(at path: URL) throws {
        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        } else {
            throw DownloaderError.fileDoesNotExist
        }
    }

    private let file: ArchiveFileEntity
    private var downloadTask: URLSessionDownloadTask?
    private var delegate: FileViewDownloadDelegate?

    init(_ file: ArchiveFileEntity, delegate: FileViewDownloadDelegate) {
        self.file = file
        self.delegate = delegate
    }


    private lazy var urlSession = URLSession(configuration: .default,
                                             delegate: self,
                                             delegateQueue: nil)


    public func downloadFile() throws {
        if isFileDownloaded() {
            print(downloadUrl)
            throw DownloaderError.fileAlreadyExits
        }
        if let url = file.url {
            startDownload(url: url)
        }
    }

    private func startDownload(url: URL) {
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
        self.downloadTask = downloadTask
        if let directory = downloadDirectory {
            print("Downloading and moving to: \(directory.path)")
        }
    }

    private func isFileDownloaded() -> Bool {
        guard let url = downloadUrl, FileManager.default.fileExists(atPath: url.path) else { return false }
        return true
    }

    private var downloadDirectory: URL? {
        guard self.file.url?.lastPathComponent != nil, let identifier = file.identifier else { return nil }
        return Downloader.directory().appendingPathComponent(identifier)
    }

    private var downloadUrl: URL? {
        guard let fileComponent = self.file.url?.lastPathComponent else { return nil }
        return downloadDirectory?.appendingPathComponent(fileComponent)
    }

    private func updateFileUrl() throws {
        if isFileDownloaded() {
            file.url = downloadUrl
            PersistenceController.shared.save()
            DispatchQueue.main.async {
                Downloader.downloadedSubject.send(self.file)
            }
        } else {
            throw DownloaderError.fileAlreadyExits
        }
    }

}

extension Downloader: URLSessionTaskDelegate {

}


extension Downloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // check for and handle errors:
           // * downloadTask.response should be an HTTPURLResponse with statusCode in 200..<299

           do {
//               let documentsURL = try
//                   FileManager.default.url(for: .documentDirectory,
//                                           in: .userDomainMask,
//                                           appropriateFor: nil,
//                                           create: false)


               if let destinationUrl = downloadUrl {
                   guard let downloadDirectory = downloadDirectory else { throw DownloaderError.couldNotCreateDirectory }
                   if !FileManager.default.fileExists(atPath: downloadDirectory.path) {
                       try FileManager.default.createDirectory(
                                  at: downloadDirectory,
                                  withIntermediateDirectories: true,
                                  attributes: nil
                              )
                   }
                   try FileManager.default.moveItem(at: location, to: destinationUrl)
                   try updateFileUrl()
               }

           } catch let error {
               print(error.localizedDescription)
           }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        if downloadTask == self.downloadTask {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            print("Downloading: \(self.percentFormatter.string(from: NSNumber(value: calculatedProgress)))")
            DispatchQueue.main.async {
                self.delegate?.downloadProgress = Double(calculatedProgress)
            }
        }
    }
}
