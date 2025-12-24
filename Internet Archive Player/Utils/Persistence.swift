//
//  Persistence.swift
//  CoreDataFun
//
//  Created by Hunter Lee Brown on 4/29/22.
//

import CoreData
import iaAPI

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = ArchiveFileEntity(context: viewContext)
            newItem.title = "Awesome Track"
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "InternetArchivePlayer")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                // Show some error here
                print(error)
            }
        }
    }

    func delete(_ object: NSManagedObject, _ saveOperation: Bool? = true) {
        let context = container.viewContext
        context.delete(object)
        if saveOperation == true {
            self.save()
        }
    }

    public func appendPlaylistItem(file: ArchiveFile, playList: PlaylistEntity) throws {
        let archiveFileEntity = file.archiveFileEntity()
        try self.appendPlaylistItem(archiveFileEntity: archiveFileEntity, playList: playList)
    }

    public func appendPlaylistItem(archiveFileEntity: ArchiveFileEntity, playList: PlaylistEntity) throws {

        if let files = playList.files?.array as? [ArchiveFileEntity] {
            let filtered = files.filter({$0.onlineUrl?.absoluteString == archiveFileEntity.onlineUrl?.absoluteString})
            guard filtered.isEmpty else {
                throw PlayerError.alreadyOnPlaylist
            }
        }

        playList.addToFiles(archiveFileEntity)
        save()
    }

    public func isOnPlaylist(entity: ArchiveFileEntity) -> Bool {
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        do {
            let playlists = try container.viewContext.fetch(fetchRequest)
            var files = [ArchiveFileEntity]()
            playlists.forEach{
                if let af = $0.files?.array as? [ArchiveFileEntity] {
                    files.append(contentsOf: af )
                }
            }

            return files.contains(entity)
        } catch let error {
            print(error)
        }

        return false
    }
    
    /// Returns all playlists that contain the given file entity
    public func getPlaylistsContaining(entity: ArchiveFileEntity) -> [PlaylistEntity] {
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        do {
            let playlists = try container.viewContext.fetch(fetchRequest)
            return playlists.filter { playlist in
                if let playlistFiles = playlist.files?.array as? [ArchiveFileEntity] {
                    return playlistFiles.contains(entity)
                }
                return false
            }
        } catch let error {
            print("Error fetching playlists containing file: \(error)")
            return []
        }
    }

    // MARK: - Favorite Archives
    
    public func saveFavoriteArchive(_ metaData: ArchiveMetaData) throws {
        // Ensure we have a valid identifier
        guard let identifier = metaData.identifier else {
            print("Cannot save favorite archive without identifier")
            return
        }
        
        // Check if already exists
        if isFavoriteArchive(identifier: identifier) {
            throw PlayerError.alreadyOnFavoriteArchives
        }
        
        // Create the entity (returns nil if identifier is missing, but we already checked above)
        guard let _ = metaData.archiveMetaDataEntity() else {
            print("Failed to create ArchiveMetaDataEntity")
            return
        }
        
        save()
    }
    
    public func removeFavoriteArchive(identifier: String) {
        let fetchRequest: NSFetchRequest<ArchiveMetaDataEntity> = ArchiveMetaDataEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        do {
            let results = try container.viewContext.fetch(fetchRequest)
            for entity in results {
                delete(entity, false)
            }
            save()
        } catch {
            print("Error removing favorite archive: \(error)")
        }
    }
    
    public func isFavoriteArchive(identifier: String) -> Bool {
        let fetchRequest: NSFetchRequest<ArchiveMetaDataEntity> = ArchiveMetaDataEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try container.viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking favorite archive: \(error)")
            return false
        }
    }
    
    public func fetchAllFavoriteArchives() -> [ArchiveMetaDataEntity] {
        let fetchRequest = ArchiveMetaDataEntity.archiveMetaDataFetchRequest
        
        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching favorite archives: \(error)")
            return []
        }
    }

}

extension NSManagedObject {
    static public func firstEntity<T: NSManagedObject>(context: NSManagedObjectContext) -> T? {
        guard let name = entity().name else { return nil }

        let fetchRequest = NSFetchRequest<T>(entityName: name)
        do {
            let object = try context.fetch(fetchRequest)
            if let foundObject = object.first { return foundObject }
            return nil
        } catch {
            return nil
        }
    }
}


extension PersistenceController {
    /// Check if a file exists in any playlist other than the one being excluded
    func fileExistsInOtherPlaylists(_ file: ArchiveFileEntity, excluding playlist: PlaylistEntity) -> Bool {
        let allPlaylists = PlaylistEntity.getAllPlaylists()

        for otherPlaylist in allPlaylists where otherPlaylist != playlist {
            if let playlistFiles = otherPlaylist.files?.array as? [ArchiveFileEntity],
               playlistFiles.contains(file) {
                return true
            }
        }

        return false
    }

    /// Clean up ArchiveFileEntity objects that are no longer in any playlist
    func cleanupOrphanedFiles(from files: [ArchiveFileEntity]) {
        for file in files {
            if !isOnPlaylist(entity: file) {
                print("🧹 Cleaning up orphaned ArchiveFileEntity: \(file.name ?? "unknown")")
                delete(file, false)
            }
        }
        save()
    }
    
    /// Clean up all orphaned files that aren't in any playlist
    func cleanupOrphans() {
        let fetchRequest: NSFetchRequest<ArchiveFileEntity> = ArchiveFileEntity.fetchRequest()
        do {
            let allFiles = try container.viewContext.fetch(fetchRequest)
            let orphanedFiles = allFiles.filter { file in
                !isOnPlaylist(entity: file)
            }
            
            if !orphanedFiles.isEmpty {
                print("🧹 Found \(orphanedFiles.count) orphaned files. Cleaning up...")
                cleanupOrphanedFiles(from: orphanedFiles)
            }
        } catch {
            print("Failed to check for orphaned files: \(error)")
        }
    }
}
