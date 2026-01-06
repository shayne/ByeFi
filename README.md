# ByeFi

<img src="ByeFi/Assets.xcassets/AppIcon.appiconset/byefi-macos-icon-1024.png" alt="ByeFi app icon" width="256" height="256" />

Download the latest app: https://github.com/shayne/ByeFi/releases/latest

ByeFi is a macOS menu bar app that disables Wi‑Fi when your laptop lid is closed and restores it when reopened.

How it works: the app reads the lid angle from the system HID sensor via IOKit, treats near‑closed angles as “lid closed,” and toggles Wi‑Fi using CoreWLAN. It remembers the previous Wi‑Fi power state so it only restores Wi‑Fi if it was on before closing, and it can skip actions while on AC power.

## Build

This repo uses [mise](https://mise.jdx.dev) for task shortcuts.

```sh
mise run build
mise run archive
```

The archive task outputs `build/ByeFi.app` for local use.
