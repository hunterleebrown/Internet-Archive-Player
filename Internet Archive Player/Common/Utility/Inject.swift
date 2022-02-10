//
//  Inject.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 2/8/22.
//

import Foundation

@propertyWrapper
struct Inject<T : Any> {

    private var service: T!

    public init() {}

    public var wrappedValue: T {
        get {
            if self.service == nil {
                return try! ServiceContainer.resolve(serviceType: T.self)
            }

            return service
        }
        set { service = newValue  }
    }

    init(wrappedValue initialValue: T) {
        self.wrappedValue = initialValue
    }
}
