//
//  MenuBarController.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/5/26.
//

import AppKit
import Defaults
import os

final class MenuBarController: NSObject {
    private let logger = Logger(subsystem: "ByeFi", category: "MenuBar")
    private let openSettings: () -> Void
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var lidControlObservation: Defaults.Observation?
    private var hideMenuBarObservation: Defaults.Observation?

    init(openSettings: @escaping () -> Void) {
        self.openSettings = openSettings
        super.init()
        configureMenu()
        updateStatusItem()
        lidControlObservation = Defaults.observe(.lidControlEnabled) { [weak self] _ in
            self?.updateStatusIcon()
        }
        hideMenuBarObservation = Defaults.observe(.hideMenuBar) { [weak self] _ in
            self?.updateStatusItem()
        }
    }

    deinit {
        lidControlObservation?.invalidate()
        hideMenuBarObservation?.invalidate()
    }

    private func configureMenu() {
        menu.autoenablesItems = false
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettingsMenuItem), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let projectItem = NSMenuItem(title: "Project Site", action: #selector(openProjectSite), keyEquivalent: "")
        projectItem.target = self
        menu.addItem(projectItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit ByeFi", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func ensureStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        configureStatusButton()
    }

    private func configureStatusButton() {
        guard let button = statusItem?.button else { return }
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusIcon()
    }

    func updateStatusItem() {
        if Defaults[.hideMenuBar] {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
            return
        }

        ensureStatusItem()
        updateStatusIcon()
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        let symbolName = Defaults[.lidControlEnabled] ? "wave.3.down.circle.fill" : "wave.3.down.circle"
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        button.image?.isTemplate = true
    }

    @objc private func openSettingsMenuItem() {
        openSettings()
    }

    @objc private func openProjectSite() {
        NSWorkspace.shared.open(AppLinks.projectURL)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            logger.error("Missing currentEvent for status item click")
            return
        }

        if event.type == .rightMouseUp {
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.menu = nil
            }
        } else {
            Defaults[.lidControlEnabled].toggle()
            updateStatusIcon()
        }
    }
}
