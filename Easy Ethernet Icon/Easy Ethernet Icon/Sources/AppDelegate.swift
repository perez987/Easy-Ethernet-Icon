import Cocoa
import SwiftUI

/// The AppDelegate class handles the core functionality of the menu bar application
/// It manages the status bar item (icon in the menu bar) and handles connection status updates
class AppDelegate: NSObject, NSApplicationDelegate {
    // Singleton instance of AppDelegate that can be accessed throughout the app
    private(set) static var instance: AppDelegate!

    // View that handles application settings
    private var settingsView = SettingsView()

    // Fixed size for the menu bar icon (20x20 pixels)
    private let fixedImageSize = 20

    // The actual menu bar item that shows in the system status bar
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: 20)

    // Instance of ApplicationMenu that handles menu creation and ethernet monitoring
    let menu = ApplicationMenu()

    /// Called when the application finishes launching
    func applicationDidFinishLaunching(_: Notification) {
        // Set up singleton instance
        AppDelegate.instance = self

        // Listen for changes in icon style from settings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateIcon),
            name: .iconStyleChanged,
            object: nil
        )

        // Start monitoring ethernet connection and update the status icon
        menu.startMonitoringEthernetStatus { status in
            DispatchQueue.main.async {
                self.updateStatusBarIcon(status: status)
            }
        }

        // Configure the status bar item
        setupStatusBarItem()
    }

    /// Sets up the initial status bar item configuration
    private func setupStatusBarItem() {
        statusBarItem.button?.imagePosition = .imageLeading
        statusBarItem.menu = menu.createMenu()
    }

    /// Updates the status bar icon when settings change
    @objc func updateIcon() {
        statusBarItem.button?.image = getConnectionImage(
            status: menu.currentConnectionStatus,
            setting: settingsView
        )
    }

    /// Updates the status bar icon with current connection status
    private func updateStatusBarIcon(status: ApplicationMenu.ConnectionStatus) {
        statusBarItem.button?.imagePosition = .imageOnly
        statusBarItem.button?.imageScaling = .scaleNone
        statusBarItem.button?.image = getConnectionImage(
            status: status,
            setting: settingsView
        )
        statusBarItem.button?.image?.size = NSSize(
            width: fixedImageSize,
            height: fixedImageSize
        )
        statusBarItem.button?.image?.isTemplate = true
    }

    /// Returns the appropriate icon image based on connection status and user settings
    func getConnectionImage(
        status: ApplicationMenu.ConnectionStatus,
        setting: SettingsView
    ) -> NSImage {
        // Choose icon based on selected style (macOS or default/Windows style)
        let imageName = setting.selectedOption == "macOS"
            ? "macOS_Ethernet\(status == .connected ? "Connected" : "Disconnected")"
            : "Default_Ethernet\(status == .connected ? "Connected" : "Disconnected")"

        let image = NSImage(named: imageName) ?? NSImage()
        image.size = NSSize(width: fixedImageSize, height: fixedImageSize)
        return image
    }

    /// Triggers a refresh of the status icon
    func updateStatusIcon() {
        menu.refreshCurrentStatus()
        updateStatusBarIcon(status: menu.currentConnectionStatus)
    }
}
