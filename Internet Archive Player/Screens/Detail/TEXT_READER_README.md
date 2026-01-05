# Text Reader Implementation

## Overview
I've implemented a memory-efficient text reader for viewing `.djvutxt` files in your Internet Archive Player app. The implementation follows the same patterns as your existing `BookReaderView` and integrates seamlessly with the Detail view.

## Files Created

### 1. `TextReaderView.swift`
The main SwiftUI view for displaying text content. Features include:
- **Chunked loading UI** - Shows "Load More" button when there's more content
- **Font size controls** - Menu in toolbar to increase/decrease/reset font size
- **Reading progress** - Shows percentage read and bytes loaded
- **Text selection** - Users can select and copy text
- **Error handling** - Graceful error display with retry option
- **Loading states** - Shows progress indicator while loading

### 2. `TextReaderViewModel.swift`
The view model that handles all the heavy lifting:
- **Chunked file reading** - Loads 50KB chunks at a time (about 25,000 characters)
- **File downloading** - Downloads the file from the ArchiveFile URL
- **File handle management** - Uses FileHandle to read large files without loading entirely into memory
- **Progress tracking** - Tracks bytes read and percentage complete
- **Font size persistence** - Saves user's font size preference to UserDefaults
- **Encoding support** - Tries UTF-8 first, falls back to ASCII if needed
- **Cleanup** - Properly closes file handles and removes temporary files

## How It Works

### Memory Efficiency
Instead of loading the entire file into memory, the viewer:
1. Downloads the file to a temporary location
2. Opens a FileHandle to the file
3. Reads only 50KB chunks at a time
4. Displays the accumulated text
5. Loads more chunks when user taps "Load More"

### User Experience
The text reader provides a vertical scrolling experience (more natural for text than page-by-page):
- Initial load shows the first 50KB of text
- Users can scroll through the loaded content
- At the bottom, a "Load More" button appears if there's more content
- Progress indicator shows how much of the file has been loaded
- Font size can be adjusted via the toolbar menu
- Text is selectable for copying

### Integration with Detail View
The text files section now has NavigationLinks that open the TextReaderView:
```swift
ForEach(self.viewModel.txtFiles, id: \.self) { file in
    NavigationLink {
        TextReaderView(archiveFile: file)
    } label: {
        self.createFileView(file)
            .padding(.leading, 5.0)
            .padding(.trailing, 5.0)
    }
}
```

## Features

### Font Size Control
- **Increase**: Toolbar menu option (12pt to 32pt range)
- **Decrease**: Toolbar menu option
- **Reset**: Returns to default 16pt
- **Persistence**: Font size preference is saved across sessions

### Progress Tracking
- Shows percentage of file read
- Displays bytes loaded vs. total file size
- Uses ByteCountFormatter for human-readable sizes

### Error Handling
The viewer handles various error scenarios:
- No URL available
- Download failures
- File handle errors
- Encoding issues
- Network cancellations

### Controls
- **Tap content**: Toggle controls visibility
- **Overlay controls**: Show reading progress and font size
- **Toolbar menu**: Font size adjustments
- **Load More button**: Fetch additional chunks

## Configuration

### Chunk Size
Currently set to 50KB per chunk. You can adjust this in `TextReaderViewModel.swift`:
```swift
private let chunkSize: Int = 50_000 // Adjust this value
```

Larger chunks = fewer load operations but more memory usage
Smaller chunks = more frequent loads but less memory usage

### Font Size Range
Default range is 12pt to 32pt. Adjust in `TextReaderViewModel.swift`:
```swift
private let minFontSize: CGFloat = 12
private let maxFontSize: CGFloat = 32
private let defaultFontSize: CGFloat = 16
```

## Usage

Users can now:
1. Navigate to any archive detail page
2. Scroll to the "Text Files" section (if available)
3. Tap on any `.djvutxt` file
4. View the text with smooth scrolling
5. Load more content as needed
6. Adjust font size to their preference
7. Select and copy text passages

## Testing Recommendations

Test with:
- Small text files (< 50KB) - Should load completely on first load
- Medium text files (50KB - 500KB) - Should require a few "Load More" taps
- Large text files (> 1MB) - Should demonstrate the memory efficiency
- Files with different encodings (UTF-8, ASCII, etc.)

## Future Enhancements

Possible improvements:
- Search within text
- Bookmarking positions
- Dark mode optimizations
- Auto-loading chunks as user scrolls near the bottom
- Table of contents detection (for structured text)
- Different theme options (serif/sans-serif fonts)

## Notes

- Files are downloaded to a temporary directory and cleaned up on dismissal
- The ArchiveFile's default URL is used (as you specified)
- The implementation is iOS-friendly and uses modern Swift Concurrency
- Follows your app's existing patterns (similar to BookReaderView structure)
