//
//  AppDelegate.swift
//  ColourPickerApp
//
//  Created by Equipp on 19/09/24.
//

import Firebase
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }

}
