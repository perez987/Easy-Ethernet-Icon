import Cocoa
import SwiftUI

/// Manages the application's menu and monitors ethernet connection status
class ApplicationMenu: NSObject, NSWindowDelegate {
    private let statusPollingInterval = 1.0

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
    private var statusMonitorTimer: DispatchSourceTimer?
    private var statusUpdateHandler: ((ConnectionStatus) -> Void)?
    private(set) var currentConnectionStatus: ConnectionStatus = .disconnected
    private(set) var currentMonitoredServiceName = MonitoredNetworkService.configuredServiceName
    private(set) var isMonitoredServiceResolved = false
    private var lastMonitoredServiceName: String?

    override init() {
        super.init()
        setupMenuItems()
        setupSpeedMonitoring()

        // Observe settings changes that affect the monitored service or displayed speed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    private func setupSpeedMonitoring() {
        // Setup speed monitoring callback
        networkMonitor.onSpeedUpdate = { [weak self] download, upload in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if !self.isMonitoredServiceResolved {
                    self.speedStatusItem.title = "Speed: -"
                    return
                }

                let unit = UserDefaults.standard.string(forKey: "speedUnit") ?? "MB/s"
                let speedText = String(format: "Speed: %.1f %@ ↓ | %.1f %@ ↑", download, unit, upload, unit)
                self.speedStatusItem.title = speedText
            }
        }

        // Start monitoring only if enabled in settings
        updateSpeedMonitoring()
    }

    @objc private func handleSettingsChange() {
        updateSpeedMonitoring()
        refreshEthernetStatus()
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
        statusUpdateHandler = statusUpdate

        if statusMonitorTimer == nil {
            let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
            // Keep status polling responsive even when the user chooses a slower speed refresh interval.
            timer.schedule(deadline: .now(), repeating: statusPollingInterval)
            timer.setEventHandler { [weak self] in
                self?.refreshEthernetStatus()
            }
            statusMonitorTimer = timer
            timer.resume()
        }

        refreshEthernetStatus()
    }

    private func refreshEthernetStatus() {
        let serviceName = MonitoredNetworkService.configuredServiceName
        let snapshot = MonitoredNetworkService.currentSnapshot(for: serviceName)
        let isResolved = snapshot != nil
        let status: ConnectionStatus = snapshot?.isConnected == true
            ? .connected
            : .disconnected

        let statusChanged = status != currentConnectionStatus
        let serviceChanged = serviceName != lastMonitoredServiceName
        let resolutionChanged = isResolved != isMonitoredServiceResolved

        currentConnectionStatus = status
        currentMonitoredServiceName = serviceName
        isMonitoredServiceResolved = isResolved
        lastMonitoredServiceName = serviceName

        guard statusChanged || serviceChanged || resolutionChanged else { return }

        statusUpdateHandler?(status)

        DispatchQueue.main.async {
            self.updateStatusMenuItem(
                serviceName: serviceName,
                status: status,
                isResolved: isResolved
            )
        }
    }

    private func updateStatusMenuItem(
        serviceName: String,
        status: ConnectionStatus,
        isResolved: Bool
    ) {
        if isResolved {
            ethernetStatusItem.title = "\(serviceName): \(status == .connected ? "Connected" : "Disconnected")"
        } else {
            ethernetStatusItem.title = "\(serviceName): Not Found"
        }
    }

    func stopMonitoring() {
        statusMonitorTimer?.cancel()
        statusMonitorTimer = nil
        networkMonitor.stopMonitoring()
    }

    func refreshCurrentStatus() {
        refreshEthernetStatus()
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
