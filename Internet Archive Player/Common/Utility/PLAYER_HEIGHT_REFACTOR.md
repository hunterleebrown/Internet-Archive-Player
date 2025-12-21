# Player Height Auto-Calculation Refactor

## Summary
Refactored the player height management system to automatically calculate the player control's height and provide a cleaner API for child views to avoid the player.

## Changes Made

### 1. Created `PlayerSafeAreaModifier.swift`
- New file with `AvoidPlayerModifier` view modifier
- Provides `.avoidPlayer()` extension method for all views
- Centralizes the safe area logic in one place

### 2. Updated `PlayerControls.swift`
- Added `PlayerHeightPreferenceKey` for communicating height changes
- Height is now measured in Home.swift to include tab bar padding

### 3. Updated `Home.swift`
- Added `.onPreferenceChange(PlayerHeightPreferenceKey.self)` to receive automatic height updates
- Added `.onChange(of: showControls)` to immediately set height to 0 when hiding
- Modified `showControlsPass` receiver to:
  - Set height to 0 immediately when hiding
  - Use fallback of 160 only if height hasn't been calculated yet (first-time edge case)
  - Otherwise let GeometryReader provide the actual height
- Replaced manual `.safeAreaInset` with `.avoidPlayer()`
- **Removed dead code:**
  - Removed `maxControlHeight` state variable (never read)
  - Removed `controlHeightPass` PassthroughSubject (never sent to)
  - Removed hardcoded height setting in speaker wave button toggle
  - Removed `.onReceive(Home.controlHeightPass)` handler

### 4. Updated All Child Views
Replaced verbose `.safeAreaInset` code with simple `.avoidPlayer()` call in:
- `FavoriteArchivesView.swift`
- `SingleListView.swift`
- `ListsView.swift` (both list and carousel layouts)
- `OtherPlaylist.swift`
- `SearchView.swift` (also removed custom `playerSafeArea` computed property)
- `NewFavoritesView.swift`
- `NowPlaying.swift` (the actual scrollable content view)

**Important:** `.avoidPlayer()` should be applied to the **scrollable content view** (List, ScrollView, etc.), not to parent containers or wrappers.

## Benefits

### Before:
```swift
.safeAreaInset(edge: .bottom) {
    if showControls {  // Sometimes conditional
        Spacer()
            .frame(height: iaPlayer.playerHeight)
    }
}
```

### After:
```swift
.avoidPlayer()
```

### Key Improvements:
1. **No magic numbers** - Height is calculated automatically based on actual content
2. **One-line usage** - Much cleaner and easier to maintain
3. **Consistent behavior** - All views use the same logic
4. **Auto-adjusting** - If PlayerControls layout changes, height updates automatically
5. **Centralized** - Logic is in one place, easier to debug and modify

## How It Works

1. PlayerControls is wrapped in a VStack with `.padding(.bottom, 59)` for the tab bar
2. A `GeometryReader` in Home.swift measures the **total height** (player controls + tab bar padding)
3. Height is sent via `PlayerHeightPreferenceKey` preference
4. `Home.swift` receives the preference and updates `iaPlayer.playerHeight` (only when controls are visible)
5. When controls are hidden:
   - `.onChange(of: showControls)` immediately sets height to 0
   - `.onReceive(Home.showControlsPass)` also sets to 0 when hidden
6. Child views use `.avoidPlayer()` modifier which:
   - Accesses `iaPlayer` from environment
   - Adds bottom safe area inset only if `playerHeight > 0`
   - Automatically updates when height changes

## Fallback Behavior
- **Showing player:** GeometryReader calculates actual height (controls + 59pt tab bar padding), or uses 219 as fallback (160 + 59) only if height is still 0 (first-time edge case)
- **Hiding player:** Immediately sets height to 0 for instant response
- This ensures smooth transitions and prevents layout jumps
- **Important:** The measured height includes the tab bar padding (59pt) so child views avoid the entire player area including the gap above the tab bar

## Testing Notes
- Test that content doesn't overlap with player controls
- Test that hiding/showing player animates smoothly
- Test that the two-row layout in PlayerControls is measured correctly
- Test across different screen sizes (iPhone, iPad)
- Test that tab bar is never covered by player controls

## Troubleshooting

### Player covers tab bar buttons
- **Cause:** Height measurement doesn't include tab bar padding
- **Solution:** Ensure GeometryReader in Home.swift measures the VStack with `.padding(.bottom, 59)` included

### Player overlaps content in List/ScrollView
- **Cause:** `.avoidPlayer()` applied to parent container instead of scrollable view
- **Solution:** Apply `.avoidPlayer()` directly to the List or ScrollView, not to wrapper VStacks or NavigationStacks

### Content jumps when showing/hiding player
- **Cause:** Height calculation triggering at wrong time or multiple times
- **Solution:** Check that `.onChange(of: showControls)` sets height to 0 immediately when hiding

## Revert Instructions (if needed)
If you need to revert these changes:
1. Delete `PlayerSafeAreaModifier.swift`
2. Remove `.onPreferenceChange(PlayerHeightPreferenceKey.self)` from Home.swift
3. Restore the simple `iaPlayer.playerHeight = show ? 160 : 0` logic
4. Replace all `.avoidPlayer()` calls with the original `.safeAreaInset` code
5. Remove `PlayerHeightPreferenceKey` and GeometryReader from PlayerControls.swift
