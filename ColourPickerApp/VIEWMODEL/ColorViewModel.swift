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
    @Published var errorMessage: String? = nil 
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var manualMode: Bool = false
    private var offlineTasks: [OfflineTask] = []

    init() {
        setupNetworkMonitor()
        loadColorsFromUserDefaults()
        loadOfflineTasks()
        fetchColorsFromFirebase()
    }

    func toggleNetworkStatus() {
        manualMode.toggle()
        isConnected = !manualMode
        if isConnected {
            print("Device is online. Attempting to sync offline data.")
            retrySyncForOfflineData()
        } else {
            print("Device is offline.")
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
                "red": UIColor(card.color).cgColor.components?[0] ?? 0,
                "green": UIColor(card.color).cgColor.components?[1] ?? 0,
                "blue": UIColor(card.color).cgColor.components?[2] ?? 0
            ]
        }
        
        UserDefaults.standard.set(colorData, forKey: "colorCards")
        print("Colors saved to UserDefaults: \(colorCards.map { $0.hex })")
    }

    func loadColorsFromUserDefaults() {
        guard let storedColors = UserDefaults.standard.array(forKey: "colorCards") as? [[String: Any]] else { return }
        
        colorCards = storedColors.compactMap { data in
            guard let red = data["red"] as? CGFloat,
                  let green = data["green"] as? CGFloat,
                  let blue = data["blue"] as? CGFloat,
                  let hex = data["hex"] as? String,
                  let timestamp = data["timestamp"] as? String else {
                return nil
            }
            return ColorCard(color: Color(red: red, green: green, blue: blue), hex: hex, timestamp: timestamp)
        }
        print("Loaded colors from UserDefaults: \(colorCards.map { $0.hex })")
    }

    func addColor(_ colorCard: ColorCard) {
        colorCards.append(colorCard)
        saveColorsToUserDefaults()
        
        if isConnected {
            syncWithFirebase(colorCard: colorCard)
        } else {
            offlineTasks.append(.addColor(colorCard))
            saveOfflineTasks()
        }
    }

    func deleteColorCard(_ card: ColorCard) {
        if let index = colorCards.firstIndex(where: { $0.hex == card.hex }) {
            colorCards.remove(at: index)
            print("Color \(card.hex) deleted locally.")
        }
        
        saveColorsToUserDefaults()
        
        if isConnected {
            deleteColorFromFirebase(card) { error in
                if let error = error {
                    self.handleError(error)
                } else {
                    print("Color \(card.hex) deleted from Firebase.")
                }
            }
        } else {
            offlineTasks.append(.deleteColor(card.hex))
            saveOfflineTasks()
            print("Offline - Will retry deleting color \(card.hex) from Firebase later.")
        }
    }

    func deleteAllColors() {
        colorCards.removeAll()
        saveColorsToUserDefaults()
        
        if isConnected {
            deleteAllColorsFromFirebase()
        } else {
            offlineTasks.append(.deleteAllColors)
            saveOfflineTasks()
            print("Offline - Will retry deleting all colors from Firebase later.")
        }
    }

    func syncWithFirebase(colorCard: ColorCard) {
        let db = Firestore.firestore()
        db.collection("colors").addDocument(data: [
            "hex": colorCard.hex,
            "timestamp": colorCard.timestamp
        ]) { error in
            if let error = error {
                self.handleError(error)
            } else {
                print("Color \(colorCard.hex) synced successfully")
            }
        }
    }

    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if !self.manualMode {
                    self.isConnected = path.status == .satisfied
                    if self.isConnected {
                        print("Network status: Online")
                        self.retrySyncForOfflineData()
                    } else {
                        print("Network status: Offline")
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
                self.handleError(error)
            } else {
                let colors = querySnapshot?.documents.map { $0.data() } ?? []
                print("Fetched colors from Firebase: \(colors)")
            }
        }
    }

    private func deleteColorFromFirebase(_ card: ColorCard, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("colors")
            .whereField("hex", isEqualTo: card.hex)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    self.handleError(error)
                    completion(error)
                } else {
                    let deleteGroup = DispatchGroup()
                    
                    for document in querySnapshot!.documents {
                        deleteGroup.enter()
                        document.reference.delete { error in
                            if let error = error {
                                print("Error deleting color \(card.hex): \(error.localizedDescription)")
                                self.showingErrorAlert = true
                                self.errorMessage = error.localizedDescription
                                completion(error)
                            } else {
                                print("Color \(card.hex) deleted from Firebase.")
                                completion(nil)
                            }
                            deleteGroup.leave()
                        }
                    }
                    
                    deleteGroup.notify(queue: .main) {
                        completion(nil)
                    }
                }
            }
    }

    func deleteAllColorsFromFirebase() {
        let db = Firestore.firestore()
        
        db.collection("colors").getDocuments { querySnapshot, error in
            if let error = error {
                self.handleError(error)
            } else {
                let deleteGroup = DispatchGroup()
                
                for document in querySnapshot!.documents {
                    deleteGroup.enter()
                    document.reference.delete { error in
                        if let error = error {
                            print("Error deleting color document \(document.documentID): \(error.localizedDescription)")
                            self.showingErrorAlert = true
                            self.errorMessage = error.localizedDescription
                        } else {
                            print("Deleted color document \(document.documentID) from Firebase.")
                        }
                        deleteGroup.leave()
                    }
                }
                
                deleteGroup.notify(queue: .main) {
                    print("All color documents deletion process completed.")
                }
            }
        }
    }

    func deleteAllColorsFromUserDefaults() {
        colorCards.removeAll()
        UserDefaults.standard.removeObject(forKey: "colorCards")
        print("All colors deleted from UserDefaults.")
    }

    private func retrySyncForOfflineData() {
        guard isConnected else { return }
        
        let tasks = offlineTasks
        offlineTasks.removeAll()
        saveOfflineTasks()
        
        for task in tasks {
            switch task {
            case .addColor(let colorCard):
                syncWithFirebase(colorCard: colorCard)
            case .deleteColor(let hex):
                deleteColorFromFirebaseByHex(hex)
            case .deleteAllColors:
                deleteAllColorsFromFirebase()
            }
        }
    }

    private func deleteColorFromFirebaseByHex(_ hex: String) {
        let db = Firestore.firestore()
        
        db.collection("colors")
            .whereField("hex", isEqualTo: hex)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    self.handleError(error)
                } else if let documents = querySnapshot?.documents, !documents.isEmpty {
                    let deleteGroup = DispatchGroup()
                    
                    for document in documents {
                        deleteGroup.enter()
                        document.reference.delete { error in
                            if let error = error {
                                print("Error deleting color \(hex): \(error.localizedDescription)")
                                self.showingErrorAlert = true
                                self.errorMessage = error.localizedDescription
                            } else {
                                print("Color \(hex) deleted from Firebase.")
                            }
                            deleteGroup.leave()
                        }
                    }
                    
                    deleteGroup.notify(queue: .main) {
                        print("Deletion of color \(hex) completed.")
                    }
                } else {
                    print("No document found for color \(hex).")
                }
            }
    }

    private func handleError(_ error: Error) {
        showingErrorAlert = true
        errorMessage = error.localizedDescription
    }

    private func saveOfflineTasks() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(offlineTasks) {
            UserDefaults.standard.set(encoded, forKey: "offlineTasks")
            print("Saved offline tasks to UserDefaults.")
        }
    }

    private func loadOfflineTasks() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "offlineTasks"),
           let tasks = try? decoder.decode([OfflineTask].self, from: data) {
            offlineTasks = tasks
            print("Loaded offline tasks from UserDefaults.")
        }
    }
}
