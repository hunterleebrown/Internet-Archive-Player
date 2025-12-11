//
//  IAReachability.swift
//  IA Music
//
//  Created by Hunter Lee Brown on 5/24/16.
//  Copyright © 2016 Hunter Lee Brown. All rights reserved.
//

import Foundation
import Network

open class IAReachability {
    
    class func isConnectedToNetwork() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false
        
        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "IAReachability")
        monitor.start(queue: queue)
        
        // Wait for the first path update with a timeout
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return isConnected
    }
    
}
