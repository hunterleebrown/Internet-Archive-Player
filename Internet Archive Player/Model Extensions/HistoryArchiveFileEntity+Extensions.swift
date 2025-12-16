//
//  HistoryArchiveFileEntity+Extensions.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/16/24.
//

import Foundation
import CoreData

extension HistoryArchiveFileEntity: ArchiveFileDisplayable {
    
    // All display properties come from ArchiveFileDisplayable protocol
    
}

extension HistoryArchiveFileEntity {
    
    /// Fetch request for history items sorted by most recently played
    static var historyFetchRequest: NSFetchRequest<HistoryArchiveFileEntity> {
        let request: NSFetchRequest<HistoryArchiveFileEntity> = HistoryArchiveFileEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "playedAt", ascending: false)]
        return request
    }
    
    /// Fetch request for most played items
    static var mostPlayedFetchRequest: NSFetchRequest<HistoryArchiveFileEntity> {
        let request: NSFetchRequest<HistoryArchiveFileEntity> = HistoryArchiveFileEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "playCount", ascending: false)]
        return request
    }
    
}
