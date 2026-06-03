import LaunchAtLogin
import SwiftUI

/// Enum for tab selection with three options
enum SettingsTab: CaseIterable {
    case general
    case network
    case about

    var titleKey: String {
        switch self {
        case .general: return "settings.tab.general"
        case .network: return "settings.tab.network"
        case .about: return "settings.tab.about"
        }
    }
}

/// Main settings view with tabs
struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @AppStorage("selectedOption") var selectedOption: String = "macOS"

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        tabLabel(for: tab)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(L10n.text("settings.title"))
            .padding(6)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Divider()
                .padding(.vertical, 8)

            // Content area for selected tab
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView()
                    case .network:
                        NetworkSettingsView()
                    case .about:
                        AboutSettingsView()
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 420, height: 304)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
        .padding(14)
    }

    /// Returns the icon name for each tab
    private func icon(for tab: SettingsTab) -> String {
        switch tab {
        case .general: return "gearshape"
        case .network: return "network"
        case .about: return "info.circle"
        }
    }

    private func tabLabel(for tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab

        return VStack(spacing: 4) {
            Image(systemName: icon(for: tab))
                .font(.system(size: 18, weight: .medium))
            Text(L10n.text(tab.titleKey))
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    .white.opacity(isSelected ? 0.35 : 0.12),
                    lineWidth: 1
                )
        )
    }
}

/// General settings view content
struct GeneralSettingsView: View {
    @AppStorage("selectedOption") var selectedOption: String = "macOS"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Launch at login toggle with aligned label and switch
            HStack(alignment: .center) {
                Text(L10n.text("settings.general.launch_at_login"))
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .leading) // Fixed width for alignment
                LaunchAtLogin.Toggle("")
                    .toggleStyle(SwitchToggleStyle(tint: .red)) // Custom color for switch
            }
            .padding(.horizontal, 16)

            // Icon Style selector with aligned label and dropdown
            HStack(alignment: .center) {
                Text(L10n.text("settings.general.icon_style"))
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .leading) // Fixed width for alignment

                // Dropdown menu for icon style selection
                Menu(content: {
                    Button(action: { updateIcon(selectedOption: "Windows") }, label: {
                        Text(L10n.text("settings.general.icon.windows"))
                    })
                    Button(action: { updateIcon(selectedOption: "macOS") }, label: {
                        Text(L10n.text("settings.general.icon.macos"))
                    })
                }, label: {
                    HStack {
                        Text(localizedIconStyleName)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                })
                .frame(width: 120) // Ensure consistent width for dropdown
            }
            .padding(.horizontal, 16)
        }
    }

    /// Updates the icon style and triggers a refresh of the status bar icon
    func updateIcon(selectedOption: String) {
        self.selectedOption = selectedOption
        AppDelegate.instance?.updateStatusIcon()
    }

    private var localizedIconStyleName: String {
        selectedOption == "Windows"
            ? L10n.text("settings.general.icon.windows")
            : L10n.text("settings.general.icon.macos")
    }
}

struct NetworkSettingsView: View {
    // Mirror the centralized default so the field shows the same initial service name the monitor uses.
    @AppStorage(MonitoredNetworkService.userDefaultsKey)
    var monitoredNetworkServiceName: String = MonitoredNetworkService.defaultServiceName
    @AppStorage("showConnectionSpeed") var showConnectionSpeed: Bool = false
    @AppStorage("speedUnit") var speedUnit: String = "MB/s"
    @AppStorage("refreshInterval") var refreshInterval: Double = 1.0
    @State private var selectedServiceAvailable = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Einheitliches Layout für Labels
            let labelWidth: CGFloat = 160

            HStack(alignment: .center) {
                Text(L10n.text("settings.network.service_name"))
                    .font(.system(size: 14))
                    .frame(width: labelWidth, alignment: .leading)

                Picker("", selection: $monitoredNetworkServiceName) {
                    ForEach(MonitoredNetworkService.selectableServiceNames, id: \.self) { serviceName in
                        Text(serviceName)
                            .tag(serviceName)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 180)
            }

            if !selectedServiceAvailable {
                Text(L10n.text("settings.network.service_not_found"))
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Show speed toggle
            HStack(alignment: .center) {
                Text(L10n.text("settings.network.show_speed"))
                    .font(.system(size: 14))
                    .frame(width: labelWidth, alignment: .leading)

                Toggle("", isOn: $showConnectionSpeed)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
            }

            // Speed unit dropdown
            HStack(alignment: .center) {
                Text(L10n.text("settings.network.speed_unit"))
                    .font(.system(size: 14))
                    .frame(width: labelWidth, alignment: .leading)

                Menu(content: {
                    Button(action: { speedUnit = "KB/s" }, label: {
                        Text("KB/s")
                    })
                    Button(action: { speedUnit = "MB/s" }, label: {
                        Text("MB/s")
                    })
                }, label: {
                    dropdownLabel(title: speedUnit)
                })
                .frame(width: 120)
                .disabled(!showConnectionSpeed)
            }

            // Refresh interval dropdown
            HStack(alignment: .center) {
                Text(L10n.text("settings.network.refresh_interval"))
                    .font(.system(size: 14))
                    .frame(width: labelWidth, alignment: .leading)

                Menu(content: {
                    Button(action: { refreshInterval = 1.0 }, label: {
                        Text(localizedIntervalLabel(for: 1))
                    })
                    Button(action: { refreshInterval = 3.0 }, label: {
                        Text(localizedIntervalLabel(for: 3))
                    })
                    Button(action: { refreshInterval = 5.0 }, label: {
                        Text(localizedIntervalLabel(for: 5))
                    })
                    Button(action: { refreshInterval = 10.0 }, label: {
                        Text(localizedIntervalLabel(for: 10))
                    })
                    Button(action: { refreshInterval = 30.0 }, label: {
                        Text(localizedIntervalLabel(for: 30))
                    })
                    Button(action: { refreshInterval = 60.0 }, label: {
                        Text(localizedIntervalLabel(for: 60))
                    })
                }, label: {
                    dropdownLabel(title: localizedIntervalLabel(for: Int(refreshInterval)))
                })
                .frame(width: 120)
                .disabled(!showConnectionSpeed)
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            monitoredNetworkServiceName = MonitoredNetworkService.normalizedServiceName(
                monitoredNetworkServiceName
            )
            updateSelectedServiceAvailability()
        }
        .onChange(of: monitoredNetworkServiceName) { _ in
            updateSelectedServiceAvailability()
        }
    }

    /// Dropdown-Label-Styling als Wiederverwendbare Funktion
    private func dropdownLabel(title: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func localizedIntervalLabel(for seconds: Int) -> String {
        if seconds == 1 {
            return L10n.text("settings.network.interval.one_second")
        }

        return String(format: L10n.text("settings.network.interval.seconds_format"), seconds)
    }

    private func updateSelectedServiceAvailability() {
        selectedServiceAvailable = MonitoredNetworkService.isSelectableServiceAvailable(
            monitoredNetworkServiceName
        )
    }
}

/// About settings view content
struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Easy Ethernet Icon")
                .font(.system(size: 16, weight: .bold))

            Link(
                L10n.text("settings.about.more_information"),
                destination: URL(string: "https://github.com/felixblome/easy-ethernet-icon")!
            )
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
                .padding(.top, 5)

            Text(L10n.text("settings.about.version"))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
}
