//
//  Model.swift
//  ColourPickerApp
//
//  Created by Equipp on 19/09/24.
//

import Foundation
import SwiftUI

struct ColorCard: Identifiable, Codable {
    var id = UUID()
    var color: Color
    var hex: String
    var timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, hex, timestamp
        case colorComponents
    }
    
    init(id: UUID = UUID(), color: Color, hex: String, timestamp: String) {
        self.id = id
        self.color = color
        self.hex = hex
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        hex = try container.decode(String.self, forKey: .hex)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        
        let components = try container.decode([CGFloat].self, forKey: .colorComponents)
        color = Color(.sRGB, red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(hex, forKey: .hex)
        try container.encode(timestamp, forKey: .timestamp)
        
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        try container.encode(components, forKey: .colorComponents)
    }
}
