# Book Reader Implementation Guide

This guide covers the Internet Archive Book Reader implementation using SwiftUI and UIPageViewController.

## Overview

The Book Reader allows users to flip through book pages from Internet Archive's digitized book collection. It uses the BookReader API to fetch individual page images and displays them in a page-curl interface.

## Architecture

### Components

1. **BookReaderViewModel** - Manages state and URL generation
2. **BookPageViewController** - UIKit view controller for individual pages
3. **BookPageViewControllerRepresentable** - SwiftUI wrapper for UIPageViewController
4. **BookReaderView** - Main SwiftUI view with controls
5. **BookReaderImageCache** - Image caching for better performance

### URL Structure

The Internet Archive BookReader uses the following URL pattern:

```
https://{host}/BookReader/BookReaderImages.php?zip={zip}&file={file}&id={identifier}&rotate={rotate}
```

Where:
- **host**: From `Archive.d1` (e.g., `ia800100.us.archive.org`)
- **zip**: `{Archive.dir}/{zipFileName}` (e.g., `/0/items/book-id/book-id_jp2.zip`)
- **file**: `{baseFileName}/{baseFileName}_XXXX.jp2` (e.g., `book-id/book-id_0001.jp2`)
- **id**: `Archive.metadata.identifier`
- **rotate**: Usually `0` (no rotation)

## Usage

### Basic Integration

```swift
import SwiftUI

struct DetailView: View {
    @StateObject var viewModel: DetailViewModel
    @State private var showingBookReader = false
    
    var body: some View {
        VStack {
            // Your existing content
            
            if viewModel.hasReadableBook {
                Button("Read Book") {
                    showingBookReader = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingBookReader) {
            if let archive = viewModel.archive,
               let zipFileName = viewModel.getBookReaderZipFile() {
                NavigationView {
                    BookReaderView(archive: archive, zipFileName: zipFileName)
                }
            }
        }
    }
}
```

### Navigation Link Integration

```swift
NavigationLink {
    if let archive = viewModel.archive,
       let zipFileName = viewModel.getBookReaderZipFile() {
        BookReaderView(archive: archive, zipFileName: zipFileName)
    }
} label: {
    Label("Read Book", systemImage: "book.fill")
}
```

## Features

### Current Features

- ✅ Page-curl transition effect
- ✅ Swipe navigation between pages
- ✅ Tap to show/hide controls
- ✅ Page picker for jumping to specific pages
- ✅ Navigation buttons (previous/next)
- ✅ Page counter display
- ✅ Pinch-to-zoom and double-tap zoom
- ✅ Image caching for better performance
- ✅ Loading indicators
- ✅ Error handling with retry

### User Interactions

1. **Swipe** - Navigate between pages
2. **Tap** - Show/hide overlay controls
3. **Double Tap** - Zoom in/out
4. **Pinch** - Zoom to specific scale
5. **Page Picker Button** - Jump to any page

## DetailViewModel Extensions

The following methods were added to `DetailViewModel`:

```swift
/// Get the JP2 zip file for book reading
public func getBookReaderZipFile() -> String? {
    return textFiles.first { $0.format == .singlePageProcessedJP2Zip }?.name
}

/// Check if this archive has a readable book
public var hasReadableBook: Bool {
    return getBookReaderZipFile() != nil && archive != nil
}
```

## Performance Considerations

### Image Caching

The `BookReaderImageCache` implements an LRU (Least Recently Used) cache:
- Maximum 50 images cached
- Automatic eviction of oldest images
- Thread-safe using Swift actors

### View Controller Reuse

The `BookPageViewControllerRepresentable.Coordinator` caches view controllers to avoid recreating them when navigating back to previously viewed pages.

### Lazy Loading

Images are only loaded when their page becomes visible, reducing memory usage and network requests.

## Customization

### Changing Transition Style

In `BookPageViewControllerRepresentable.makeUIViewController`:

```swift
// Current: Page curl effect
let pageViewController = UIPageViewController(
    transitionStyle: .pageCurl,
    navigationOrientation: .horizontal,
    options: nil
)

// Alternative: Scroll effect
let pageViewController = UIPageViewController(
    transitionStyle: .scroll,
    navigationOrientation: .horizontal,
    options: nil
)
```

### Adjusting Cache Size

In `BookReaderImageCache`:

```swift
private let maxCacheSize = 50 // Change this value
```

