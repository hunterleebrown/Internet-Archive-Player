//
//  PlaylistEntity+Extension.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 5/1/22.
//

import Foundation
import CoreData

extension PlaylistEntity {

    static func fetchRequest(playlistName: String) -> NSFetchRequest<PlaylistEntity> {
        let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "\(playlistName)")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        return request
    }

    static func fetchRequestAllPlaylists() -> NSFetchRequest<PlaylistEntity> {
        let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        return request
    }

    private var mutableSubItems: NSMutableOrderedSet {
        return mutableOrderedSetValue(forKey: "files")
    }

    public func moveObject(indexes: IndexSet, toIndex: Int) {
        mutableSubItems.moveObjects(at: indexes, to: toIndex)
    }

    static public func getAllPlaylists() -> [PlaylistEntity] {
        let listsFetchController =
        NSFetchedResultsController(fetchRequest:  PlaylistEntity.fetchRequestAllPlaylists(),
                                   managedObjectContext: PersistenceController.shared.container.viewContext,
                                   sectionNameKeyPath: nil,
                                   cacheName: nil)


        do {
            try listsFetchController.performFetch()
            if let playlists = listsFetchController.fetchedObjects {
                if playlists.count > 0 {
                    return playlists.filter{!$0.permanent}
                }
            }
        } catch {
            print("failed to fetch items!")
        }

        return []
    }

}
