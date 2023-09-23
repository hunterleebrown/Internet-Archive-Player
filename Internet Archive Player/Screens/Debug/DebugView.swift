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
                    HStack(alignment: .top, spacing: 5){
                        Text(downloadedFile.name)
                            .font(.caption)
                        Spacer()
                        Text("\(downloadedFile.size)")
                            .font(.caption)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
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
