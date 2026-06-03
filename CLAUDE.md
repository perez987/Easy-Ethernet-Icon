# CLAUDE.md

## Project Overview

**Easy Ethernet Icon** is a lightweight macOS menu bar app that monitors Ethernet connection status and speed. It is written in Swift and targets macOS 13.5+.

## Repository Structure

```
Easy Ethernet Icon/
├── Easy Ethernet Icon/          # Main app target
│   ├── Sources/                 # Swift source files
│   │   ├── Main.swift
│   │   ├── AppDelegate.swift
│   │   ├── ApplicationMenu.swift
│   │   ├── NetworkMonitor.swift
│   │   ├── MonitoredNetworkService.swift
│   │   ├── SettingsView.swift
│   │   └── Localization.swift
│   ├── Assets.xcassets/
│   ├── en.lproj/
│   └── es.lproj/
└── Easy Ethernet Icon.xcodeproj/
```

## Build & Run

Open the project in Xcode and build with **⌘B**, or from the command line:

```bash
xcodebuild -project "Easy Ethernet Icon/Easy Ethernet Icon.xcodeproj" \
  -scheme "Easy Ethernet Icon" \
  -configuration Debug \
  build
```

## Linting

SwiftLint is configured in `Easy Ethernet Icon/.swiftlint.yml`. Run it from the repo root:

```bash
cd "Easy Ethernet Icon"
swiftlint
```

Disabled rules: `function_body_length`, `type_body_length`, `file_length`, `cyclomatic_complexity`, `inclusive_language`, `void_function_in_ternary`.

## Key Conventions

- **Xcode project uses `PBXFileSystemSynchronizedRootGroup`**: new Swift files placed under `Easy Ethernet Icon/Easy Ethernet Icon/Sources/` are automatically picked up by the project — no manual project.pbxproj edits needed.
- **External dependency**: `LaunchAtLogin` (Swift Package) for Login Item support.
- **Minimum deployment target**: macOS 13.5.
- **Localization**: English (`en.lproj`) and Spanish (`es.lproj`) string catalogs.
