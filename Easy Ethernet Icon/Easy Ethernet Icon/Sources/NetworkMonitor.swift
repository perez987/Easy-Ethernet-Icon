import Foundation
import QuartzCore

class NetworkMonitor {
    private var monitorTimer: DispatchSourceTimer?
    private var lastDataReceived: UInt64 = 0
    private var lastDataSent: UInt64 = 0
    private var lastUpdateTime: TimeInterval = 0

    var onSpeedUpdate: ((Double, Double) -> Void)?

    func startMonitoring() {
        let refreshInterval = UserDefaults.standard.double(forKey: "refreshInterval")

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
    }

    private func updateNetworkUsage() {
        guard let counters = getNetworkCounters() else { return }

        let currentTime = CACurrentMediaTime()
        let timeInterval = currentTime - lastUpdateTime

        let useKilobytes = UserDefaults.standard.string(forKey: "speedUnit") == "KB/s"
        let divisor = useKilobytes ? 1024.0 : 1_048_576.0

        var downloadSpeed: Double
        var uploadSpeed: Double

        if counters.received >= lastDataReceived {
            let bytesReceived = Double(counters.received - lastDataReceived)
            downloadSpeed = (bytesReceived / timeInterval) / divisor
        } else {
            let bytesReceived = Double(UInt64.max - lastDataReceived + counters.received)
            downloadSpeed = (bytesReceived / timeInterval) / divisor
        }

        if counters.sent >= lastDataSent {
            let bytesSent = Double(counters.sent - lastDataSent)
            uploadSpeed = (bytesSent / timeInterval) / divisor
        } else {
            let bytesSent = Double(UInt64.max - lastDataSent + counters.sent)
            uploadSpeed = (bytesSent / timeInterval) / divisor
        }

        lastDataReceived = counters.received
        lastDataSent = counters.sent
        lastUpdateTime = currentTime

        DispatchQueue.main.async {
            self.onSpeedUpdate?(downloadSpeed, uploadSpeed)
        }
    }

    private func getNetworkCounters() -> (received: UInt64, sent: UInt64)? {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddrs) == 0, let firstAddr = ifaddrs else { return nil }
        defer { freeifaddrs(ifaddrs) }

        var dataReceived: UInt64 = 0
        var dataSent: UInt64 = 0

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ifptr.pointee.ifa_flags)
            let isUp = (flags & (IFF_UP | IFF_RUNNING)) == (IFF_UP | IFF_RUNNING)
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            if !isUp || isLoopback { continue }

            if let data = ifptr.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                dataReceived += UInt64(data.pointee.ifi_ibytes)
                dataSent += UInt64(data.pointee.ifi_obytes)
            }
        }

        return (dataReceived, dataSent)
    }
}
