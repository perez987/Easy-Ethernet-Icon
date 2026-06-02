import Foundation
import QuartzCore

class NetworkMonitor {
    private var monitorTimer: DispatchSourceTimer?
    private var lastDataReceived: UInt64 = 0
    private var lastDataSent: UInt64 = 0
    private var lastUpdateTime: TimeInterval = 0
    private var lastInterfaceName: String?

    var onSpeedUpdate: ((Double, Double) -> Void)?

    func startMonitoring() {
        stopMonitoring()
        let storedRefreshInterval = UserDefaults.standard.double(forKey: "refreshInterval")
        let refreshInterval = storedRefreshInterval > 0 ? storedRefreshInterval : 1.0

        monitorTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        monitorTimer?.schedule(deadline: .now(), repeating: refreshInterval)
        monitorTimer?.setEventHandler { [weak self] in
            self?.updateNetworkUsage()
        }
        monitorTimer?.resume()
    }

    func stopMonitoring() {
        monitorTimer?.cancel()
        monitorTimer = nil
        lastDataReceived = 0
        lastDataSent = 0
        lastUpdateTime = 0
        lastInterfaceName = nil
    }

    private func updateNetworkUsage() {
        guard let snapshot = MonitoredNetworkService.currentSnapshot() else {
            stopTrackingCurrentInterface()
            publishSpeed(download: 0, upload: 0)
            return
        }

        if snapshot.bsdName != lastInterfaceName {
            lastInterfaceName = snapshot.bsdName
            lastDataReceived = snapshot.received
            lastDataSent = snapshot.sent
            lastUpdateTime = CACurrentMediaTime()
            publishSpeed(download: 0, upload: 0)
            return
        }

        let currentTime = CACurrentMediaTime()
        guard lastUpdateTime > 0 else {
            lastDataReceived = snapshot.received
            lastDataSent = snapshot.sent
            lastUpdateTime = currentTime
            publishSpeed(download: 0, upload: 0)
            return
        }

        let timeInterval = currentTime - lastUpdateTime
        guard timeInterval > 0 else { return }

        let useKilobytes = UserDefaults.standard.string(forKey: "speedUnit") == "KB/s"
        let divisor = useKilobytes ? 1024.0 : 1_048_576.0

        var downloadSpeed: Double
        var uploadSpeed: Double

        if snapshot.received >= lastDataReceived {
            let bytesReceived = Double(snapshot.received - lastDataReceived)
            downloadSpeed = (bytesReceived / timeInterval) / divisor
        } else {
            let bytesReceived = Double(UInt64.max - lastDataReceived + snapshot.received)
            downloadSpeed = (bytesReceived / timeInterval) / divisor
        }

        if snapshot.sent >= lastDataSent {
            let bytesSent = Double(snapshot.sent - lastDataSent)
            uploadSpeed = (bytesSent / timeInterval) / divisor
        } else {
            let bytesSent = Double(UInt64.max - lastDataSent + snapshot.sent)
            uploadSpeed = (bytesSent / timeInterval) / divisor
        }

        lastDataReceived = snapshot.received
        lastDataSent = snapshot.sent
        lastUpdateTime = currentTime

        publishSpeed(download: downloadSpeed, upload: uploadSpeed)
    }

    private func publishSpeed(download: Double, upload: Double) {
        DispatchQueue.main.async {
            self.onSpeedUpdate?(download, upload)
        }
    }

    private func stopTrackingCurrentInterface() {
        lastDataReceived = 0
        lastDataSent = 0
        lastUpdateTime = 0
        lastInterfaceName = nil
    }
}
