//
//  PowerSourceMonitor.swift
//  ByeFiCore
//
//  Created by Shayne Sweeney on 1/5/26.
//

import Foundation
import IOKit.ps

enum PowerSourceMonitor {
    static func isOnACPower() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return true
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any],
                  let state = description[kIOPSPowerSourceStateKey as String] as? String else {
                continue
            }
            return state != kIOPSBatteryPowerValue
        }

        return true
    }
}
