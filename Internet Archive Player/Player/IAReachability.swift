//
//  IAReachability.swift
//  IA Music
//
//  Created by Hunter Lee Brown on 5/24/16.
//  Copyright © 2016 Hunter Lee Brown. All rights reserved.
//

import Foundation
import SystemConfiguration


open class IAReachability {
    
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let nodename = ("archive.org" as NSString).utf8String

        let defaultRouteReachability = SCNetworkReachabilityCreateWithName(nil, nodename!)
            
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
}
