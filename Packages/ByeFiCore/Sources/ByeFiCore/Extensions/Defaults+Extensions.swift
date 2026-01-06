//
//  Defaults+Extensions.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/6/26.
//

import Defaults

extension Defaults.Keys {
    static let lidControlEnabled = Key<Bool>("lidControlEnabled", default: true)
    static let ignoreWhenOnACPower = Key<Bool>("ignoreWhenOnACPower", default: true)
    static let hideMenuBar = Key<Bool>("hideMenuBar", default: false)
    static let launchAtLogin = Key<Bool>("launchAtLogin", default: false)
    static let launchAtLoginConfigured = Key<Bool>("launchAtLoginConfigured", default: false)
}
