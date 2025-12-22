# Archive Error Overlay - Implementation Guide

## Overview

A universal error overlay system has been implemented to display `ArchiveServiceError` messages throughout the Internet Archive Player app. The system consists of three main components:

### 1. **ArchiveErrorOverlay.swift** - UI Component
A reusable SwiftUI view that displays errors in a modal overlay with:
- Semi-transparent backdrop
- Error card with icon and title
- Scrollable error message
- Close button (X icon in header)
- Dismiss button at bottom
- Smooth animations

### 2. **ArchiveErrorManager.swift** - State Manager
A singleton `@MainActor` class that manages error state globally:
- `@Published var errorMessage: String?` - The current error to display
- `showError(_ error: ArchiveServiceError)` - Display an archive error
- `showError(_ error: Error)` - Display any error
- `showError(message: String)` - Display custom message
- `clearError()` - Dismiss the current error

### 3. **View Modifier** - Integration
A `.archiveErrorOverlay()` modifier added to the root Home view that:
- Observes the `ArchiveErrorManager.shared.errorMessage`
- Displays the overlay when an error exists
- Handles dismissal with animation

## How It Works

### Automatic Error Display

All ViewModels that call `PlayerArchiveService` methods now automatically show errors in the universal overlay:

**Files Updated:**
- ✅ `DetailViewModel.swift` (iOS Detail view)
- ✅ `TVDetail.swift` (tvOS Detail view)
- ✅ `SearchView.swift` (iOS Search)
- ✅ `TVSearchView.swift` (tvOS Search - already had good error handling)
- ✅ `CollectionFilterCache.swift` (Collection filters)

Each catch block now includes:
```swift
} catch let error as ArchiveServiceError {
    // Local error handling...
    self.errorMessage = "Failed to load: \(error.description)"
    self.hasError = true
    
    // Show in universal overlay
    ArchiveErrorManager.shared.showError(error)
}
```

### Manual Error Display

You can trigger the error overlay from anywhere in the app:

```swift
// From any view or view model
ArchiveErrorManager.shared.showError(message: "Something went wrong!")

// Or with an ArchiveServiceError
ArchiveErrorManager.shared.showError(ArchiveServiceError.nodata)

// Or with any error
do {
    try somethingThatThrows()
} catch {
    ArchiveErrorManager.shared.showError(error)
}

// Dismiss manually if needed
ArchiveErrorManager.shared.clearError()
```

## User Experience

1. **Error Occurs**: When a `PlayerArchiveService` call fails
2. **Overlay Appears**: A centered card slides in with scale animation
3. **User Dismissal**: User can:
   - Tap the X button in the header
   - Tap the "Dismiss" button at the bottom
   - Tap outside the card (on the backdrop)
4. **Overlay Closes**: Smooth fade-out animation

## Architecture Benefits

### ✅ Centralized Error Handling
- Single source of truth for error display
- Consistent UI/UX across the entire app
- Easy to modify styling in one place

### ✅ Non-Intrusive
- Errors don't block the entire UI
- Users can easily dismiss and continue
- Doesn't interfere with navigation

### ✅ Flexible
- Can be triggered from any view or view model
- Works with specific error types or custom messages
- Supports both automatic and manual error display

### ✅ Maintainable
- ViewModels still maintain their own error properties for local display
- Universal overlay is additive, not replacing existing error handling
- Easy to extend with additional error types

## Styling

The error overlay uses:
- **Colors**: `.fairyRed` for error icon and action button
- **Font Weights**: Bold headers, semibold buttons
- **Spacing**: Consistent 20pt padding
- **Animation**: Spring animation with 0.3s response time
- **Max Width**: 400pt for readability
- **Shadow**: Subtle shadow for depth

## Testing

To test the error overlay:

1. **Trigger a search error**: Search for something that doesn't exist
2. **Trigger a detail error**: Try to load an invalid archive identifier
3. **Trigger a filter error**: Simulate a network failure when loading collections
4. **Test dismissal**: Verify all three dismissal methods work
5. **Test animations**: Check smooth entrance and exit

## Future Enhancements

Potential improvements:
- Add different error severity levels (warning, error, critical)
- Support for actionable errors (retry button)
- Auto-dismiss after a timeout (optional)
- Sound/haptic feedback on error display
- Error logging/analytics integration
- Support for multiple simultaneous errors (queue)
