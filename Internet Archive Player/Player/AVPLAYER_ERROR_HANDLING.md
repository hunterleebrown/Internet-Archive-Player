# AVPlayer Error Handling

## Overview

AVPlayer errors are now automatically detected and surfaced to users through the universal error overlay system. When a media file fails to play, users will see a descriptive error message that slides down from the top of the screen.

## Implementation

### 1. Error Detection

The `Player` class monitors `AVPlayerItem.status` through Key-Value Observing (KVO):

```swift
// In loadAndPlay(_:)
avPlayer.addObserver(
    self, 
    forKeyPath: #keyPath(AVPlayer.currentItem.status), 
    options: [.new, .initial], 
    context: &observerContext
)
```

### 2. Error Handling

When the player item status changes to `.failed`, the error is captured and displayed:

```swift
if newStatus == .failed {
    print("❌ AVPlayer Error: \(error?.localizedDescription)")
    
    // Surface to user via universal error overlay
    if let error = self.avPlayer.currentItem?.error {
        Task { @MainActor in
            let fileName = self.playingFile?.title ?? "Unknown file"
            let errorMessage = "Failed to play \"\(fileName)\": \(error.localizedDescription)"
            ArchiveErrorManager.shared.showError(message: errorMessage)
        }
    }
}
```

## Common AVPlayer Errors

### Network Errors
- **URL not reachable**: "The operation couldn't be completed"
- **Connection timeout**: "The request timed out"
- **No internet connection**: "The Internet connection appears to be offline"

### File Format Errors
- **Unsupported format**: "The operation could not be completed"
- **Corrupted file**: "The media data is invalid"

### Authorization Errors
- **403 Forbidden**: Access denied to the media resource
- **404 Not Found**: Media file doesn't exist at URL

### Playback Errors
- **Streaming failure**: "The media failed to load"
- **Buffer underrun**: Playback interrupted due to insufficient buffer

## Error Message Format

Error messages are formatted to be user-friendly:

```
Failed to play "[File Name]": [Error Description]
```

Examples:
- "Failed to play "song.mp3": The Internet connection appears to be offline."
- "Failed to play "video.mp4": The operation couldn't be completed."

## Testing AVPlayer Errors

### Test Scenarios:

1. **Invalid URL**
   ```swift
   let badURL = URL(string: "https://invalid-domain-12345.com/file.mp3")!
   player.loadAndPlay(badURL)
   ```

2. **404 Not Found**
   ```swift
   let notFoundURL = URL(string: "https://archive.org/download/nonexistent/file.mp3")!
   player.loadAndPlay(notFoundURL)
   ```

3. **Unsupported Format**
   ```swift
   let unsupportedURL = URL(string: "https://example.com/file.xyz")!
   player.loadAndPlay(unsupportedURL)
   ```

4. **Network Disconnected**
   - Turn off WiFi and cellular data
   - Try to play an online stream

5. **Timeout**
   - Use a URL that's extremely slow to respond
   - AVPlayer will timeout after default duration

## User Experience

When an AVPlayer error occurs:

1. ✅ **Error Detected**: AVPlayer status changes to `.failed`
2. ✅ **Console Log**: Error details printed to console for debugging
3. ✅ **User Notification**: Error overlay slides down from top
4. ✅ **User Action**: User can dismiss by:
   - Tapping the X button
   - Tapping outside the overlay
5. ✅ **Playback Stops**: Player pauses and awaits user action

## Architecture Flow

```
┌─────────────────────┐
│ User Taps Play      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Player.loadAndPlay()│
│ - Adds KVO observer │
│ - Replaces item     │
│ - Calls play()      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ AVPlayer attempts   │
│ to load media       │
└──────────┬──────────┘
           │
           ├─────────────────┐
           │                 │
           ▼                 ▼
    ┌──────────┐      ┌──────────────┐
    │ Success  │      │ Failed       │
    │ .status  │      │ .status      │
    │ = .ready │      │ = .failed    │
    └──────────┘      └──────┬───────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ observeValue()   │
                    │ detects .failed  │
                    └──────┬───────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Extract error    │
                    │ from currentItem │
                    └──────┬───────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ ArchiveErrorMgr  │
                    │ .showError()     │
                    └──────┬───────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Error overlay    │
                    │ slides down      │
                    └──────────────────┘
```

## Advanced: Additional Error Monitoring

For more granular error detection, you can also monitor:

### AVPlayerItemFailedToPlayToEndTime Notification

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(playerItemFailedToPlayToEndTime(_:)),
    name: .AVPlayerItemFailedToPlayToEndTime,
    object: nil
)

@objc func playerItemFailedToPlayToEndTime(_ notification: Notification) {
    if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
        Task { @MainActor in
            ArchiveErrorManager.shared.showError(error)
        }
    }
}
```

### AVPlayerItemNewErrorLogEntry Notification

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(playerItemNewErrorLogEntry(_:)),
    name: .AVPlayerItemNewErrorLogEntry,
    object: nil
)

@objc func playerItemNewErrorLogEntry(_ notification: Notification) {
    if let playerItem = notification.object as? AVPlayerItem,
       let errorLog = playerItem.errorLog() {
        // Log error details for debugging
        print("🔴 AVPlayer Error Log: \(errorLog)")
    }
}
```

## Best Practices

1. ✅ **Always observe status**: Monitor `AVPlayerItem.status` for all playback
2. ✅ **Provide context**: Include file name in error messages
3. ✅ **Log to console**: Keep detailed logs for debugging
4. ✅ **User-friendly messages**: Convert technical errors to readable text
5. ✅ **Handle gracefully**: Don't crash, pause and inform user
6. ✅ **Allow retry**: Give users a way to try again
7. ✅ **Clean up observers**: Remove KVO observers when done

## Debugging Tips

### Enable Detailed Logging

```swift
// In Player.swift
if newStatus == .failed {
    if let error = self.avPlayer.currentItem?.error as NSError? {
        print("❌ AVPlayer Error:")
        print("   Domain: \(error.domain)")
        print("   Code: \(error.code)")
        print("   Description: \(error.localizedDescription)")
        print("   Failure Reason: \(error.localizedFailureReason ?? "None")")
        print("   Recovery Suggestion: \(error.localizedRecoverySuggestion ?? "None")")
        print("   User Info: \(error.userInfo)")
    }
}
```

### Check Error Logs

```swift
if let errorLog = avPlayer.currentItem?.errorLog() {
    for event in errorLog.events ?? [] {
        print("Error Event: \(event)")
    }
}
```

## Summary

AVPlayer errors are now fully integrated with the universal error overlay system:

- ✅ Automatic detection via KVO
- ✅ User-friendly error messages
- ✅ Consistent UI with other app errors
- ✅ Clean error handling without crashes
- ✅ Detailed logging for debugging

All playback errors will now be visible to users, helping them understand when and why media fails to play! 🎉
