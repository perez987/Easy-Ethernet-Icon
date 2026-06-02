import LaunchAtLogin
import SwiftUI

/// Enum for tab selection with three options
enum SettingsTab: String, CaseIterable {
    case general = "General"
    case network = "Network"
    case about = "About"
}

/// Main settings view with tabs
struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @AppStorage("selectedOption") var selectedOption: String = "macOS"

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar at the top
            HStack {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: icon(for: tab))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .accentColor : .gray)
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .accentColor : .gray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Settings")
            .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
            .cornerRadius(8)
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
        .frame(width: 420, height: 240)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding()
    }

    /// Returns the icon name for each tab
    private func icon(for tab: SettingsTab) -> String {
        switch tab {
        case .general: return "gearshape"
        case .network: return "network"
        case .about: return "info.circle"
        }
    }
}

/// General settings view content
struct GeneralSettingsView: View {
    @AppStorage("selectedOption") var selectedOption: String = "macOS"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Launch at login toggle with aligned label and switch
            HStack(alignment: .center) {
                Text("Launch at login")
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .leading) // Fixed width for alignment
                LaunchAtLogin.Toggle("")
                    .toggleStyle(SwitchToggleStyle(tint: .red)) // Custom color for switch
            }
            .padding(.horizontal, 16)

            // Icon Style selector with aligned label and dropdown
            HStack(alignment: .center) {
                Text("Icon Style:")
                    .font(.system(size: 14))
                    .frame(width: 120, alignment: .leading) // Fixed width for alignment

                // Dropdown menu for icon style selection
                Menu {
                    Button(action: { updateIcon(selectedOption: "Windows") }) {
                        Text("Windows")
                    }
                    Button(action: { updateIcon(selectedOption: "macOS") }) {
                        Text("macOS")
                    }
                } label: {
                    HStack {
                        Text(selectedOption)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .frame(width: 120) // Ensure consistent width for dropdown
            }
            .padding(.horizontal, 16)
        }
    }

    /// Updates the icon style and triggers a refresh of the status bar icon
    func updateIcon(selectedOption: String) {
        self.selectedOption = selectedOption
        AppDelegate.instance.updateStatusIcon()
    }
}

struct NetworkSettingsView: View {
    @AppStorage("showConnectionSpeed") var showConnectionSpeed: Bool = false
    @AppStorage("speedUnit") var speedUnit: String = "MB/s"
    @AppStorage("refreshInterval") var refreshInterval: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Einheitliches Layout für Labels
            let labelWidth: CGFloat = 160

            // Show speed toggle
            HStack(alignment: .center) {
                Text("Show connection speed")
                    .font(.system(size: 14))
                    .frame(width: labelWidth, alignment: .leading)

                Toggle("", isOn: $showConnectionSpeed)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
            }

            // Speed unit dropdown
            HStack(alignment: .center) {
                Text("Speed unit")
                    .font(.system(size: 14))
                    .frame(width: labelWidth, alignment: .leading)

                Menu {
                    Button(action: { speedUnit = "KB/s" }) {
                        Text("KB/s")
                    }
                    Button(action: { speedUnit = "MB/s" }) {
                        Text("MB/s")
                    }
                } label: {
                    dropdownLabel(title: speedUnit)
                }
                .frame(width: 120)
                .disabled(!showConnectionSpeed)
            }

            // Refresh interval dropdown
            HStack(alignment: .center) {
                Text("Refresh interval")
                    .font(.system(size: 14))
                    .frame(width: labelWidth, alignment: .leading)

                Menu {
                    Button(action: { refreshInterval = 1.0 }) {
                        Text("1 second")
                    }
                    Button(action: { refreshInterval = 3.0 }) {
                        Text("3 seconds")
                    }
                    Button(action: { refreshInterval = 5.0 }) {
                        Text("5 seconds")
                    }
                    Button(action: { refreshInterval = 10.0 }) {
                        Text("10 seconds")
                    }
                    Button(action: { refreshInterval = 30.0 }) {
                        Text("30 seconds")
                    }
                    Button(action: { refreshInterval = 60.0 }) {
                        Text("60 seconds")
                    }
                } label: {
                    dropdownLabel(title: "\(Int(refreshInterval)) seconds")
                }
                .frame(width: 120)
                .disabled(!showConnectionSpeed)
            }
        }
        .padding(.horizontal, 16)
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
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

/// About settings view content
struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Easy Ethernet Icon")
                .font(.system(size: 16, weight: .bold))

            Link("More information", destination: URL(string: "https://github.com/felixblome/easy-ethernet-icon")!)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
                .padding(.top, 5)

            Text("Made by Felix Blome | v1.2")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
}
