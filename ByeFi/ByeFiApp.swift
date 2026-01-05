//
//  ByeFiApp.swift
//  ByeFi
//
//  Created by Shayne Sweeney on 1/5/26.
//

import ByeFiCore
import SwiftUI

@main
struct ByeFiApp: App {
    @NSApplicationDelegateAdaptor(ByeFiCore.AppDelegate.self) private var appDelegate

    var body: some Scene {
        ByeFiAppRoot.makeScene(appDelegate: appDelegate)
    }
}
