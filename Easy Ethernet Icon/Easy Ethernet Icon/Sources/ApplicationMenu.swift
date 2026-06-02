import Cocoa
import Network
import SwiftUI

/// Manages the application's menu and monitors ethernet connection status
class ApplicationMenu: NSObject, NSWindowDelegate {
    // Main menu instance
    let menu = NSMenu()

    /// Represents the possible states of ethernet connection
    enum ConnectionStatus {
        case connected
        case disconnected
    }

    // Menu items
    let ethernetStatusItem = NSMenuItem(
        title: "Checking Ethernet Status...",
        action: nil,
        keyEquivalent: ""
    )
    let speedStatusItem = NSMenuItem(
        title: "Speed: -",
        action: nil,
        keyEquivalent: ""
    )
    let quitApplicationItem = NSMenuItem(
        title: "Quit Application",
        action: #selector(quitApplication),
        keyEquivalent: "q"
    )
    let networkSettingsItem = NSMenuItem(
        title: "Open Network Settings",
        action: #selector(openNetworkSettings),
        keyEquivalent: "n"
    )
    let settingsItem = NSMenuItem(
        title: "Settings",
        action: #selector(openSettings),
        keyEquivalent: "s"
    )

    // Settings window reference
    var settingsPanel: NSPanel?

    // Reference to NetworkMonitor
    private let networkMonitor = NetworkMonitor()

    override init() {
        super.init()
        setupMenuItems()
        setupSpeedMonitoring()

        // Observe changes to showConnectionSpeed setting
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSpeedSettingChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    private func setupSpeedMonitoring() {
        // Setup speed monitoring callback
        networkMonitor.onSpeedUpdate = { [weak self] download, upload in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let unit = UserDefaults.standard.string(forKey: "speedUnit") ?? "MB/s"
                let speedText = String(format: "Speed: %.1f %@ ↓ | %.1f %@ ↑", download, unit, upload, unit)
                self.speedStatusItem.title = speedText
            }
        }

        // Start monitoring only if enabled in settings
        updateSpeedMonitoring()
    }

    @objc private func handleSpeedSettingChange() {
        updateSpeedMonitoring()
    }

    private func updateSpeedMonitoring() {
        let showSpeed = UserDefaults.standard.bool(forKey: "showConnectionSpeed")

        if showSpeed {
            networkMonitor.startMonitoring()
        } else {
            networkMonitor.stopMonitoring()
            DispatchQueue.main.async {
                self.speedStatusItem.title = "Speed: -"
            }
        }
    }

    /// Sets up menu item targets
    private func setupMenuItems() {
        quitApplicationItem.target = self
        networkSettingsItem.target = self
        settingsItem.target = self
    }

    /// Creates and returns the configured menu
    func createMenu() -> NSMenu {
        menu.removeAllItems() // Clean up before adding items

        menu.addItem(ethernetStatusItem)
        menu.addItem(speedStatusItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(networkSettingsItem)
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitApplicationItem)

        return menu
    }

    /// Starts monitoring ethernet connection status
    func startMonitoringEthernetStatus(statusUpdate: @escaping (ConnectionStatus) -> Void) {
        let monitor = NWPathMonitor(requiredInterfaceType: .wiredEthernet)

        monitor.pathUpdateHandler = { path in
            let status: ConnectionStatus = path.status == .satisfied
                ? .connected
                : .disconnected

            statusUpdate(status)

            DispatchQueue.main.async {
                self.updateStatusMenuItem(status: status)
            }
        }

        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    private func updateStatusMenuItem(status: ConnectionStatus) {
        ethernetStatusItem.title = "Ethernet: \(status == .connected ? "Connected" : "Disconnected")"
    }

    func stopMonitoring() {
        networkMonitor.stopMonitoring()
    }

    /// Quits the application
    @objc func quitApplication() {
        stopMonitoring()
        NSApplication.shared.terminate(self)
    }

    /// Opens the settings panel
    @objc func openSettings() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        if settingsPanel == nil {
            createSettingsPanel()
        }

        settingsPanel?.makeKeyAndOrderFront(nil)
        settingsPanel?.orderFrontRegardless()
    }

    /// Creates the settings panel
    private func createSettingsPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        panel.center()
        panel.setFrameAutosaveName("Settings")
        panel.contentView = NSHostingView(rootView: SettingsView())
        panel.delegate = self
        panel.isFloatingPanel = true
        panel.level = .floating

        settingsPanel = panel
    }

    /// Opens system network settings
    @objc func openNetworkSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.network") {
            NSWorkspace.shared.open(url)
        }
    }
}
