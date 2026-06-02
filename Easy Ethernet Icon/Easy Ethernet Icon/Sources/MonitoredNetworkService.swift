import Foundation
import SystemConfiguration

enum MonitoredNetworkService {
    static let userDefaultsKey = "monitoredNetworkServiceName"
    static let defaultServiceName = "Ethernet 2"

    struct InterfaceSnapshot {
        let bsdName: String
        let isConnected: Bool
        let received: UInt64
        let sent: UInt64
    }

    static var configuredServiceName: String {
        let storedValue = UserDefaults.standard.string(forKey: userDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let storedValue, !storedValue.isEmpty {
            return storedValue
        }

        return defaultServiceName
    }

    static func currentSnapshot(for serviceName: String = configuredServiceName) -> InterfaceSnapshot? {
        guard let bsdName = bsdInterfaceName(for: serviceName) else { return nil }
        return interfaceSnapshot(forBSDName: bsdName)
    }

    private static func bsdInterfaceName(for serviceName: String) -> String? {
        guard
            let preferences = SCPreferencesCreate(nil, "EasyEthernetIcon" as CFString, nil),
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

    private static func bsdName(for interface: SCNetworkInterface) -> String? {
        if let bsdName = SCNetworkInterfaceGetBSDName(interface) as String? {
            return bsdName
        }

        guard let nestedInterface = SCNetworkInterfaceGetInterface(interface) else {
            return nil
        }

        return bsdName(for: nestedInterface)
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
