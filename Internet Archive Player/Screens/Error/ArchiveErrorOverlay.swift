//
//  ArchiveErrorOverlay.swift
//  Internet Archive Player
//
//  Created by Assistant on 12/21/24.
//

import SwiftUI
import iaAPI

/// A universal overlay that displays Archive service errors with a dismiss button
struct ArchiveErrorOverlay: View {
    let errorMessage: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Error card - slides down from top (full width)
            VStack(spacing: 0) {
                // Header with icon and title
                HStack(spacing: 12) {
                    Spacer()
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.fairyCream)
                    
                    Text("Error")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.fairyCream)
                    
                    Spacer()
                    
                    // Close button (positioned absolutely)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.fairyRed)
                .overlay(alignment: .trailing) {
                    // Close button overlaid on the right
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.fairyCream.opacity(0.8))
                    }
                    .padding(.trailing, 20)
                }
                
                Divider()
                    .background(Color.fairyCream.opacity(0.3))
                
                // Error message - natural height based on content
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.fairyCream)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(Color.fairyRed)
            }
            .frame(maxWidth: .infinity) // Full screen width
            .background(Color.fairyRed)
            .ignoresSafeArea(edges: .horizontal) // Ignore horizontal safe area
        }
    }
}

/// Environment key for managing error display
struct ArchiveErrorKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

extension EnvironmentValues {
    var archiveError: Binding<String?> {
        get { self[ArchiveErrorKey.self] }
        set { self[ArchiveErrorKey.self] = newValue }
    }
}

/// View modifier that adds error overlay capability
struct ArchiveErrorModifier: ViewModifier {
    @Binding var errorMessage: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let error = errorMessage {
                ArchiveErrorOverlay(errorMessage: error) {
                    errorMessage = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: errorMessage != nil)
    }
}

extension View {
    /// Adds a universal error overlay for displaying Archive service errors
    /// - Parameter errorMessage: Binding to the error message string
    func archiveErrorOverlay(_ errorMessage: Binding<String?>) -> some View {
        modifier(ArchiveErrorModifier(errorMessage: errorMessage))
    }
}

// MARK: - Preview
struct ArchiveErrorOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            ArchiveErrorOverlay(
                errorMessage: "Failed to load archive: The requested item could not be found on the Internet Archive servers. Please check the identifier and try again.",
                onDismiss: {}
            )
        }
    }
}
