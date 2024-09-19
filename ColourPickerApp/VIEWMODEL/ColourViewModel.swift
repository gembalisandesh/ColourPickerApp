//
//  ColourViewModel.swift
//  ColourPickerApp
//
//  Created by Equipp on 19/09/24.
//

import SwiftUI
import Firebase

class ColorViewModel: ObservableObject {
    @Published var colorCards: [ColorCard] = []
    @Published var isConnected: Bool = true
    @Published var showingErrorAlert: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let db = Firestore.firestore()
    
    func randomColor() -> Color {
        Color(red: .random(in: 0...1),
              green: .random(in: 0...1),
              blue: .random(in: 0...1))
    }
    
    func colorToHex(color: Color) -> String {
        let components = color.cgColor?.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
    
    func toggleNetworkStatus() {
        isConnected.toggle()
    }
    
    func loadColorsFromUserDefaults() {
        if let savedColors = userDefaults.object(forKey: "savedColors") as? Data {
            let decoder = JSONDecoder()
            if let loadedColors = try? decoder.decode([ColorCard].self, from: savedColors) {
                self.colorCards = loadedColors
            }
        }
    }
    
    func saveColorsToUserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(colorCards) {
            userDefaults.set(encoded, forKey: "savedColors")
        }
    }
    
    func syncWithFirebase(colorCard: ColorCard) {
        db.collection("colors").addDocument(data: [
            "hex": colorCard.hex,
            "timestamp": colorCard.timestamp
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                self.showingErrorAlert = true
            }
        }
    }
    
    func fetchColorsFromFirebase() {
        db.collection("colors").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                self.showingErrorAlert = true
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    if let hex = data["hex"] as? String,
                       let timestamp = data["timestamp"] as? String {
                        let color = self.hexToColor(hex: hex)
                        let colorCard = ColorCard(color: color, hex: hex, timestamp: timestamp)
                        if !self.colorCards.contains(where: { $0.id == colorCard.id }) {
                            self.colorCards.append(colorCard)
                        }
                    }
                }
                self.saveColorsToUserDefaults()
            }
        }
    }
    
    func updateColorInFirebase(_ colorCard: ColorCard) {
        db.collection("colors").whereField("timestamp", isEqualTo: colorCard.timestamp).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                self.showingErrorAlert = true
            } else {
                for document in querySnapshot!.documents {
                    document.reference.updateData([
                        "hex": colorCard.hex,
                        "timestamp": colorCard.timestamp
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                            self.showingErrorAlert = true
                        }
                    }
                }
            }
        }
    }
    
    func deleteColorFromFirebase(_ colorCard: ColorCard) {
        db.collection("colors").whereField("timestamp", isEqualTo: colorCard.timestamp).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                self.showingErrorAlert = true
            } else {
                for document in querySnapshot!.documents {
                    document.reference.delete() { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                            self.showingErrorAlert = true
                        }
                    }
                }
            }
        }
    }
    
    private func hexToColor(hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}
