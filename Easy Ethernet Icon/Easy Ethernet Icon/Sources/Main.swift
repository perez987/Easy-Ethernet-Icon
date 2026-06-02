import Cocoa
import Network
import SwiftUI

/// Custom notification for icon style changes
extension Notification.Name {
    static let iconStyleChanged = Notification.Name("iconStyleChanged")
}

/// Main application structure
@main
struct Ethernet_Menu_IconApp: App {
    // Links the AppDelegate to the SwiftUI application lifecycle
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Creates the settings scene for the application
        Settings {
            SettingsView()
        }
    }
}
