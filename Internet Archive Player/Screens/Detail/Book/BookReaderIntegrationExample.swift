//
//  BookReaderIntegrationExample.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//
//  This file demonstrates how to integrate the BookReaderView into your existing Detail view.

import SwiftUI
import iaAPI

// MARK: - Example Integration

/*
 
 Add this to your Detail view where you want to show the "Read Book" button:
 
 ```swift
 if viewModel.hasReadableBook {
     NavigationLink {
         if let archive = viewModel.archive,
            let zipFileName = viewModel.getBookReaderZipFile() {
             BookReaderView(archive: archive, zipFileName: zipFileName)
         }
     } label: {
         Label("Read Book", systemImage: "book.fill")
             .font(.headline)
             .foregroundColor(.white)
             .frame(maxWidth: .infinity)
             .padding()
             .background(Color.blue)
             .cornerRadius(12)
     }
     .padding()
 }
 ```
 
 Or, if you want to use a sheet presentation:
 
 ```swift
 struct DetailView: View {
     @StateObject var viewModel: DetailViewModel
     @State private var showingBookReader = false
     
     var body: some View {
         VStack {
             // Your existing detail view content
             
             if viewModel.hasReadableBook {
                 Button {
                     showingBookReader = true
                 } label: {
                     Label("Read Book", systemImage: "book.fill")
                         .font(.headline)
                         .foregroundColor(.white)
                         .frame(maxWidth: .infinity)
                         .padding()
                         .background(Color.blue)
                         .cornerRadius(12)
                 }
                 .padding()
             }
         }
         .fullScreenCover(isPresented: $showingBookReader) {
             if let archive = viewModel.archive,
                let zipFileName = viewModel.getBookReaderZipFile() {
                 NavigationView {
                     BookReaderView(archive: archive, zipFileName: zipFileName)
                         .toolbar {
                             ToolbarItem(placement: .navigationBarLeading) {
                                 Button("Done") {
                                     showingBookReader = false
                                 }
                             }
                         }
                 }
             }
         }
     }
 }
 ```
 
 Or in a List with other media items:
 
 ```swift
 Section("Available Formats") {
     // Audio files
     if !viewModel.audioFiles.isEmpty {
         NavigationLink {
             // Audio player view
         } label: {
             Label("Audio (\(viewModel.audioFiles.count) tracks)", systemImage: "music.note")
         }
     }
     
     // Book reader
     if viewModel.hasReadableBook {
         NavigationLink {
             if let archive = viewModel.archive,
                let zipFileName = viewModel.getBookReaderZipFile() {
                 BookReaderView(archive: archive, zipFileName: zipFileName)
             }
         } label: {
             Label("Read Book", systemImage: "book.fill")
         }
     }
     
     // Movies
     if !viewModel.movieFiles.isEmpty {
         NavigationLink {
             // Movie player view
         } label: {
             Label("Video (\(viewModel.movieFiles.count) files)", systemImage: "film")
         }
     }
 }
 ```
 
*/

// MARK: - Sample Detail View with Book Reader Integration

struct DetailViewWithBookReader: View {
    @StateObject var viewModel: DetailViewModel
    @State private var showingBookReader = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Album art or header
                if let image = viewModel.uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(12)
                }
                
                // Title and metadata
                VStack(alignment: .leading, spacing: 8) {
                    if let title = viewModel.archiveDoc?.archiveTitle {
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    if let creator = viewModel.archiveDoc?.creator?.first {
                        Text(creator)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Media types section
                VStack(spacing: 12) {
                    // Audio
                    if !viewModel.audioFiles.isEmpty {
                        mediaButton(
                            title: "Play Audio",
                            subtitle: "\(viewModel.audioFiles.count) tracks",
                            icon: "music.note",
                            color: .blue
                        ) {
                            // Handle audio playback
                        }
                    }
                    
                    // Book Reader
                    if viewModel.hasReadableBook {
                        mediaButton(
                            title: "Read Book",
                            subtitle: "Flip through pages",
                            icon: "book.fill",
                            color: .orange
                        ) {
                            showingBookReader = true
                        }
                    }
                    
                    // Video
                    if !viewModel.movieFiles.isEmpty {
                        mediaButton(
                            title: "Watch Video",
                            subtitle: "\(viewModel.movieFiles.count) files",
                            icon: "film",
                            color: .purple
                        ) {
                            // Handle video playback
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .fullScreenCover(isPresented: $showingBookReader) {
            if let archive = viewModel.archive,
               let zipFileName = viewModel.getBookReaderZipFile() {
                NavigationView {
                    BookReaderView(archive: archive, zipFileName: zipFileName)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    showingBookReader = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
        }
    }
    
    private func mediaButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
