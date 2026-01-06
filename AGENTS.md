# Repository Guidelines

## Project Structure & Module Organization
- `ByeFi.xcodeproj` is the app project entry point.
- App code lives in `ByeFi/` (main app target) and the shared SwiftPM module `Packages/ByeFiCore/`.
- Core logic is organized under `Packages/ByeFiCore/Sources/ByeFiCore/`:
  - `App/` (lifecycle, menu bar, settings wiring)
  - `Sensors/` (lid angle + power/wifi control)
  - `Views/` (SwiftUI settings UI)
  - `Extensions/` (Defaults keys)
- Assets live in `ByeFi/Assets.xcassets/` (including `AccentColor`).

## Build, Test, and Development Commands
Use mise tasks (preferred):
- `mise run build` — builds the macOS app.
- `mise run test` — runs tests (if/when added).
- `mise run clean` — cleans build artifacts.

Direct Xcodebuild equivalents:
- `xcodebuild -project ByeFi.xcodeproj -scheme ByeFi -destination 'platform=macOS' build`
- `xcodebuild -project ByeFi.xcodeproj -scheme ByeFi -destination 'platform=macOS' test`

## Coding Style & Naming Conventions
- Swift style follows Xcode defaults and Swift API Design Guidelines.
- Use 4-space indentation and one type per file when practical.
- Names: `UpperCamelCase` for types, `lowerCamelCase` for vars/functions.
- No enforced formatter/linter yet; keep formatting consistent with nearby code.

## Testing Guidelines
- No test targets are present currently.
- If adding tests, use XCTest and place them in a standard location such as
  `Packages/ByeFiCore/Tests/ByeFiCoreTests/` or an Xcode test target like `ByeFiTests`.
- Name tests as `test_<behavior>` (e.g., `test_lidClose_disablesWifi`).

## Commit & Pull Request Guidelines
- Git history shows no established commit convention (e.g., only “Initial commit”).
- Use clear, imperative summaries: “Add menu bar toggle”, “Fix settings focus”.
- PRs should include a short description, testing command(s) run, and screenshots
  for UI changes when relevant.

## Configuration & Defaults
- User settings are stored via the `Defaults` SwiftPM package
  (keys defined in `Packages/ByeFiCore/Sources/ByeFiCore/Extensions/Defaults+Extensions.swift`).
- System integrations use CoreWLAN, ServiceManagement, and IOKit; keep changes
  guarded and document any new entitlements or private APIs.
