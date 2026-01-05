//
//  BookReaderView.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//

import SwiftUI
import iaAPI

struct BookReaderView: View {
    @StateObject private var viewModel: BookReaderViewModel
    @Environment(\.dismiss) private var dismiss
    
    let archive: Archive
    let zipFileName: String
    
    @State private var showingPagePicker = false
    @State private var isControlsVisible = true
    
    init(archive: Archive, zipFileName: String) {
        self.archive = archive
        self.zipFileName = zipFileName
        print("📖 [BookReaderView] Initializing with archive: \(archive.metadata?.identifier ?? "unknown")")
        
        // Initialize the view model with the data immediately
        _viewModel = StateObject(wrappedValue: BookReaderViewModel(archive: archive, zipFileName: zipFileName))
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // Page View Controller
            BookPageViewControllerRepresentable(
                viewModel: viewModel,
                currentPage: $viewModel.currentPage
            )
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation {
                    isControlsVisible.toggle()
                }
            }
            
            // Overlay Controls
            if isControlsVisible {
                overlayControls
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Page \(viewModel.currentPage) of \(viewModel.totalPages)")
        .navigationBarBackButtonHidden(isControlsVisible)
        .toolbar {
            if isControlsVisible {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingPagePicker.toggle()
                    } label: {
                        Image(systemName: "list.number")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPagePicker) {
            PagePickerView(
                currentPage: $viewModel.currentPage,
                totalPages: viewModel.totalPages
            )
        }
    }
    
    private var overlayControls: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 40) {
                // Previous Page Button
                Button {
                    viewModel.previousPage()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .opacity(viewModel.canGoPrevious ? 1.0 : 0.3)
                }
                .disabled(!viewModel.canGoPrevious)
                
                // Page Info
                VStack(spacing: 8) {
                    Text("Page \(viewModel.currentPage)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("of \(viewModel.totalPages)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Next Page Button
                Button {
                    viewModel.nextPage()
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .opacity(viewModel.canGoNext ? 1.0 : 0.3)
                }
                .disabled(!viewModel.canGoNext)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// Page picker sheet for jumping to a specific page
struct PagePickerView: View {
    @Binding var currentPage: Int
    let totalPages: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPage: Int
    
    init(currentPage: Binding<Int>, totalPages: Int) {
        self._currentPage = currentPage
        self.totalPages = totalPages
        self._selectedPage = State(initialValue: currentPage.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Jump to Page")
                    .font(.headline)
                    .padding(.top)
                
                Picker("Page", selection: $selectedPage) {
                    ForEach(1...totalPages, id: \.self) { page in
                        Text("Page \(page)")
                            .tag(page)
                    }
                }
                .pickerStyle(.wheel)
                
                Button("Go to Page") {
                    currentPage = selectedPage
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


