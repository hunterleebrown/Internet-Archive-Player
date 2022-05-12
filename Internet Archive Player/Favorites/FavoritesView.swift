//
//  SwiftUIView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 1/21/22.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject var viewModel = FavoritesView.ViewModel()
    var body: some View {
        List {
            ForEach(self.viewModel.paths, id: \.self) { file in
                Text(file)
                    .font(.caption2)
            }
            Divider()
            Text("Total files: \(self.viewModel.totalFiles)")
            Text("Total size: \(self.viewModel.totalDownloadSize)")

        }
        .modifier(BackgroundColorModifier(backgroundColor: Color.gray))
        .onAppear() {
            viewModel.updateFiles()
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}

extension FavoritesView {
    class ViewModel: ObservableObject {
        @Published var paths: [String] = []
        @Published var totalFiles: Int = 0
        @Published var totalDownloadSize: Int = 0

        func updateFiles() {
            do {
                let itemDirs = try FileManager.default.contentsOfDirectory(atPath: Downloader.directory().path)
                for dir in itemDirs {
                    guard dir != ".DS_Store" else { continue }
                    var directory: ObjCBool = ObjCBool(true)
                    let directoryPath = Downloader.directory().appendingPathComponent(dir)

                    print("---------> dir path: \(directoryPath)")

                    if FileManager.default.fileExists(atPath: directoryPath.path, isDirectory: &directory) {

                        self.paths = try FileManager.default.contentsOfDirectory(atPath: directoryPath.path)
                        for file in self.paths {
                            guard file != ".DS_Store" else { continue }
                            let filePath = directoryPath.appendingPathComponent(file)
                            let attributes = try FileManager.default.attributesOfItem(atPath: filePath.path)
                            print("\(file) attributes: \(attributes[FileAttributeKey.size]!)")
                            totalFiles = totalFiles + 1
                            if let fileSize = attributes[FileAttributeKey.size] as? Int {
                                totalDownloadSize = totalDownloadSize + fileSize
                            }
                        }
                    }
                }
            } catch {
                print("ERROR IN FILE FETCH -- or no contentsOfDirectoryAtPath  \(error)")
            }
        }


    }
}
