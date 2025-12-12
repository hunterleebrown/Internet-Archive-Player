# Favorite Archives Implementation Guide

## Overview
This implementation adds a new "Favorite Archives" feature that allows users to save entire archive items (metadata) as favorites, separate from the existing file-level favorites.

## What's Been Implemented

### 1. Core Data Extension (`ArchiveMetaData+ArchiveMetaDataEntity.swift`)
- Mapping extension from `ArchiveMetaData` (iaAPI) to `ArchiveMetaDataEntity` (Core Data)
- Convenience computed properties for displaying entity data
- Fetch request configuration

### 2. Persistence Layer Updates (`Persistence.swift`)
Added methods:
- `saveFavoriteArchive(_:)` - Saves an archive metadata as favorite
- `removeFavoriteArchive(identifier:)` - Removes a favorite archive
- `isFavoriteArchive(identifier:)` - Checks if archive is favorited
- `fetchAllFavoriteArchives()` - Retrieves all favorite archives

### 3. Player Integration (`Player.swift`)
- Added `@Published var favoriteArchives: [ArchiveMetaDataEntity]`
- Added `PlayerError.alreadyOnFavoriteArchives` case
- Implemented methods:
  - `addFavoriteArchive(_:)`
  - `removeFavoriteArchive(identifier:)`
  - `isFavoriteArchive(identifier:)`
  - `refreshFavoriteArchives()`
- Loads favorite archives on initialization

### 4. Detail View Updates (`Detail.swift`)
- Added heart button to toggle favorite status
- Added `@State var isFavoriteArchive: Bool`
- Added `@State var favoriteArchivesErrorAlertShowing: Bool`
- Implemented `toggleFavoriteArchive()` function
- Checks favorite status on appear
- Shows filled/unfilled heart based on status

### 5. Favorite Archives List View (`FavoriteArchivesView.swift`)
- Full list view for displaying saved favorite archives
- Supports deletion via swipe or edit mode
- Empty state with helpful message
- Navigation to Detail view on tap
- Custom row view with icon, title, creator, publisher, and media type

## What You Need To Do

### ⚠️ CRITICAL: Add Core Data Entity Definition

You need to add the `ArchiveMetaDataEntity` to your Core Data model file:

1. Open `InternetArchivePlayer.xcdatamodeld` in Xcode
2. Click the "+" button to add a new Entity
3. Name it: `ArchiveMetaDataEntity`
4. Add the following attributes:

| Attribute Name | Type | Optional | Default |
|---------------|------|----------|---------|
| identifier | String | NO | - |
| title | String | YES | - |
| archiveTitle | String | YES | - |
| mediatype | String | YES | - |
| creator | String | YES | - |
| publisher | String | YES | - |
| desc | String | YES | - |
| iconUrlString | String | YES | - |
| dateAdded | Date | YES | - |

5. Set `identifier` as an indexed property (for faster lookups)
6. In the Data Model Inspector, set the Codegen to "Class Definition" or "Manual/None" (if you prefer manual)

### Optional Enhancements

#### Add to Navigation/Menu
You'll want to add a way for users to access the `FavoriteArchivesView`. Consider adding it to:
- Your main navigation menu
- A tab bar item
- A button in the home view
- Settings or profile section

Example:
```swift
NavigationLink(destination: FavoriteArchivesView()) {
    Label("Favorite Archives", systemImage: "heart.fill")
}
```

#### Show Favorite Count Badge
You could show a badge with the count:
```swift
Text("Favorite Archives (\(iaPlayer.favoriteArchives.count))")
```

#### Add Search/Filter to FavoriteArchivesView
If users accumulate many favorites, consider adding:
- Search bar to filter by title/creator
- Segmented control to filter by media type
- Sort options (date added, alphabetical, etc.)

#### Add Haptic Feedback
In `toggleFavoriteArchive()`:
```swift
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()
```

## Testing Checklist

- [ ] Core Data entity is properly defined
- [ ] App builds without errors
- [ ] Can favorite an archive from Detail view
- [ ] Heart button shows filled state when favorited
- [ ] Can unfavorite by tapping heart again
- [ ] Favorite Archives list displays saved items correctly
- [ ] Can navigate to Detail from Favorite Archives list
- [ ] Can delete items from Favorite Archives list
- [ ] Favorites persist after app restart
- [ ] Duplicate check works (trying to favorite same archive twice)
- [ ] Empty state shows when no favorites exist

## Architecture Notes

### Why This Approach?
- **Separation of Concerns**: `ArchiveMetaData` stays as a pure DTO from iaAPI
- **Follows Existing Pattern**: Mirrors `ArchiveFile` → `ArchiveFileEntity`
- **Lightweight Storage**: Only metadata is saved, not full file listings
- **Lazy Loading**: Full archive details fetched only when user taps

### Data Flow
1. User views archive in Detail view
2. Taps heart button
3. `ArchiveMetaData` → converted to `ArchiveMetaDataEntity`
4. Saved to Core Data
5. Player's `favoriteArchives` array updated
6. UI updates to show filled heart

### Future Considerations
- Consider adding iCloud sync for favorites
- Export/import favorites as JSON
- Share favorite archives list with others
- Add tags or categories to organize favorites
- Recently added section in Favorite Archives

## Questions?
If you run into any issues:
1. Check that the Core Data entity is properly defined
2. Verify entity name matches exactly: `ArchiveMetaDataEntity`
3. Clean build folder (Cmd+Shift+K)
4. Ensure all new files are in your target's compile sources