### Customizing Controls

Modify the `overlayControls` computed property in `BookReaderView`:

```swift
private var overlayControls: some View {
    VStack {
        Spacer()
        // Customize your controls here
    }
}
```

## Error Handling

The implementation handles several error scenarios:

1. **Network Errors** - Shows error message with page number
2. **Invalid Images** - Displays error placeholder
3. **Missing Pages** - Handled gracefully with error state
4. **HTTP Errors** - Detects and displays appropriate messages

## Advanced Features

### Using the Cached Version

For better performance with zoom support, replace `BookPageViewController` with `CachedBookPageViewController` in the representable:

```swift
// In BookPageViewControllerRepresentable.Coordinator
func viewController(for page: Int) -> CachedBookPageViewController? {
    guard page > 0 && page <= parent.viewModel.totalPages,
          let url = parent.viewModel.urlForPage(page) else {
        return nil
    }
    
    if let existingVC = viewControllers[page] {
        return existingVC
    }
    
    let vc = CachedBookPageViewController(pageNumber: page, imageURL: url)
    viewControllers[page] = vc
    return vc
}
```

### Setting Total Pages

If you know the exact number of pages, set it in the view model:

```swift
viewModel.configure(archive: archive, zipFileName: zipFileName)
viewModel.totalPages = 250 // Set actual page count
```

### Adding Bookmarks

You can extend the `BookReaderViewModel` to support bookmarks:

```swift
@Published var bookmarks: Set<Int> = []

func toggleBookmark(_ page: Int) {
    if bookmarks.contains(page) {
        bookmarks.remove(page)
    } else {
        bookmarks.insert(page)
    }
}

func isBookmarked(_ page: Int) -> Bool {
    bookmarks.contains(page)
}
```

## Testing

### Manual Testing Checklist

- [ ] Page curl animation works smoothly
- [ ] Can navigate forward and backward
- [ ] Controls show/hide on tap
- [ ] Page picker opens and functions correctly
- [ ] Images load and display correctly
- [ ] Zoom in/out works (if using cached version)
- [ ] Error states display properly
- [ ] Navigation bar updates with current page
- [ ] App doesn't crash on edge cases (page 0, beyond total)

### Testing with Real Data

Find a book archive identifier from archive.org (e.g., "goodytwoshoes00newyiala") and test:

```swift
let testArchive = // Fetch archive with identifier
let zipFile = // Get .singlePageProcessedJP2Zip file
BookReaderView(archive: testArchive, zipFileName: zipFile)
```

## Troubleshooting

### Images Not Loading

1. Check that `archive.d1` is not nil
2. Verify `archive.dir` is properly formatted
3. Ensure the zip file name is correct
4. Test the generated URL in a browser

### Page Navigation Not Working

1. Verify `totalPages` is set correctly
2. Check that URL generation returns valid URLs
3. Ensure the coordinator is properly managing view controllers

### Memory Issues

1. Reduce `maxCacheSize` in `BookReaderImageCache`
2. Clear cache when view disappears:
   ```swift
   .onDisappear {
       Task {
           await BookReaderImageCache.shared.clearCache()
       }
   }
   ```

## Future Enhancements

Potential improvements:

- [ ] Thumbnail grid view
- [ ] Search within book text (OCR)
- [ ] Bookmark persistence
- [ ] Reading progress tracking
- [ ] Text selection and copying
- [ ] Night mode with inverted colors
- [ ] Page preloading for smoother experience
- [ ] Landscape orientation support
- [ ] Split view for two-page spread

## API Reference

### BookReaderViewModel

```swift
@MainActor
final class BookReaderViewModel: ObservableObject {
    @Published var currentPage: Int
    @Published var totalPages: Int
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    
    func configure(archive: Archive, zipFileName: String)
    func urlForPage(_ pageNumber: Int) -> URL?
    func nextPage()
    func previousPage()
    func goToPage(_ page: Int)
    var canGoNext: Bool { get }
    var canGoPrevious: Bool { get }
}
```

### BookReaderView

```swift
struct BookReaderView: View {
    let archive: Archive
    let zipFileName: String
    
    init(archive: Archive, zipFileName: String)
}
```

## License

This implementation is part of the Internet Archive Player project.

## Credits

- Internet Archive BookReader API
- UIKit Page View Controller
- SwiftUI

---

For questions or issues, please refer to the main project documentation.
