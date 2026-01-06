//
//  ByeFiAppRoot.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/5/26.
//

import SwiftUI

public enum ByeFiAppRoot {
    @MainActor
    public static func makeScene(appDelegate: AppDelegate) -> some Scene {
        _ = appDelegate
        return Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 560, height: 640)
    }
}
