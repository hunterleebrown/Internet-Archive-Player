//
//  IAReachability.swift
//  IA Music
//
//  Created by Hunter Lee Brown on 5/24/16.
//  Copyright © 2016 Hunter Lee Brown. All rights reserved.
//

import Foundation
import Network

@MainActor
open class IAReachability: ObservableObject {
    
    // Singleton pattern for shared monitoring
    static let shared = IAReachability()
    
    @Published private(set) var isConnected = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "IAReachability")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    // Legacy synchronous API (kept for compatibility)
    class func isConnectedToNetwork() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        
        // Use a class wrapper to avoid capturing a mutable variable
        final class ConnectionState: @unchecked Sendable {
            var isConnected = false
            let lock = NSLock()
            
            func setConnected(_ connected: Bool) {
                lock.lock()
                defer { lock.unlock() }
                isConnected = connected
            }
            
            func getConnected() -> Bool {
                lock.lock()
                defer { lock.unlock() }
                return isConnected
            }
        }
        
        let state = ConnectionState()
        
        monitor.pathUpdateHandler = { path in
            state.setConnected(path.status == .satisfied)
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "IAReachability.OneTime")
        monitor.start(queue: queue)
        
        // Wait for the first path update with a timeout
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return state.getConnected()
    }
    
}
