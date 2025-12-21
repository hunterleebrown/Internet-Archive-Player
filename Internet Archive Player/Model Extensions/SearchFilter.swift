//
//  SearchFilter.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/20/24.
//

import Foundation
import SwiftUI
import UIKit

struct SearchFilter: Identifiable, Hashable, Codable {
    var name: String
    var identifier: String
    var iconUrl: URL?
    var uiImage: UIImage?
    var image: Image?
    var systemImageName: String? // Store the system image name for encoding
    
    // Use identifier as the unique id for Identifiable conformance
    var id: String { identifier }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func == (lhs: SearchFilter, rhs: SearchFilter) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    // MARK: - Codable conformance
    
    enum CodingKeys: String, CodingKey {
        case name
        case identifier
        case iconUrl
        case uiImageData
        case systemImageName
    }
    
    init(name: String, identifier: String, iconUrl: URL? = nil, uiImage: UIImage? = nil, image: Image? = nil, systemImageName: String? = nil) {
        self.name = name
        self.identifier = identifier
        self.iconUrl = iconUrl
        self.uiImage = uiImage
        self.image = image
        self.systemImageName = systemImageName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        identifier = try container.decode(String.self, forKey: .identifier)
        iconUrl = try container.decodeIfPresent(URL.self, forKey: .iconUrl)
        systemImageName = try container.decodeIfPresent(String.self, forKey: .systemImageName)
        
        // Decode UIImage from Data if present
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .uiImageData) {
            uiImage = UIImage(data: imageData)
        } else {
            uiImage = nil
        }
        
        // Reconstruct Image from system image name if present
        if let systemName = systemImageName {
            image = Image(systemName: systemName)
        } else {
            image = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(identifier, forKey: .identifier)
        try container.encodeIfPresent(iconUrl, forKey: .iconUrl)
        try container.encodeIfPresent(systemImageName, forKey: .systemImageName)
        
        // Encode UIImage as PNG Data if present
        if let uiImage = uiImage, let imageData = uiImage.pngData() {
            try container.encode(imageData, forKey: .uiImageData)
        }
    }
}
