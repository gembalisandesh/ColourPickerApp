//
//  Model.swift
//  ColourPickerApp
//
//  Created by Equipp on 19/09/24.
//

import Foundation
import SwiftUI

struct ColorCard: Identifiable {
    var id = UUID()
    var color: Color
    var hex: String
    var timestamp: String
}
