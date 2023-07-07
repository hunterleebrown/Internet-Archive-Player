//
//  PlaylistEntity+Extension.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 5/1/22.
//

import Foundation
import CoreData

extension PlaylistEntity {

    static var playlistFetchRequest: NSFetchRequest<PlaylistEntity> {
      let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
      request.predicate = NSPredicate(format: "name == %@", "main")
      request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

      return request
    }

    static var favoritesFetchRequest: NSFetchRequest<PlaylistEntity> {
      let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
      request.predicate = NSPredicate(format: "name == %@", "favorites")
      request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

      return request
    }

    private var mutableSubItems: NSMutableOrderedSet {
        return mutableOrderedSetValue(forKey: "files")
    }

    public func moveObject(indexes: IndexSet, toIndex: Int) {
        mutableSubItems.moveObjects(at: indexes, to: toIndex)
    }

}
