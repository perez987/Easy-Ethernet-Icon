# CLAUDE.md

## Project Overview

**Easy Ethernet Icon** is a lightweight macOS menu bar app that monitors Ethernet connection status and speed. It is written in Swift and targets macOS 13.5+.

Designed to monitor only the system's Ethernet interface, a setting has been added that allows the user to choose between two Ethernet interfaces:

- `Ethernet` (built-in primary interface)
- `Ethernet 2` (interface created by `Heliport.app` + `itlwm.kext` to use Intel Wi-Fi cards not natively supported by macOS).

## Repository Structure

```
Easy-Ethernet-Icon/
├── Images/                      # README screenshots
├── Xcode-project/
│   ├── .swiftlint.yml
│   ├── Easy Ethernet Icon/      # Main app target
│   │   ├── Sources/             # Swift source files
│   │   │   ├── Main.swift
│   │   │   ├── AppDelegate.swift
│   │   │   ├── ApplicationMenu.swift
│   │   │   ├── NetworkMonitor.swift
│   │   │   ├── MonitoredNetworkService.swift
│   │   │   ├── SettingsView.swift
│   │   │   └── Localization.swift
│   │   ├── Assets.xcassets/     # Default, macOS and itlwm icon sets
│   │   ├── en.lproj/
│   │   └── es.lproj/
│   └── Easy Ethernet Icon.xcodeproj/
├── README.md
└── Fork-repo-differences.md
```

## Build & Run

Open the project in Xcode and build with **⌘B**, or from the command line:

```bash
xcodebuild -project "Xcode-project/Easy Ethernet Icon.xcodeproj" \
  -scheme "Easy Ethernet Icon" \
  -configuration Debug \
  build
```

## Linting

SwiftLint is configured in `Xcode-project/.swiftlint.yml`. Run it from the repo root:

```bash
cd "Xcode-project"
swiftlint lint --config .swiftlint.yml
```

Disabled rules:

- `function_body_length`
- `type_body_length`
- `file_length`
- `cyclomatic_complexity`
- `inclusive_language`
- `void_function_in_ternary`.

## Key Conventions

- **Xcode project uses `PBXFileSystemSynchronizedRootGroup`**: new Swift files placed under `Xcode-project/Easy Ethernet Icon/Sources/` are automatically picked up by the project — no manual project.pbxproj edits needed.
- **External dependency**: `LaunchAtLogin` (Swift Package) for Login Item support.
- **Icon styles**: `macOS`, `Windows` (asset prefix `Default`) and `itlwm` (for Hackintosh systems using HeliPort + itlwm). `AppDelegate.getConnectionImage` builds the asset name as `<prefix>_EthernetConnected` / `<prefix>_EthernetDisconnected`.
- **No tests**: the project has no test targets, and the shared scheme has no testables, so Product ▸ Test is disabled.
- **Minimum deployment target**: macOS 13.5.
- **Localization**: English (`en.lproj`) and Spanish (`es.lproj`) string catalogs.
