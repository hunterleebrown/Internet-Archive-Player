//
//  DebugView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 9/20/23.
//

import Foundation
import SwiftUI

struct DebugView: View {

    @State var report: DownloadReport = Downloader.report()

    var body: some View {
        VStack{
            HStack{
                Text("Downloaded files: ")
                    .foregroundColor(.fairyRed)
                Text("\(report.files.count)")
                Spacer()
                Text("\(report.totalSize())")
            }
            List{
                ForEach(report.files, id: \.self) { downloadedFile in
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
        .navigationTitle("Debug")
        .padding()
    }

}
