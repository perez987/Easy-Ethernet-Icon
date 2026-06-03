# Changelog

Changes in this fork relative to the upstream source at [felixblome/easy-ethernet-icon](https://github.com/felixblome/easy-ethernet-icon).

## v1.4.0

### Added

- **Ethernet 2 support** — New `MonitoredNetworkService` module that resolves the active BSD interface through `SystemConfiguration`, allowing the user to choose between `Ethernet` (built-in) and `Ethernet 2` (virtual interface created by Heliport + itlwm for unsupported Intel Wi-Fi cards).
- **Localization infrastructure** — `Localization.swift` with a thin `L10n.text()` wrapper around `NSLocalizedString`.
- **English localizable strings** — `en.lproj/Localizable.strings` with all UI strings extracted.
- **Spanish localizable strings** — `es.lproj/Localizable.strings` with full Spanish translation.
- **SwiftLint configuration** — `.swiftlint.yml` for consistent code style enforcement.
- **CLAUDE.md** — Developer guide describing project structure, build requirements, and contribution notes.

### Changed

- **SettingsView — UI redesign**
  - Tab bar replaced with a modern pill-style control using material backgrounds and rounded rectangles.
  - Window height increased from 240 to 316 to accommodate the new network service selector.
  - Tab labels and all visible strings now use localized keys.
  - `SettingsTab` enum cases changed to lowercase (`general`, `network`, `about`) and each case now exposes a `titleKey` property instead of a `rawValue` string.
- **SettingsView — Network tab**
  - Added a network service name selector (Ethernet / Ethernet 2).
  - Shows an inline warning when the selected service is not found on the current Mac.
- **ApplicationMenu**
  - Menu item order changed: Settings now appears before Quit.
  - All hardcoded strings replaced with `L10n.text()` calls.
  - Speed display now shows a placeholder when the monitored service is not resolved.
  - Speed format string is localized.
  - Added a `statusPollingInterval` constant (1 second).
- **NetworkMonitor**
  - Removed unused `import Network`.
  - `ConnectionStatus` enum cases lowercased to Swift conventions (`connected` / `disconnected`).
  - Monitoring now calls `stopMonitoring()` before restarting to prevent timer leaks.
  - Added `publishSpeed()` helper to centralise speed-event dispatch.
  - Refresh interval defaults to 1 second when the stored value is zero or missing.
- **NetworkMonitor — speed tracking accuracy**
  - Replaced the previous approach (summing all active non-loopback interfaces) with per-interface tracking via `MonitoredNetworkService.currentSnapshot()`.
  - Detects interface changes and resets counters on switchover, avoiding phantom speed spikes.
  - Guards against division by zero when the time interval is zero.
- **AppDelegate**
  - Initial status bar icon now reflects the actual connection state at launch instead of always showing Disconnected.
  - Various minor code-style clean-ups (removed redundant `self.` prefixes, trailing whitespace, import ordering).
