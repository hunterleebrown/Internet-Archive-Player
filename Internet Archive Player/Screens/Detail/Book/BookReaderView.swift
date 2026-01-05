//
//  BookReaderView.swift
//  Internet Archive Player
//
//  Created on 1/4/26.
//

import SwiftUI
import iaAPI
import Photos

struct BookReaderView: View {
    @StateObject private var viewModel: BookReaderViewModel
    @Environment(\.dismiss) private var dismiss
    
    let archive: Archive
    let zipFileName: String
    
    @State private var showingPagePicker = false
    @State private var isControlsVisible = true
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var isSavingImage = false
    
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
        .alert("Save Image", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    /// Save the current page image to Photos
    private func saveCurrentPageImage() {
        guard !isSavingImage else { return }
        
        isSavingImage = true
        
        Task {
            do {
                // Get the image URL for current page
                guard let imageURL = viewModel.urlForPage(viewModel.currentPage) else {
                    showSaveError("Failed to generate image URL")
                    return
                }
                
                // Download the image
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                
                guard let image = UIImage(data: data) else {
                    showSaveError("Failed to load image")
                    return
                }
                
                // Check photo library permission
                let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
                
                switch status {
                case .notDetermined:
                    let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                    if newStatus == .authorized || newStatus == .limited {
                        await saveImage(image)
                    } else {
                        showSaveError("Photo library access denied. Please enable in Settings.")
                    }
                    
                case .authorized, .limited:
                    await saveImage(image)
                    
                case .denied, .restricted:
                    showSaveError("Photo library access denied. Please enable in Settings.")
                    
                @unknown default:
                    showSaveError("Unable to access photo library")
                }
                
            } catch {
                showSaveError("Failed to download image: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                isSavingImage = false
            }
        }
    }
    
    @MainActor
    private func saveImage(_ image: UIImage) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            
            saveAlertMessage = "Image saved to Photos successfully!"
            showingSaveAlert = true
            
        } catch {
            saveAlertMessage = "Failed to save image: \(error.localizedDescription)"
            showingSaveAlert = true
        }
    }
    
    @MainActor
    private func showSaveError(_ message: String) {
        saveAlertMessage = message
        showingSaveAlert = true
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
            
            // Save Image Button
            Button {
                saveCurrentPageImage()
            } label: {
                HStack(spacing: 8) {
                    if isSavingImage {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 20))
                    }
                    Text(isSavingImage ? "Saving..." : "Save to Photos")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .disabled(isSavingImage)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .padding(.top, 12)
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


