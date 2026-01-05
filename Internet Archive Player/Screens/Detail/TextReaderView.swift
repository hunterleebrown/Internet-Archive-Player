//
//  TextReaderView.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//

import SwiftUI
import iaAPI

/// A view for reading large text files (like .djvutxt) in chunks to avoid memory issues
struct TextReaderView: View {
    @StateObject private var viewModel: TextReaderViewModel
    @Environment(\.dismiss) private var dismiss
    
    let archiveFile: ArchiveFile
    
    @State private var isControlsVisible = true
    @State private var showingSettings = false
    
    init(archiveFile: ArchiveFile) {
        self.archiveFile = archiveFile
        print("📄 [TextReaderView] Initializing with file: \(archiveFile.name ?? "unknown")")
        
        _viewModel = StateObject(wrappedValue: TextReaderViewModel(archiveFile: archiveFile))
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.displayText.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else {
                textContentView
            }
            
            // Overlay Controls
            if isControlsVisible {
                overlayControls
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(archiveFile.title ?? archiveFile.name ?? "Text File")
        .toolbar {
            if isControlsVisible {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.increaseFontSize()
                        } label: {
                            Label("Increase Font Size", systemImage: "textformat.size.larger")
                        }
                        
                        Button {
                            viewModel.decreaseFontSize()
                        } label: {
                            Label("Decrease Font Size", systemImage: "textformat.size.smaller")
                        }
                        
                        Divider()
                        
                        Button {
                            viewModel.resetFontSize()
                        } label: {
                            Label("Reset Font Size", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "textformat.size")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadInitialContent()
        }
    }
    
    private var textContentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.displayText)
                        .font(.system(size: viewModel.fontSize))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("textContent")
                    
                    // Load more indicator
                    if viewModel.hasMoreContent {
                        Button {
                            viewModel.loadMoreContent()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                }
                                
                                Text(viewModel.isLoading ? "Loading..." : "Load More")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .padding()
                        }
                        .disabled(viewModel.isLoading)
                    } else if !viewModel.displayText.isEmpty {
                        Text("End of file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .onTapGesture {
                    withAnimation {
                        isControlsVisible.toggle()
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
            
            Text("Loading text file...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error Loading Text")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                viewModel.loadInitialContent()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var overlayControls: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                // Progress info
                VStack(spacing: 4) {
                    Text("\(viewModel.percentageRead)% read")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.bytesReadFormatted) of \(viewModel.totalSizeFormatted)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.5))
                
                // Font size info
                VStack(spacing: 4) {
                    Text("Font Size")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("\(Int(viewModel.fontSize)) pt")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.75))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

