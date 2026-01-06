//
//  LaunchAtLoginManager.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/5/26.
//

import Foundation
import ServiceManagement
import os

enum LaunchAtLoginManager {
    private static let logger = Logger(subsystem: "ByeFi", category: "LaunchAtLogin")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Failed to update launch at login: \(error.localizedDescription)")
        }
    }
}
