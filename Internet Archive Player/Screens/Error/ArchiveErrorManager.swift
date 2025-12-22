//
//  ArchiveErrorManager.swift
//  Internet Archive Player
//
//  Created by Assistant on 12/21/24.
//

import Foundation
import Combine
import iaAPI

/// Centralized manager for handling and displaying Archive service errors throughout the app
@MainActor
class ArchiveErrorManager: ObservableObject {
    /// Shared singleton instance
    static let shared = ArchiveErrorManager()
    
    /// The current error message to display, if any
    @Published var errorMessage: String?
    
    private init() {}
    
    /// Display an ArchiveServiceError
    /// - Parameter error: The ArchiveServiceError to display
    func showError(_ error: ArchiveServiceError) {
        errorMessage = error.description
    }
    
    /// Display a generic error
    /// - Parameter error: The error to display
    func showError(_ error: Error) {
        if let archiveError = error as? ArchiveServiceError {
            showError(archiveError)
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    /// Display a custom error message
    /// - Parameter message: The error message to display
    func showError(message: String) {
        errorMessage = message
    }
    
    /// Clear the current error
    func clearError() {
        errorMessage = nil
    }
}
