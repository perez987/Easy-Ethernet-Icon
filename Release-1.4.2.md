# Release Notes — v1.4.2

This document summarizes the main changes included in the first release of this fork.

## Short Version (GitHub Release)

Easy Ethernet Icon **v1.4.2** is the first release of this fork.

### Highlights
- Added support for monitoring **Ethernet 2**.
- Added full **English and Spanish localization**.
- Improved **network speed accuracy** by tracking the selected interface directly.
- Improved project sharing setup with a **shared Xcode scheme**.

### Also included
- Settings UI refresh with improved network service selection.
- Better startup behavior (status icon now reflects real connection state at launch).
- Internal cleanup and stability improvements for monitoring/timers.

## Full Version (Technical)

This release includes all major improvements introduced since the fork was created.

### Highlights
- Added support for monitoring **Ethernet 2** (virtual interface setups, e.g. Heliport + itlwm).
- Added full **localization support** (English + Spanish).
- Improved **network speed accuracy** by tracking the selected interface directly.
- Updated project setup with a **shared Xcode scheme** for more consistent builds across environments.

### Added
- New `MonitoredNetworkService` module to resolve and monitor the active BSD interface.
- New localization layer via `Localization.swift` (`L10n.text()` wrapper).
- `en.lproj/Localizable.strings` and `es.lproj/Localizable.strings`.
- SwiftLint configuration (`.swiftlint.yml`).
- Shared scheme: `Easy Ethernet Icon.xcscheme`.

### Changed
- **Settings UI redesign**:
  - Modern pill-style tab selector.
  - Larger settings window.
  - New network service selector (Ethernet / Ethernet 2).
  - Warning shown when selected service is unavailable.
- **Menu behavior/UI**:
  - Settings item moved before Quit.
  - Localized labels and speed format.
  - Better placeholder behavior when monitored service is unresolved.
- **Network monitoring internals**:
  - Better timer lifecycle handling.
  - Safer defaults for refresh interval.
  - Interface-switch handling to prevent false speed spikes.
- **Startup behavior**:
  - Status bar icon now reflects real connection state on launch.

### Internal / Project
- Added shared Xcode scheme and adjusted scheme management behavior.
- Minor cleanup and style consistency improvements.
