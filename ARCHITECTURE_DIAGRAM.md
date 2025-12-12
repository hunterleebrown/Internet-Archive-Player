# Favorite Archives Feature - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE LAYER                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────┐              ┌─────────────────────────┐  │
│  │   Detail.swift       │              │ FavoriteArchivesView    │  │
│  │  ┌────────────────┐  │              │  ┌──────────────────┐   │  │
│  │  │ Heart Button   │  │              │  │  List of Saved   │   │  │
│  │  │ (Toggle Fav)   │  │◄─────────────┤  │  Archives        │   │  │
│  │  └────────────────┘  │  Navigation  │  └──────────────────┘   │  │
│  │                      │              │                         │  │
│  │  Shows filled/       │              │  - Tap to view detail  │  │
│  │  unfilled heart      │              │  - Swipe to delete     │  │
│  └──────────────────────┘              │  - Edit mode           │  │
│            │                            └─────────────────────────┘  │
│            │ toggleFavoriteArchive()              │                  │
│            │                                      │                  │
└────────────┼──────────────────────────────────────┼──────────────────┘
             │                                      │
             ▼                                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        BUSINESS LOGIC LAYER                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Player.swift (@ObservableObject)         │    │
│  │                                                             │    │
│  │  @Published var favoriteArchives: [ArchiveMetaDataEntity]  │    │
│  │                                                             │    │
│  │  Methods:                                                   │    │
│  │  • addFavoriteArchive(ArchiveMetaData) throws              │    │
│  │  • removeFavoriteArchive(identifier: String)               │    │
│  │  • isFavoriteArchive(identifier: String) -> Bool           │    │
│  │  • refreshFavoriteArchives()                               │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                │                                     │
│                                ▼                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              PersistenceController.swift                     │    │
│  │                                                             │    │
│  │  Methods:                                                   │    │
│  │  • saveFavoriteArchive(ArchiveMetaData) throws             │    │
│  │  • removeFavoriteArchive(identifier: String)               │    │
│  │  • isFavoriteArchive(identifier: String) -> Bool           │    │
│  │  • fetchAllFavoriteArchives() -> [ArchiveMetaDataEntity]   │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                │                                     │
└────────────────────────────────┼─────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌───────────────────────┐          ┌──────────────────────────┐    │
│  │  iaAPI Package        │          │    Core Data Model       │    │
│  │  (External)           │          │                          │    │
│  │                       │          │  ArchiveMetaDataEntity   │    │
│  │  ArchiveMetaData      │─────────►│  • identifier: String    │    │
│  │  • identifier         │ Convert  │  • title: String?        │    │
│  │  • title              │  via     │  • archiveTitle: String? │    │
│  │  • creator            │ Extension│  • creator: String?      │    │
│  │  • publisher          │          │  • publisher: String?    │    │
│  │  • description        │          │  • mediatype: String?    │    │
│  │  • iconUrl            │          │  • desc: String?         │    │
│  │  (Read-only DTO)      │          │  • iconUrlString: String?│    │
│  │                       │          │  • dateAdded: Date?      │    │
│  └───────────────────────┘          │  (Persisted)             │    │
│                                     └──────────────────────────┘    │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  ArchiveMetaData+ArchiveMetaDataEntity.swift                │    │
│  │                                                             │    │
│  │  extension ArchiveMetaData {                                │    │
│  │    func archiveMetaDataEntity() -> ArchiveMetaDataEntity    │    │
│  │  }                                                          │    │
│  │                                                             │    │
│  │  extension ArchiveMetaDataEntity {                          │    │
│  │    • iconUrl: URL? { get }                                  │    │
│  │    • displayTitle: String { get }                           │    │
│  │    • displayCreator: String? { get }                        │    │
│  │    • static var archiveMetaDataFetchRequest                 │    │
│  │  }                                                          │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════
                            DATA FLOW
═══════════════════════════════════════════════════════════════════════

ADD TO FAVORITES FLOW:
═════════════════════
1. User taps heart button in Detail view
2. Detail.toggleFavoriteArchive() called
3. Player.addFavoriteArchive(archiveDoc) called
4. PersistenceController.saveFavoriteArchive(metaData) called
5. ArchiveMetaData.archiveMetaDataEntity() creates Core Data entity
6. Entity saved to persistent store
7. Player.refreshFavoriteArchives() updates @Published array
8. UI updates (heart fills, list updates)


REMOVE FROM FAVORITES FLOW:
═══════════════════════════
1. User taps filled heart button OR swipes to delete in list
2. Player.removeFavoriteArchive(identifier) called
3. PersistenceController.removeFavoriteArchive(identifier) called
4. Entity fetched and deleted from Core Data
5. Player.refreshFavoriteArchives() updates @Published array
6. UI updates (heart empties, item removed from list)


VIEW FAVORITES LIST FLOW:
════════════════════════
1. User navigates to FavoriteArchivesView
2. View appears, calls Player.refreshFavoriteArchives()
3. Displays Player.favoriteArchives array
4. User taps an item
5. Navigates to Detail view with identifier
6. Detail view fetches full archive data from API


═══════════════════════════════════════════════════════════════════════
                    COMPARISON WITH EXISTING FEATURES
═══════════════════════════════════════════════════════════════════════

EXISTING: File-Level Favorites (Unchanged)
───────────────────────────────────────────
Player.favoriteItems: [ArchiveFileEntity]
└─ Individual audio/video files
└─ Stored in PlaylistEntity (name: "Favorites")
└─ Can be played directly from list


NEW: Archive-Level Favorites
────────────────────────────
Player.favoriteArchives: [ArchiveMetaDataEntity]  
└─ Entire archive items (albums, shows, etc.)
└─ Stored directly as Core Data entities
└─ Tap to view detail, then select files to play


USE CASES:
─────────
File Favorites: "I love this specific track"
Archive Favorites: "I want to explore this album/show later"
```
