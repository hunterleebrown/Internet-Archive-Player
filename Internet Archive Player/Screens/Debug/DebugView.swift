//
//  DebugView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/20/23.
//

import Foundation
import SwiftUI

struct DebugView: View {

    @ObservedObject var viewModel: ViewModel = ViewModel()

    var body: some View {
        VStack{
            HStack{
                Text("Downloaded files: ")
                    .foregroundColor(.fairyRed)
                Text("\(viewModel.report?.files.count ?? 0)")
                Spacer()
                Text("\(viewModel.report?.totalSize() ?? 0)")
            }
            List{
                ForEach(viewModel.report?.files ?? [], id: \.self) { downloadedFile in
                    VStack(alignment: .leading) {
                        Text(downloadedFile.directoryPath)
                            .font(.caption)
                            .bold()
                            .frame(alignment: .leading)
                        HStack(alignment: .top, spacing: 0){
                            Text(downloadedFile.name)
                                .font(.caption)
                            Spacer()
                            Text("\(downloadedFile.size)")
                                .font(.caption)
                        }
                    }
                    .frame(minHeight: 20)
                    .listRowInsets(EdgeInsets())
                    .padding(EdgeInsets())
                }

            }
            .environment(\.defaultMinListRowHeight, 20)
            .listStyle(PlainListStyle())
        }
        .onAppear(perform: {
            viewModel.startDownloadReport()
        })
        .navigationTitle("Debug")
        .padding()
    }

}

extension DebugView {
    class ViewModel: ObservableObject {
        @Published var report: DownloadReport?
        func startDownloadReport() {
            report = Downloader.report()
        }
    }
}
