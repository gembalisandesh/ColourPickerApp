//
//  ColourViewModel.swift
//  ColourPickerApp
//
//  Created by Equipp on 19/09/24.
//

import Foundation
import SwiftUI
import Firebase
import Network

class ColorViewModel: ObservableObject {
    @Published var colorCards: [ColorCard] = []
    @Published var isConnected: Bool = true
    @Published var showingErrorAlert: Bool = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var manualMode: Bool = false
    
    init() {
        setupNetworkMonitor()
        loadColorsFromUserDefaults()
        fetchColorsFromFirebase()
    }
   
    func toggleNetworkStatus() {
        manualMode.toggle()
        isConnected = !manualMode
        if isConnected {
            retrySyncForOfflineData()
        }
    }
    
    func randomColor() -> Color {
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        return Color(red: red, green: green, blue: blue)
    }
    
    func colorToHex(color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    func saveColorsToUserDefaults() {
        let colorData = colorCards.map { card -> [String: Any] in
            return [
                "hex": card.hex,
                "timestamp": card.timestamp,
                "red": UIColor(card.color).cgColor.components![0],
                "green": UIColor(card.color).cgColor.components![1],
                "blue": UIColor(card.color).cgColor.components![2]
            ]
        }
        
        UserDefaults.standard.set(colorData, forKey: "colorCards")
    }
    
    func loadColorsFromUserDefaults() {
        guard let storedColors = UserDefaults.standard.array(forKey: "colorCards") as? [[String: Any]] else { return }
        
        colorCards = storedColors.map { data in
            let red = data["red"] as! CGFloat
            let green = data["green"] as! CGFloat
            let blue = data["blue"] as! CGFloat
            let hex = data["hex"] as! String
            let timestamp = data["timestamp"] as! String
            return ColorCard(color: Color(red: red, green: green, blue: blue), hex: hex, timestamp: timestamp)
        }
    }
    
    func syncWithFirebase(colorCard: ColorCard) {
        guard isConnected else { return }
        
        let db = Firestore.firestore()
        db.collection("colors").addDocument(data: [
            "hex": colorCard.hex,
            "timestamp": colorCard.timestamp
        ]) { error in
            if let error = error {
                print("Error syncing color: \(error)")
                self.showingErrorAlert = true
            } else {
                print("Color synced successfully")
            }
        }
    }
    
    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if !self.manualMode {
                    self.isConnected = path.status == .satisfied
                    if self.isConnected {
                        self.retrySyncForOfflineData()
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func fetchColorsFromFirebase() {
        let db = Firestore.firestore()
        db.collection("colors").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }

    
    func retrySyncForOfflineData() {
        guard isConnected else { return }
        
        for card in colorCards {
            syncWithFirebase(colorCard: card)
        }
    }
}
