import Foundation
import SystemConfiguration

enum MonitoredNetworkService {
    static let userDefaultsKey = "monitoredNetworkServiceName"
    static let selectableServiceNames = ["Ethernet", "Ethernet 2"]
    static let defaultServiceName = "Ethernet"
    // Used only if the app bundle identifier is unavailable while opening SystemConfiguration preferences.
    private static let fallbackPreferencesIdentifier = "Easy Ethernet Icon"
    // Some macOS services wrap the real BSD device in a small stack of virtual interfaces.
    // Cap recursion so a malformed interface graph cannot recurse indefinitely.
    private static let maxInterfaceNestingDepth = 10

    struct InterfaceSnapshot {
        let bsdName: String
        let isConnected: Bool
        let received: UInt64
        let sent: UInt64
    }

    static var configuredServiceName: String {
        normalizedServiceName(UserDefaults.standard.string(forKey: userDefaultsKey))
    }

    static func currentSnapshot(for serviceName: String = configuredServiceName) -> InterfaceSnapshot? {
        guard let bsdName = bsdInterfaceName(for: normalizedServiceName(serviceName)) else { return nil }
        return interfaceSnapshot(forBSDName: bsdName)
    }

    static func isServiceAvailable(_ serviceName: String) -> Bool {
        guard selectableServiceNames.contains(serviceName) else { return false }
        return bsdInterfaceName(for: serviceName) != nil
    }

    static func normalizedServiceName(_ serviceName: String?) -> String {
        let trimmedValue = serviceName?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmedValue, selectableServiceNames.contains(trimmedValue) {
            return trimmedValue
        }

        return defaultServiceName
    }

    private static func bsdInterfaceName(for serviceName: String) -> String? {
        guard
            let preferences = SCPreferencesCreate(
                nil,
                (Bundle.main.bundleIdentifier ?? fallbackPreferencesIdentifier) as CFString,
                nil
            ),
            let services = SCNetworkServiceCopyAll(preferences) as? [SCNetworkService]
        else {
            return nil
        }

        for service in services {
            guard let currentServiceName = SCNetworkServiceGetName(service) as String? else { continue }

            if currentServiceName == serviceName,
               let interface = SCNetworkServiceGetInterface(service),
               let bsdName = bsdName(for: interface) {
                return bsdName
            }
        }

        return nil
    }

    private static func bsdName(for interface: SCNetworkInterface, depth: Int = 0) -> String? {
        guard depth < maxInterfaceNestingDepth else { return nil }

        if let bsdName = SCNetworkInterfaceGetBSDName(interface) as String? {
            return bsdName
        }

        guard let nestedInterface = SCNetworkInterfaceGetInterface(interface) else {
            return nil
        }

        return bsdName(for: nestedInterface, depth: depth + 1)
    }

    private static func interfaceSnapshot(forBSDName bsdName: String) -> InterfaceSnapshot? {
        var ifaddrsPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrsPointer) == 0, let firstAddress = ifaddrsPointer else { return nil }
        defer { freeifaddrs(ifaddrsPointer) }

        for pointer in sequence(first: firstAddress, next: { $0.pointee.ifa_next }) {
            guard let interfaceName = pointer.pointee.ifa_name else { continue }
            guard String(cString: interfaceName) == bsdName else { continue }
            guard let address = pointer.pointee.ifa_addr else { continue }
            guard address.pointee.sa_family == UInt8(AF_LINK) else { continue }

            let flags = Int32(pointer.pointee.ifa_flags)
            let isConnected = (flags & (IFF_UP | IFF_RUNNING)) == (IFF_UP | IFF_RUNNING)
            let data = pointer.pointee.ifa_data?.assumingMemoryBound(to: if_data.self)

            return InterfaceSnapshot(
                bsdName: bsdName,
                isConnected: isConnected,
                received: data.map { UInt64($0.pointee.ifi_ibytes) } ?? 0,
                sent: data.map { UInt64($0.pointee.ifi_obytes) } ?? 0
            )
        }

        return nil
    }
}
