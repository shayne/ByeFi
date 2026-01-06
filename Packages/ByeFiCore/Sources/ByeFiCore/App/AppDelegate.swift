//
//  AppDelegate.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/5/26.
//

import AppKit
import Defaults

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let lidAngleMonitor = LidAngleMonitor()
    private var menuBarController: MenuBarController?
    private var pendingSettingsOpen = false
    private var windowCloseObserver: NSObjectProtocol?
    private var windowKeyObserver: NSObjectProtocol?

    public override init() {
        super.init()
        applyDefaultLaunchAtLoginIfNeeded()
    }

    public func applicationWillFinishLaunching(_ notification: Notification) {
        updateActivationPolicy()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        _ = lidAngleMonitor
        menuBarController = MenuBarController(openSettings: { [weak self] in
            _ = self?.openSettings()
        })
        windowKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateActivationPolicy()
            }
        }
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateActivationPolicy()
            }
        }
        pendingSettingsOpen = true
        DispatchQueue.main.async { [weak self] in
            self?.showPendingSettingsIfNeeded()
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        _ = openSettings()
        return true
    }

    deinit {
        if let windowCloseObserver {
            NotificationCenter.default.removeObserver(windowCloseObserver)
        }
        if let windowKeyObserver {
            NotificationCenter.default.removeObserver(windowKeyObserver)
        }
    }

    @discardableResult
    func openSettings() -> Bool {
        activateApp()

        if focusSettingsWindowsIfAvailable() {
            updateActivationPolicy()
            return true
        }

        guard triggerSettingsMenuItem() else {
            return false
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            _ = self.focusSettingsWindowsIfAvailable()
            self.updateActivationPolicy()
        }
        return true
    }

    private func showPendingSettingsIfNeeded(retries: Int = 8) {
        guard pendingSettingsOpen else { return }
        if focusSettingsWindowsIfAvailable() {
            pendingSettingsOpen = false
            return
        }
        _ = openSettings()
        guard retries > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showPendingSettingsIfNeeded(retries: retries - 1)
        }
    }

    private func settingsWindows() -> [NSWindow] {
        NSApp.windows.filter { window in
            NSStringFromClass(type(of: window)) != "NSStatusBarWindow" && window.toolbar?.items != nil
        }
    }

    private func prepareSettingsWindowForActiveSpace(_ window: NSWindow) {
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.collectionBehavior.remove(.canJoinAllSpaces)
    }

    private func focusSettingsWindowsIfAvailable() -> Bool {
        let windows = settingsWindows()
        guard !windows.isEmpty else { return false }
        activateApp()
        for window in windows {
            prepareSettingsWindowForActiveSpace(window)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            window.center()
        }
        return true
    }

    private func activateApp() {
        NSApp.setActivationPolicy(.regular)
        if #available(macOS 14.0, *) {
            NSRunningApplication.current.activate(options: [.activateAllWindows])
            NSApp.activate()
        } else {
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateActivationPolicy() {
        let visibleWindows = NSApp.windows.filter { window in
            window.isVisible && NSStringFromClass(type(of: window)) != "NSStatusBarWindow"
        }
        if visibleWindows.isEmpty {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
    }

    private func triggerSettingsMenuItem() -> Bool {
        guard let mainMenu = NSApp.mainMenu else { return false }
        if let item = findSettingsMenuItem(in: mainMenu) {
            if let action = item.action {
                NSApp.sendAction(action, to: item.target, from: item)
                return true
            }
        }
        return false
    }

    private func applyDefaultLaunchAtLoginIfNeeded() {
        #if !DEBUG
        guard !Defaults[.launchAtLoginConfigured] else { return }
        LaunchAtLoginManager.setEnabled(true)
        Defaults[.launchAtLogin] = true
        Defaults[.launchAtLoginConfigured] = true
        #endif
    }

    private func findSettingsMenuItem(in menu: NSMenu) -> NSMenuItem? {
        for item in menu.items {
            if isSettingsMenuItem(item) {
                return item
            }
            if let submenu = item.submenu, let match = findSettingsMenuItem(in: submenu) {
                return match
            }
        }
        return nil
    }

    private func isSettingsMenuItem(_ item: NSMenuItem) -> Bool {
        let title = item.title.lowercased()
        if title.contains("settings") || title.contains("preferences") {
            return true
        }
        if item.keyEquivalent == "," && item.keyEquivalentModifierMask.contains(.command) {
            return true
        }
        if let actionName = item.action.map({ NSStringFromSelector($0).lowercased() }),
           actionName.contains("showsettings") || actionName.contains("showpreferences")
        {
            return true
        }
        return false
    }
}
