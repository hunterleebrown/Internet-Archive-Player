//
//  ServiceContainer.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/8/22.
//

import Foundation
import SwiftUI

struct ServiceContainer {

    enum ContainerError: Error {
        case serviceNotFound
    }


    public static var iaPlayer = IAPlayer()

    static func resolve<T : Any>(serviceType: T.Type) throws -> T {

        if serviceType == IAPlayer.self {
            return (iaPlayer as! T)
        }

//        if serviceType == TrackingContext.self {
//            return (trackingService as! T)
//        }
//        if serviceType == UdsServiceProtocol.self {
//            return (uds as! T)
//        }
//        if serviceType == AppEntryService.self {
//            return (appEntryService as! T)
//        }
//        if serviceType == UpdateEnforcer.self {
//            return (updateEnforcer as! T)
//        }
//        if serviceType == NewslettersProvider.self {
//            return (newsletterProvider as! T)
//        }
//        if serviceType == Messages.self {
//            return (messages as! T)
//        }
//        if serviceType == MessagingManager.self {
//            return (messagingManager as! T)
//        }
//        if serviceType == APIClient.self {
//            return (apiClient as! T)
//        }
//        if serviceType == FeatureFlagConfiguration.self {
//            return (featureFlagConfiguration as! T)
//        }

        throw ContainerError.serviceNotFound
    }
}
