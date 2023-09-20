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
