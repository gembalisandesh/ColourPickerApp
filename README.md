# ColourPickerApp

ColourPickerApp is a SwiftUI-based iOS application that allows users to generate, save, and manage color cards. It features offline support, Firebase integration for cloud synchronization, and a user-friendly interface.

## Features

- Generate random color cards
- Save color cards locally and sync with Firebase
- View color cards with hex codes and timestamps
- Delete individual color cards or all colors at once
- Offline support with automatic syncing when back online
- Network status monitoring with manual online/offline toggle
- Error handling with user-friendly alert notifications
- Deletion of specific colors or all colors at once, both locally and from Firebase

## Screenshots

<img src="https://github.com/user-attachments/assets/2b774a58-c957-47e1-be92-dfb434e70f42" width="200" /> 
<img src="https://github.com/user-attachments/assets/84b899d9-945a-478a-86d1-cd369f828895" width="200" /> 
<img src="https://github.com/user-attachments/assets/9103819f-b614-4633-80e6-0a86434e89ce" width="200" />
## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+
- CocoaPods (for Firebase installation)

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/gembalisandesh/ColourPickerApp.git
   ```

2. Navigate to the project directory:
   ```
   cd ColourPickerApp
   ```

3. Install Firebase using CocoaPods:
   ```
   pod init
   ```
   Add the following lines to your Podfile:
   ```
   pod 'Firebase/Firestore'
   pod 'Firebase/Analytics'
   ```
   Then run:
   ```
   pod install
   ```

4. Open the `.xcworkspace` file in Xcode.

5. Set up a Firebase project and add your `GoogleService-Info.plist` file to the Xcode project.

6. Build and run the project.

## Usage

1. Launch the app on your iOS device or simulator.
2. Tap the "Generate Color" button to create a new random color card.
3. View your color cards in the main list, showing the color, hex code, and timestamp.
4. To delete a specific color:
   - Tap the delete button (trash icon) on the color card
5. To delete all colors:
   - Use the "Delete All Colors" button at the bottom of the screen
6. Toggle the network status switch to manually control online/offline behavior:
   - When switched to offline, the app will store changes locally
   - When switched back to online, the app will attempt to sync offline changes with Firebase

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture:

- `ColorCard`: Model representing a color card.
- `ColorViewModel`: ViewModel handling business logic and data management.
- `ContentView`: Main view of the application.
- `ColorCardView`: Subview for displaying individual color cards.

## Offline Support

The app uses `UserDefaults` for local storage and `NWPathMonitor` for network status monitoring. When offline, the app continues to function, storing data locally. Upon regaining network connection, it automatically syncs with Firebase.

The app also provides a manual toggle for simulating offline/online behavior, useful for testing and demonstrations.

## Firebase Integration

The app uses Firebase Firestore for cloud storage and synchronization of color cards. Ensure you have set up a Firebase project and added the necessary configuration files to your Xcode project.

## Error Handling

The app includes robust error handling:
- Network-related errors are caught and displayed to the user
- Firebase operation errors (e.g., during sync or deletion) are handled gracefully
- User-friendly alert notifications are shown for any errors, ensuring the user is always informed about the app's status

## Deletion Features

- Individual Color Deletion: Users can delete a specific color card by tapping the delete button (trash icon) on the card. A confirmation dialog appears before the deletion is performed.
- Bulk Deletion: The "Delete All Colors" feature allows users to remove all color cards at once. A confirmation dialog appears before proceeding with the deletion.

Both deletion operations remove colors from local storage and Firebase (when online).

## Contribution

Contributions are welcome! Please feel free to submit a Pull Request.

